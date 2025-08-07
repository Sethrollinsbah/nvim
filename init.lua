-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo(
    { { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } },
    true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

vim.opt.swapfile = false

vim.api.nvim_create_user_command("DrawLine", function()
  require("user.xdraw_rs").add_line(10, 10, 100, 100)
end, {})

vim.api.nvim_create_user_command("UndoDraw", function()
  require("user.xdraw_rs").undo()
end, {})

vim.api.nvim_create_user_command("RedoDraw", function()
  require("user.xdraw_rs").redo()
end, {})

vim.api.nvim_create_user_command("SaveDraw", function(opts)
  require("user.xdraw_rs").save(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("LoadDraw", function(opts)
  require("user.xdraw_rs").load(opts.args)
end, { nargs = 1 })

