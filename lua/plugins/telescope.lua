-- lua/lazy_setup.lua (or similar file like lua/plugins.lua)

---@type LazySpec
return {
  -- Other plugins...

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.x", -- Always good to use a stable tag
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Telescope setup options
      require("telescope").setup {
        -- your config here
      }

      -- *** THIS IS WHERE YOUR KEYMAP BELONGS! ***
      vim.keymap.set(
        "n",
        "<leader>fd",
        function() require("telescope.builtin").diagnostics() end,
        { desc = "Find diagnostics (global)" }
      )
    end,
  },

  --Other plugins...
}
