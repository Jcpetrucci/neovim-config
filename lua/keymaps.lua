--- diff the unsaved changes of a file against the saved version:
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd([[
    vert new
    setlocal buftype=nofile
    read ++edit #
    0d_
    diffthis
    wincmd p
    diffthis
  ]])
end, {})
