-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = false

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ colorscheme / theme ]]
require 'colorscheme'

-- [[ vim Settings options ]]
-- e.g. line numbers enabled
require 'options'

-- Official GitHub Copilot plugin
require 'plugin-gh-copilot'

