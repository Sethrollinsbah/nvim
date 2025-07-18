return {
  "kdheepak/lazygit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
  },
  config = function()
    -- Fix for git log crashes
    vim.g.lazygit_floating_window_winblend = 0
    vim.g.lazygit_floating_window_scaling_factor = 0.9
    vim.g.lazygit_use_neovim_remote = 1
    -- Set custom config path
    vim.g.lazygit_config_file_path = vim.fn.expand("~/.config/lazygit/config.yml")
  end,
}
