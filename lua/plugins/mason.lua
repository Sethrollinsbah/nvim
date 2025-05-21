---@type LazySpec
return {
  -- LSPs
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "lua_ls",
        "rust_analyzer",
        "ts_ls",
        "svelte",
      })
    end,
  },
  -- Formatters/Linters
  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "stylua",
        "prettier",
        "eslint_d",
        "rustfmt",
        "cargo-check",
        "markdownlint",
        "svelte-check",
      })
    end,
  },
  -- Debuggers
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "python",
        "js",
        "node2",
        "codelldb",
      })
    end,
  },
}
