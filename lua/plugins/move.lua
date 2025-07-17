return {

  -- 1. LSP Setup for sui_move_analyzer
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "AstroNvim/astrolsp",
        opts = {
          servers = { "sui_move_analyzer" },
          config = {
            sui_move_analyzer = {
              cmd = { vim.fn.expand "~/.cargo/bin/sui-move-analyzer" },
              filetypes = { "move" },
              root_dir = function(fname)
                local util = require "lspconfig.util"
                return util.root_pattern("Move.toml", "Sui.toml", ".git")(fname) or util.path.dirname(fname)
              end,
              settings = {
                ["sui-move-analyzer"] = {
                  ["inlay-hints"] = true,
                  ["diagnostics"] = true,
                  ["completion"] = true,
                  ["hover"] = true,
                  ["goto-definition"] = true,
                  ["find-references"] = true,
                },
              },
              init_options = {
                enableInlayHints = true,
              },
              on_attach = function(client, bufnr)
                vim.notify("Sui Move Analyzer attached", vim.log.levels.INFO)
                if client.server_capabilities.inlayHintProvider then vim.lsp.inlay_hint.enable(bufnr, true) end
              end,
            },
          },
          setup_handlers = {
            sui_move_analyzer = function(_, opts)
              local lspconfig = require "lspconfig"
              local configs = require "lspconfig.configs"
              if not configs.sui_move_analyzer then
                configs.sui_move_analyzer = {
                  default_config = opts,
                }
              end
              lspconfig.sui_move_analyzer.setup(opts)
            end,
          },
        },
      },
    },
  },

  -- 2. Syntax Highlighting for Move
  {
    "yanganto/move.vim",
    branch = "sui-move",
    ft = "move",
  },

  -- 3. Filetype Detection and Keymaps
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      -- Filetype autocmd
      opts.autocmds = vim.tbl_deep_extend("force", opts.autocmds or {}, {
        move_filetype = {
          {
            event = { "BufRead", "BufNewFile" },
            pattern = "*.move",
            callback = function()
              vim.bo.filetype = "move"
              vim.opt_local.tabstop = 4
              vim.opt_local.shiftwidth = 4
              vim.opt_local.expandtab = true
            end,
          },
        },
      })

      -- Keybindings
      opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
        n = {
          ["<Leader>lm"] = { desc = "󱃾 Sui Move" },
          ["<Leader>lmb"] = { function() vim.cmd "!sui move build" end, desc = "Sui Move build" },
          ["<Leader>lmt"] = { function() vim.cmd "!sui move test" end, desc = "Sui Move test" },
          ["<Leader>lmc"] = { function() vim.cmd "!sui move build --check" end, desc = "Sui Move check" },
          ["<Leader>lmp"] = {
            function()
              local gas = vim.fn.input "Gas budget (default 20000000): "
              if gas == "" then gas = "20000000" end
              vim.cmd("!sui client publish --gas-budget " .. gas)
            end,
            desc = "Sui Move publish",
          },
          ["<Leader>lmh"] = { function() vim.lsp.buf.hover() end, desc = "LSP Hover" },
          ["<Leader>lmgd"] = { function() vim.lsp.buf.definition() end, desc = "Go to Definition" },
          ["<Leader>lmgr"] = { function() vim.lsp.buf.references() end, desc = "Find References" },
          ["<Leader>lmr"] = { function() vim.cmd "LspRestart sui_move_analyzer" end, desc = "Restart LSP" },
        },
      })

      return opts
    end,
  },
}
