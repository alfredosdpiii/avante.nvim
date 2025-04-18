local Utils = require("avante.utils")
local Path = require("plenary.path")
local scan = require("plenary.scandir")

---@class avante.GraphDB
local M = { ready = false }

local function get_db_path()
  local state = vim.fn.stdpath("state") .. "/avante"
  Path:new(state):mkdir({ parents = true, exists_ok = true })
  return state .. "/graphdb.sqlite"
end
-- Expose DB path for external checks
M.get_db_path = get_db_path

--- Execute SQL script via sqlite3 CLI
local function exec_sql(sql)
  local db = get_db_path()
  -- Execute a single SQL statement via sqlite3 CLI
  -- Escape single quotes
  local stmt = sql:gsub("'", "''")
  local cmd = string.format("sqlite3 %q '%s'", db, stmt)
  -- Run the statement silently
  vim.fn.system(cmd)
end

--- Initialize schema and clear existing data
local function init_db()
  local sql = [[
    PRAGMA journal_mode=WAL;
    CREATE TABLE IF NOT EXISTS nodes(
      id TEXT PRIMARY KEY,
      filepath TEXT,
      type TEXT,
      start_row INTEGER,
      start_col INTEGER,
      end_row INTEGER,
      end_col INTEGER
    );
    CREATE TABLE IF NOT EXISTS edges(
      parent TEXT,
      child TEXT
    );
    DELETE FROM edges;
    DELETE FROM nodes;
    BEGIN TRANSACTION;
  ]]
  exec_sql(sql)
end

--- Finalize transaction
local function finalize_db()
  exec_sql("COMMIT;")
end

--- Recursive AST indexing into sqlite
local function index_node(node, filepath, parent_id)
  local sr, sc, er, ec = node:range()
  local typ = node:type()
  local id = filepath .. "@" .. typ .. "@" .. sr .. "@" .. sc
  -- Insert node
  local sql = string.format(
    "INSERT OR IGNORE INTO nodes VALUES('%s','%s','%s',%d,%d,%d,%d);",
    id, filepath, typ, sr, sc, er, ec
  )
  exec_sql(sql)
  -- Insert edge
  if parent_id then
    local esql = string.format(
      "INSERT INTO edges VALUES('%s','%s');",
      parent_id, id
    )
    exec_sql(esql)
  end
  for child in node:iter_children() do
    index_node(child, filepath, id)
  end
end

--- Index entire project AST into sqlite graphdb
---@param project_root string
function M.index_project(project_root)
  -- initialize DB schema
  -- initialize DB schema synchronously
  init_db()
  -- scan project files
  local files = scan.scan_dir(project_root, {
    hidden = false,
    depth = math.huge,
    add_dirs = false,
    respect_gitignore = true,
  })
  local ext2lang = { lua="lua", js="javascript", jsx="javascript", ts="typescript", tsx="tsx" }
  -- chunked processing with batched SQL
  local idx = 1
  local total = #files
  local pending_sql = {}
  local function flush_sql()
    if #pending_sql > 0 then
      local batch = table.concat(pending_sql, "\n")
      exec_sql(batch)
      pending_sql = {}
    end
  end
  local function process_batch()
    local count = 0
    while idx <= total and count < 3 do
      local filepath = files[idx]
      local ext = filepath:match("^.+%.([^%.]+)$")
      local lang = ext and ext2lang[ext]
      if lang then
        local lines = Utils.read_file_from_buf_or_disk(filepath)
        if lines then
          local src = table.concat(lines, "\n")
          local ok, parser = pcall(vim.treesitter.get_string_parser, src, lang)
          if ok and parser then
            for _, tree in ipairs(parser:parse()) do
              -- collect AST node SQL
              local node = tree:root()
              local function collect(node, parent_id)
                local sr, sc, er, ec = node:range()
                local typ = node:type()
                local id = filepath .. "@" .. typ .. "@" .. sr .. "@" .. sc
                table.insert(pending_sql, string.format("INSERT OR IGNORE INTO nodes VALUES('%s','%s','%s',%d,%d,%d,%d);", id, filepath, typ, sr, sc, er, ec))
                if parent_id then
                  table.insert(pending_sql, string.format("INSERT INTO edges VALUES('%s','%s');", parent_id, id))
                end
                for child in node:iter_children() do collect(child, id) end
              end
              collect(node, nil)
            end
          end
        end
      end
      idx = idx + 1
      count = count + 1
    end
    -- flush after batch
    flush_sql()
    if idx <= total then
      vim.defer_fn(process_batch, 0)
    else
      finalize_db()
      M.ready = true
      Utils.info("GraphDB: AST indexed in sqlite at " .. get_db_path(), { title = "Avante" })
    end
  end
  -- start async indexing
  process_batch()
end

--- Export AST context for LLM
---@return string
function M.export_context()
  if not M.ready then
    Utils.warn("GraphDB: indexing not finished, context may be incomplete", { title = "Avante" })
  end
  local db = get_db_path()
  local query = "SELECT filepath||' '||type||' '||start_row||','||start_col||' '||end_row||','||end_col FROM nodes;"
  local cmd = string.format("sqlite3 -separator ' | ' '%s' \"%s\"", db, query)
  local lines = vim.fn.systemlist(cmd)
  return table.concat(lines, "\n")
end

--- Get all distinct filepaths indexed in the AST graph
---@return string[] list of filepaths
function M.get_filepaths()
  local db = get_db_path()
  local query = "SELECT DISTINCT filepath FROM nodes;"
  local cmd = string.format("sqlite3 -noheader -separator '' '%s' \"%s\"", db, query)
  local ok, output = pcall(vim.fn.systemlist, cmd)
  if ok and type(output) == 'table' then
    return output
  end
  return {}
end

--- Find files that import or require a given module name
---@param module_name string
---@return string[] filepaths
function M.find_imports(module_name)
  local files = M.get_filepaths()
  local res = {}
  for _, filepath in ipairs(files) do
    local lines, err = Utils.read_file_from_buf_or_disk(filepath)
    if lines then
      for _, line in ipairs(lines) do
        if line:match("import%s+.*['\"]" .. module_name .. "['\"]")
          or line:match("require%(['\"]" .. module_name .. "['\"]%)") then
          table.insert(res, filepath)
          break
        end
      end
    end
  end
  return res
end

--- Clear persisted graph database
function M.clear_cache()
  local db = get_db_path()
  local p = Path:new(db)
  if p:exists() then
    p:rm()  -- remove file
    Utils.info("GraphDB cache cleared", { title = "Avante" })
  else
    Utils.info("GraphDB cache not found", { title = "Avante" })
  end
  M.ready = false
end

return M