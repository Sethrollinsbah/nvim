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
-- require("toggleterm").setup({
--   -- ... other config
--   open_mapping = [[<c-\>]], -- Default toggle
--   terminal_mappings = true,
--   insert_mappings = true,
--
--   -- Custom keybindings for terminal mode
--   on_create = function(term)
--     local opts = { buffer = term.bufnr }
--     -- Quick escape from terminal insert mode
--     vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)
--     -- Quick close terminal
--     vim.keymap.set("t", "<C-q>", "<C-\\><C-n>:q<CR>", opts)
--   end,
-- })
