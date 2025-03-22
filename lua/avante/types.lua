---@meta

---@class vim.api.create_autocmd.callback.args
---@field id number
---@field event string
---@field group number?
---@field match string
---@field buf number
---@field file string
---@field data any

---@class vim.api.keyset.create_autocmd.opts: vim.api.keyset.create_autocmd
---@field callback? fun(ev:vim.api.create_autocmd.callback.args):boolean?

---@param event string | string[] (string|array) Event(s) that will trigger the handler
---@param opts vim.api.keyset.create_autocmd.opts
---@return integer
function vim.api.nvim_create_autocmd(event, opts) end

---@class vim.api.keyset.user_command.callback_opts
---@field name string
---@field args string
---@field fargs string[]
---@field nargs? integer | string
---@field bang? boolean
---@field line1? integer
---@field line2? integer
---@field range? integer
---@field count? integer
---@field reg? string
---@field mods? string
---@field smods? UserCommandSmods

---@class UserCommandSmods
---@field browse boolean
---@field confirm boolean
---@field emsg_silent boolean
---@field hide boolean
---@field horizontal boolean
---@field keepalt boolean
---@field keepjumps boolean
---@field keepmarks boolean
---@field keeppatterns boolean
---@field lockmarks boolean
---@field noautocmd boolean
---@field noswapfile boolean
---@field sandbox boolean
---@field silent boolean
---@field split string
---@field tab integer
---@field unsilent boolean
---@field verbose integer
---@field vertical boolean

---@class vim.api.keyset.user_command.opts: vim.api.keyset.user_command
---@field nargs? integer | string
---@field range? integer
---@field bang? boolean
---@field desc? string
---@field force? boolean
---@field complete? fun(prefix: string, line: string, pos?: integer): string[]
---@field preview? fun(opts: vim.api.keyset.user_command.callback_opts, ns: integer, buf: integer): nil

---@alias vim.api.keyset.user_command.callback fun(opts?: vim.api.keyset.user_command.callback_opts):nil

---@param name string
---@param command vim.api.keyset.user_command.callback
---@param opts? vim.api.keyset.user_command.opts
function vim.api.nvim_create_user_command(name, command, opts) end

---@type boolean
vim.g.avante_login = vim.g.avante_login

---@class AvanteHandlerOptions: table<[string], string>
---@field on_start AvanteLLMStartCallback
---@field on_chunk AvanteLLMChunkCallback
---@field on_stop AvanteLLMStopCallback
---
---@alias AvanteLLMMessageContentItem string | { type: "text", text: string } | { type: "image", source: { type: "base64", media_type: string, data: string } } | { type: "tool_use", name: string, id: string, input: any } | { type: "tool_result", tool_use_id: string, content: string, is_error?: boolean } | { type: "thinking", thinking: string, signature: string } | { type: "redacted_thinking", data: string }
---
---@alias AvanteLLMMessageContent AvanteLLMMessageContentItem[] | string
---
---@class AvanteLLMMessage
---@field role "user" | "assistant"
---@field content AvanteLLMMessageContent
---
---@class AvanteLLMToolResult
---@field tool_name string
---@field tool_use_id string
---@field content string
---@field is_error? boolean
---
---@class AvantePromptOptions: table<[string], string>
---@field system_prompt string
---@field messages AvanteLLMMessage[]
---@field image_paths? string[]
---@field tools? AvanteLLMTool[]
---@field tool_histories? AvanteLLMToolHistory[]
---
---@class AvanteGeminiMessage
---@field role "user"
---@field parts { text: string }[]
---
---@class AvanteClaudeBaseMessage
---@field cache_control {type: "ephemeral"}?
---
---@class AvanteClaudeTextMessage: AvanteClaudeBaseMessage
---@field type "text"
---@field text string
---
---@class AvanteClaudeImageMessage: AvanteClaudeBaseMessage
---@field type "image"
---@field source {type: "base64", media_type: string, data: string}
---
---@class AvanteClaudeMessage
---@field role "user" | "assistant"
---@field content [AvanteClaudeTextMessage | AvanteClaudeImageMessage][]

---@class AvanteClaudeTool
---@field name string
---@field description string
---@field input_schema AvanteClaudeToolInputSchema

---@class AvanteClaudeToolInputSchema
---@field type "object"
---@field properties table<string, AvanteClaudeToolInputSchemaProperty>
---@field required string[]

---@class AvanteClaudeToolInputSchemaProperty
---@field type "string" | "number" | "boolean"
---@field description string
---@field enum? string[]
---
---@class AvanteOpenAIChatResponse
---@field id string
---@field object "chat.completion" | "chat.completion.chunk"
---@field created integer
---@field model string
---@field system_fingerprint string
---@field choices? AvanteOpenAIResponseChoice[] | AvanteOpenAIResponseChoiceComplete[]
---@field usage {prompt_tokens: integer, completion_tokens: integer, total_tokens: integer}
---
---@class AvanteOpenAIResponseChoice
---@field index integer
---@field delta AvanteOpenAIMessage
---@field logprobs? integer
---@field finish_reason? "stop" | "length"
---
---@class AvanteOpenAIResponseChoiceComplete
---@field message AvanteOpenAIMessage
---@field finish_reason "stop" | "length" | "eos_token"
---@field index integer
---@field logprobs integer
---
---@class AvanteOpenAIMessageToolCallFunction
---@field name string
---@field arguments string
---
---@class AvanteOpenAIMessageToolCall
---@field index integer
---@field id string
---@field type "function"
---@field function AvanteOpenAIMessageToolCallFunction
---
---@class AvanteOpenAIMessage
---@field role? "user" | "system" | "assistant"
---@field content? string
---@field reasoning_content? string
---@field reasoning? string
---@field tool_calls? AvanteOpenAIMessageToolCall[]
---
---@class AvanteOpenAITool
---@field type "function"
---@field function AvanteOpenAIToolFunction
---
---@class AvanteOpenAIToolFunction
---@field name string
---@field description string | nil
---@field parameters AvanteOpenAIToolFunctionParameters | nil
---@field strict boolean | nil
---
---@class AvanteOpenAIToolFunctionParameters
---@field type "object"
---@field properties table<string, AvanteOpenAIToolFunctionParameterProperty>
---@field required string[]
---@field additionalProperties boolean
---
---@class AvanteOpenAIToolFunctionParameterProperty
---@field type string
---@field description string
---
---@alias AvanteChatMessage AvanteClaudeMessage | AvanteOpenAIMessage | AvanteGeminiMessage
---
---@alias AvanteMessagesParser fun(self: AvanteProviderFunctor, opts: AvantePromptOptions): AvanteChatMessage[]
---
---@class AvanteCurlOutput: {url: string, proxy: string, insecure: boolean, body: table<string, any> | string, headers: table<string, string>, rawArgs: string[] | nil}
---@alias AvanteCurlArgsParser fun(self: AvanteProviderFunctor, prompt_opts: AvantePromptOptions): AvanteCurlOutput
---
---@alias AvanteResponseParser fun(self: AvanteProviderFunctor, ctx: any, data_stream: string, event_state: string, opts: AvanteHandlerOptions): nil
---
---@class AvanteDefaultBaseProvider: table<string, any>
---@field endpoint? string
---@field extra_headers? table<string, any>
---@field model? string
---@field local? boolean
---@field proxy? string
---@field timeout? integer
---@field allow_insecure? boolean
---@field api_key_name? string
---@field _shellenv? string
---@field disable_tools? boolean
---@field entra? boolean
---@field hide_in_model_selector? boolean
---
---@class AvanteSupportedProvider: AvanteDefaultBaseProvider
---@field __inherited_from? string
---@field temperature? number
---@field max_tokens? number
---@field max_completion_tokens? number
---@field reasoning_effort? string
---@field display_name? string
---
---@class AvanteLLMUsage
---@field input_tokens number
---@field cache_creation_input_tokens number
---@field cache_read_input_tokens number
---@field output_tokens number
---
---@class AvanteLLMThinkingBlock
---@field thinking string
---@field signature string
---
---@class AvanteLLMRedactedThinkingBlock
---@field data string
---
---@class AvanteLLMToolUse
---@field name string
---@field id string
---@field input_json string
---@field response_contents? string[]
---@field thinking_blocks? AvanteLLMThinkingBlock[]
---@field redacted_thinking_blocks? AvanteLLMRedactedThinkingBlock[]
---
---@class AvanteLLMStartCallbackOptions
---@field usage? AvanteLLMUsage
---
---@class AvanteLLMStopCallbackOptions
---@field reason "complete" | "tool_use" | "error" | "rate_limit" | "cancelled"
---@field error? string | table
---@field usage? AvanteLLMUsage
---@field tool_use_list? AvanteLLMToolUse[]
---@field retry_after? integer
---@field headers? table<string, string>
---@field tool_histories? AvanteLLMToolHistory[]
---
---@alias AvanteStreamParser fun(self: AvanteProviderFunctor, ctx: any, line: string, handler_opts: AvanteHandlerOptions): nil
---@alias AvanteLLMStartCallback fun(opts: AvanteLLMStartCallbackOptions): nil
---@alias AvanteLLMChunkCallback fun(chunk: string): any
---@alias AvanteLLMStopCallback fun(opts: AvanteLLMStopCallbackOptions): nil
---@alias AvanteLLMConfigHandler fun(opts: AvanteSupportedProvider): AvanteDefaultBaseProvider, table<string, any>
---
---@class AvanteProvider: AvanteSupportedProvider
---@field parse_curl_args? AvanteCurlArgsParser
---@field parse_stream_data? AvanteStreamParser
---@field parse_api_key? fun(): string | nil
---
---@class AvanteProviderFunctor
---@field support_prompt_caching boolean | nil
---@field role_map table<"user" | "assistant", string>
---@field parse_messages AvanteMessagesParser
---@field parse_response AvanteResponseParser
---@field parse_curl_args AvanteCurlArgsParser
---@field is_disable_stream fun(self: AvanteProviderFunctor): boolean
---@field setup fun(): nil
---@field is_env_set fun(): boolean
---@field api_key_name string
---@field tokenizer_id string | "gpt-4o"
---@field model? string
---@field parse_api_key fun(): string | nil
---@field parse_stream_data? AvanteStreamParser
---@field on_error? fun(result: table<string, any>): nil
---@field transform_tool? fun(self: AvanteProviderFunctor, tool: AvanteLLMTool): AvanteOpenAITool | AvanteClaudeTool
---@field get_rate_limit_sleep_time? fun(self: AvanteProviderFunctor, headers: table<string, string>): integer | nil
---
---@alias AvanteBedrockPayloadBuilder fun(self: AvanteBedrockModelHandler | AvanteBedrockProviderFunctor, prompt_opts: AvantePromptOptions, request_body: table<string, any>): table<string, any>
---
---@class AvanteBedrockProviderFunctor: AvanteProviderFunctor
---@field load_model_handler fun(): AvanteBedrockModelHandler
---@field build_bedrock_payload? AvanteBedrockPayloadBuilder
---
---@class AvanteBedrockModelHandler : AvanteProviderFunctor
---@field role_map table<"user" | "assistant", string>
---@field parse_messages AvanteMessagesParser
---@field parse_response AvanteResponseParser
---@field build_bedrock_payload AvanteBedrockPayloadBuilder
---
---@alias AvanteLlmMode "planning" | "editing" | "suggesting" | "cursor-planning" | "cursor-applying" | "claude-text-editor-tool"
---
---@class AvanteSelectedCode
---@field path string
---@field content string
---@field file_type string
---
---@class AvanteSelectedFile
---@field path string
---@field content string
---@field file_type string
---
---@class AvanteTemplateOptions
---@field ask boolean
---@field code_lang string
---@field recently_viewed_files string[] | nil
---@field selected_code AvanteSelectedCode | nil
---@field project_context string | nil
---@field selected_files AvanteSelectedFile[] | nil
---@field diagnostics string | nil
---@field history_messages AvanteLLMMessage[] | nil
---@field memory string | nil
---
---@class AvanteGeneratePromptsOptions: AvanteTemplateOptions
---@field instructions? string
---@field mode? AvanteLlmMode
---@field provider AvanteProviderFunctor | AvanteBedrockProviderFunctor | nil
---@field tools? AvanteLLMTool[]
---@field tool_histories? AvanteLLMToolHistory[]
---@field original_code? string
---@field update_snippets? string[]
---@field prompt_opts? AvantePromptOptions
---
---@class AvanteLLMToolHistory
---@field tool_result? AvanteLLMToolResult
---@field tool_use? AvanteLLMToolUse
---
---@class AvanteLLMStreamOptions: AvanteGeneratePromptsOptions
---@field on_start AvanteLLMStartCallback
---@field on_chunk AvanteLLMChunkCallback
---@field on_stop AvanteLLMStopCallback
---@field on_tool_log? function(tool_name: string, log: string): nil
---
---@alias AvanteLLMToolFunc<T> fun(
---  input: T,
---  on_log?: (fun(log: string): nil) | nil,
---  on_complete?: (fun(result: boolean | string | nil, error: string | nil): nil) | nil)
---  : (boolean | string | nil, string | nil)
---
---@class AvanteLLMTool
---@field name string
---@field description string
---@field func? AvanteLLMToolFunc
---@field param AvanteLLMToolParam
---@field returns AvanteLLMToolReturn[]
---@field enabled? fun(opts: { user_input: string, history_messages: AvanteLLMMessage[] }): boolean

---@class AvanteLLMToolPublic : AvanteLLMTool
---@field func AvanteLLMToolFunc

---@class AvanteLLMToolParam
---@field type 'table'
---@field fields AvanteLLMToolParamField[]

---@class AvanteLLMToolParamField
---@field name string
---@field description string
---@field type 'string' | 'integer' | 'boolean'
---@field optional? boolean

---@class AvanteLLMToolReturn
---@field name string
---@field description string
---@field type 'string' | 'string[]' | 'boolean'
---@field optional? boolean
---
---@class avante.ChatHistoryEntry
---@field timestamp string
---@field provider string
---@field model string
---@field request string
---@field response string
---@field original_response string
---@field selected_file {filepath: string}?
---@field selected_code AvanteSelectedCode | nil
---@field reset_memory boolean?
---@field selected_filepaths string[] | nil
---@field visible boolean?
---@field tool_histories? AvanteLLMToolHistory[]
---
---@class avante.ChatHistory
---@field title string
---@field timestamp string
---@field entries avante.ChatHistoryEntry[]
---@field memory avante.ChatMemory | nil
---@field filename string
---
---@class avante.ChatMemory
---@field content string
---@field last_summarized_timestamp string
---
---@class avante.CurlOpts
---@field provider AvanteProviderFunctor
---@field prompt_opts AvantePromptOptions
---@field handler_opts AvanteHandlerOptions
---@field on_response_headers? fun(headers: table<string, string>): nil
---
---@class avante.lsp.Definition
---@field content string
---@field uri string
---
