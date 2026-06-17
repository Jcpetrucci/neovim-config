vim.g.copilot_no_tab_map = true
vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
  silent = true,
})
vim.keymap.set("i", "<C-L>", "<Plug>(copilot-next)", { silent = true })
vim.keymap.set("i", "<C-H>", "<Plug>(copilot-previous)", { silent = true })
vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)", { silent = true })

local ai = require("ai_defaults")
local chat = require("CopilotChat")

chat.setup({
  auto_insert_mode = false,
  question_header = "## User ",
  answer_header = "## Copilot ",
  error_header = "## Error ",
  separator = "───",
  show_help = true,
  context = "buffers",
  prompts = ai.prompts(),
  window = {
    layout = "horizontal",
    height = 0.30,
  },

})

-- Core chat window
vim.keymap.set("n", "<leader>aa", "<cmd>CopilotChatOpen<cr>",  { silent = true, desc = "Open Copilot Chat" })
vim.keymap.set("n", "<leader>ax", "<cmd>CopilotChatClose<cr>", { silent = true, desc = "Close Copilot Chat" })

-- Docs-aware prompts: build lazily on keypress
vim.keymap.set("n", "<leader>aP", function()
  chat.ask(ai.prompt_docs_plan(), { resources = { "buffer" } })
end, { silent = true, desc = "Docs Plan" })

vim.keymap.set("n", "<leader>aE", function()
  chat.ask(ai.prompt_docs_edit(), { resources = { "buffer" } })
end, { silent = true, desc = "Docs Edit" })

-- Visual-mode prompts (selection context)
vim.keymap.set("v", "<leader>ap", function()
  chat.ask(ai.prompt_plan(), { resources = { "selection" } })
end, { silent = true, desc = "Plan selection" })

vim.keymap.set("v", "<leader>ae", function()
  chat.ask(ai.prompt_edit(), { resources = { "selection" } })
end, { silent = true, desc = "Edit selection" })

vim.keymap.set("v", "<leader>ar", function()
  chat.ask(ai.prompt_review(), { resources = { "selection" } })
end, { silent = true, desc = "Review selection" })

vim.keymap.set("v", "<leader>ai", function()
  chat.ask("Explain what this code does, including any edge cases and risks.", { resources = { "selection" } })
end, { silent = true, desc = "Explain selection" })

vim.keymap.set("v", "<leader>aP", function()
  chat.ask(ai.prompt_docs_plan(), { resources = { "selection" } })
end, { silent = true, desc = "Docs Plan selection" })

vim.keymap.set("v", "<leader>aE", function()
  chat.ask(ai.prompt_docs_edit(), { resources = { "selection" } })
end, { silent = true, desc = "Docs Edit selection" })

-- Quickfix navigation
vim.keymap.set("n", "<leader>qo", "<cmd>copen<cr>",  { silent = true, desc = "Open quickfix" })
vim.keymap.set("n", "<leader>qc", "<cmd>cclose<cr>", { silent = true, desc = "Close quickfix" })
vim.keymap.set("n", "<leader>qn", "<cmd>cnext<cr>",  { silent = true, desc = "Quickfix next" })
vim.keymap.set("n", "<leader>qp", "<cmd>cprev<cr>",  { silent = true, desc = "Quickfix previous" })

-- Optional debugging helpers
vim.api.nvim_create_user_command("AIDocsDebug", function()
  print(ai.prompt_docs_plan())
end, {})

vim.api.nvim_create_user_command("AIModels", function()
  print(vim.inspect(ai.models))
end, {})


-- Stronger CopilotChat window styling via a dedicated highlight namespace
local copilot_chat_ns = vim.api.nvim_create_namespace("copilot_chat_window")

vim.api.nvim_set_hl(copilot_chat_ns, "Normal",     { bg = "#145090", fg = "NONE" })
vim.api.nvim_set_hl(copilot_chat_ns, "NormalNC",   { bg = "#145090", fg = "NONE" })
vim.api.nvim_set_hl(copilot_chat_ns, "EndOfBuffer",{ bg = "#145090", fg = "#550000" })

-- Only matters if you use a floating chat window
vim.api.nvim_set_hl(copilot_chat_ns, "NormalFloat",{ bg = "#145090", fg = "NONE" })
vim.api.nvim_set_hl(copilot_chat_ns, "FloatBorder",{ bg = "#145090", fg = "#ffaaaa" })

local function apply_copilot_chat_hl()
  if vim.bo.filetype ~= "copilot-chat" then
    return
  end

  local win = vim.api.nvim_get_current_win()

-- Defer one tick so this runs after the window is fully realized / plugin sets its state
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_hl_ns(win, copilot_chat_ns)
    end
  end)
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
  pattern = "copilot-chat",
  callback = apply_copilot_chat_hl,
})
