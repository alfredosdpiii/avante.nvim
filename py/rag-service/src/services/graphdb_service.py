import os
import sqlite3
from pathlib import Path
from tree_sitter_language_pack import get_parser

from libs.configs import BASE_DATA_DIR
from libs.utils import logger

# GraphDB SQLite file
DB_FILE = BASE_DATA_DIR / "sqlite" / "graphdb.sqlite"

class GraphDBService:
    """Service to index code AST into SQLite and export context."""
    def __init__(self):
        self.db_file = DB_FILE
        self.db_file.parent.mkdir(parents=True, exist_ok=True)

    def index_project(self, project_root: str) -> None:
        """Parse project code files and store AST nodes in SQLite."""
        conn = sqlite3.connect(self.db_file)
        c = conn.cursor()
        # init schema
        c.execute("PRAGMA journal_mode=WAL;")
        c.execute(
            "CREATE TABLE IF NOT EXISTS nodes(id TEXT PRIMARY KEY, filepath TEXT, type TEXT, start_row INTEGER, start_col INTEGER, end_row INTEGER, end_col INTEGER)"
        )
        c.execute("CREATE TABLE IF NOT EXISTS edges(parent TEXT, child TEXT)")
        c.execute("DELETE FROM edges")
        c.execute("DELETE FROM nodes")
        conn.commit()
        # file extension to languages
        ext2lang = {".lua":"lua", ".js":"javascript", ".jsx":"javascript", ".ts":"typescript", ".tsx":"tsx"}
        # walk directory
        for root, dirs, files in os.walk(project_root):
            for f in files:
                ext = Path(f).suffix
                lang = ext2lang.get(ext)
                if not lang:
                    continue
                fp = os.path.join(root, f)
                try:
                    src = Path(fp).read_text(encoding="utf-8")
                except Exception as e:
                    logger.error(f"GraphDB: read {fp} failed: {e}")
                    continue
                parser = get_parser(lang)
                tree = parser.parse(bytes(src, "utf8"))
                def recurse(node, parent_id=None):
                    sr, sc = node.start_point
                    er, ec = node.end_point
                    typ = node.type
                    id_ = f"{fp}@{typ}@{sr}@{sc}"
                    try:
                        c.execute(
                            "INSERT OR IGNORE INTO nodes VALUES(?,?,?,?,?,?,?);",
                            (id_, fp, typ, sr, sc, er, ec),
                        )
                    except Exception:
                        pass
                    if parent_id:
                        try:
                            c.execute("INSERT INTO edges VALUES(?,?);", (parent_id, id_))
                        except Exception:
                            pass
                    for child in node.children:
                        recurse(child, id_)
                recurse(tree.root_node)
        conn.commit()
        conn.close()
        logger.info(f"GraphDB: AST indexed in sqlite at {self.db_file}")

    def export_context(self) -> str:
        """Export all AST nodes as a newline-delimited string."""
        conn = sqlite3.connect(self.db_file)
        c = conn.cursor()
        rows = c.execute(
            "SELECT filepath || ' ' || type || ' ' || start_row || ',' || start_col || ' ' || end_row || ',' || end_col FROM nodes"
        ).fetchall()
        conn.close()
        return "\n".join(r[0] for r in rows)

    def clear_cache(self) -> None:
        """Delete the SQLite file to clear AST cache."""
        if self.db_file.exists():
            try:
                self.db_file.unlink()
                logger.info("GraphDB cache cleared")
            except Exception as e:
                logger.error(f"Failed to clear GraphDB cache: {e}")

graphdb_service = GraphDBService()