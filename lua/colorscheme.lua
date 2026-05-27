--- status line

_G.encoding = function()
  return (vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.enc)
end

_G.bom = function()
  return vim.bo.bomb and ",BOM" or ""
end

_G.ro = function()
  return (vim.bo.readonly or not vim.bo.modifiable) and " [RO] " or ""
end

_G.modified = function()
  return vim.bo.modified and "[*]" or ""
end


-- Statusline
vim.opt.statusline = table.concat({
  "%7*[%n]",                             -- buffer number
  "%2* %y",                              -- filetype
  "%3* %{v:lua.encoding()}",             -- encoding
  "%3* %{v:lua.bom()}",                  -- BOM
  "%4* %{&ff}",                          -- fileformat
  "%5* %{&spelllang} ",                  -- spelllang
  "%6*%{v:lua.ro()}",                    -- readonly / unmodifiable
  "%1* %= %<%F",                         -- full path (right-aligned)
  "%6*%{v:lua.modified()}",              -- modified flag
  "%4* line:%l/%L (%03p%%)",              -- line info
  "%3* col:%03c",                        -- column
  "%2* %w %P ",                          -- preview flag + top/bot
})



--- colorscheme
local function apply_highlight_overrides()
  local set = vim.api.nvim_set_hl

  -- search highlights
  set(0, "CurSearch", {
    reverse = true,
    fg = "#d75f5f",
    bg = "#1c1c1c",
    cterm = { reverse = true },
    ctermfg = 167,
    ctermbg = 234,
  })

  set(0, "Search", {
    reverse = true,
    fg = "#d7d787",
    bg = "#1c1c1c",
    cterm = { reverse = true },
    ctermfg = 186,
    ctermbg = 234,
  })

  set(0, "DiffText", {
    bold = true,
    cterm = { bold = true },
    ctermfg = 232,
    ctermbg = 173,
  })

  set(0, "DiffChange", {
    ctermbg = 66,
  })

  set(0, "DiffDelete", {
    ctermfg = 167,
  })

  -- links / other
  set(0, "Question", { link = "Title" })
  set(0, "Ignore", { link = "MatchParen" })
  set(0, "Normal", { bg = "NONE", ctermbg = "NONE" })

  -- statusline user groups
  set(0, "User1", { ctermfg = 0,   ctermbg = 75 })
  set(0, "User2", { ctermfg = 0,   ctermbg = 247 })
  set(0, "User3", { ctermfg = 0,   ctermbg = 245 })
  set(0, "User4", { ctermfg = 254, ctermbg = 240 })
  set(0, "User5", { ctermfg = 254, ctermbg = 235 })
  set(0, "User6", { ctermfg = 0,   ctermbg = 202 })
  set(0, "User7", { ctermfg = 254, ctermbg = 0, bold = true, cterm = { bold = true } })
  -- set(0, "User8", { strikethrough = true, cterm = { strikethrough = true }, bg = "NONE", ctermbg = "NONE" })
  set(0, "User9", { ctermfg = 84,  bg = "NONE", ctermbg = "NONE" })
  set(0, "User0", { ctermfg = 254, ctermbg = 172 })
end

local group = vim.api.nvim_create_augroup("MyColorOverrides", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = apply_highlight_overrides,
})

vim.cmd.colorscheme 'habamax'
