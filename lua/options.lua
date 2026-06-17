-- UI basics
vim.o.termguicolors = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.completeopt = "menuone,noinsert,noselect,popup"

--- legacy stuff, what does this do?
vim.o.backspace='indent,eol,start'
vim.o.fileencodings='ucs-bom,utf-8,latin1'
vim.o.guicursor='n-v-c:block,o:hor50,i-ci:hor15,r-cr:hor30,sm:block,a:blinkon0'
vim.o.helplang='en'

--- history and undo
vim.o.history=5000
-- Enable undo/redo changes even after closing and reopening a file
vim.o.undofile = true

--- search
vim.o.hlsearch=true
vim.o.ignorecase=true
vim.o.smartcase=true

vim.o.ruler=true

--- line numbering
vim.o.nu=true
vim.o.relativenumber=true

--- indenting and whitespace
vim.o.list=true
vim.o.smartindent=true
vim.opt.listchars={ tab = ' ┊ ', nbsp = '␣', eol = '$' }

--- (change settings if YAML:)
vim.api.nvim_create_autocmd("FileType", {
	pattern = 'yaml',
	group = group,
	callback = function()
		vim.bo.ts = 2
		vim.bo.sts = 2
		vim.bo.sw = 2
		vim.bo.expandtab = true
		vim.wo.cursorcolumn = true
	end,
})

--- display unicode characters (e.g. pipe for tab)
--- vim.o.termencoding='utf-8'

--- active line
vim.o.cursorline=true
vim.o.modeline=true

--- mouse
--- vim.o.mouse=''

--- diff whats new since last save
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new")
  vim.opt_local.buftype = "nofile"
  vim.opt_local.bufhidden = "wipe"
  vim.opt_local.buflisted = false
  vim.opt_local.swapfile = false

  vim.cmd("read ++edit #")
  vim.cmd("0delete _")
  vim.cmd("diffthis")
  vim.cmd("wincmd p")
  vim.cmd("diffthis")
end, {})
