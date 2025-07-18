-- lua/plugins/mason.lua
-- Mason configuration WITHOUT rust-analyzer (handled by rustaceanvim)

---@type LazySpec
return {
  -- LSP Server Management
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "lua_ls",
        -- "rust_analyzer", -- REMOVED - handled by rustaceanvim with system rust-analyzer
        "ts_ls",
        "svelte",
        "jsonls",
        "yamlls",
        "pyright",
        "bashls",
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
        "markdownlint",
        "svelte-check",
        "black", -- Python formatter
        "isort", -- Python import sorter
        "shellcheck", -- Shell script linter
        -- NOTE: No rustfmt here - cargo handles Rust formatting
      })
    end,
  },

  -- Debuggers (all languages)
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {
      ensure_installed = {
        "python",
        "bash",
        "node2",
        "chrome",
        "js",
        "codelldb", -- For Rust debugging
        "cpptools",
      },

      automatic_installation = true,

      handlers = {
        -- Python debugger
        python = function()
          local dap = require "dap"

          dap.adapters.python = {
            type = "executable",
            command = "python",
            args = { "-m", "debugpy.adapter" },
          }

          dap.configurations.python = {
            {
              type = "python",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              pythonPath = function() return "/usr/bin/python3" end,
            },
          }
        end,

        -- Node.js debugger
        node2 = function()
          local dap = require "dap"

          dap.adapters.node2 = {
            type = "executable",
            command = "node",
            args = {
              vim.fn.stdpath "data" .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
            },
          }

          dap.configurations.javascript = {
            {
              name = "Launch file",
              type = "node2",
              request = "launch",
              program = "${file}",
              cwd = vim.fn.getcwd(),
              sourceMaps = true,
              protocol = "inspector",
              console = "integratedTerminal",
            },
          }

          dap.configurations.typescript = dap.configurations.javascript
        end,

        -- Rust debugger (codelldb)
        codelldb = function()
          local dap = require "dap"

          dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
              command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
              args = { "--port", "${port}" },
            },
          }

          dap.configurations.rust = {
            {
              name = "Launch Rust binary",
              type = "codelldb",
              request = "launch",
              program = function()
                -- Build before debugging
                vim.fn.system "cargo build"
                
                -- Auto-detect binary from Cargo.toml
                local cargo_toml_path = vim.fn.getcwd() .. "/Cargo.toml"
                if vim.fn.filereadable(cargo_toml_path) == 1 then
                  local cargo_toml = vim.fn.readfile(cargo_toml_path)
                  for _, line in ipairs(cargo_toml) do
                    local name = line:match '^name%s*=%s*"(.-)"'
                    if name then 
                      return vim.fn.getcwd() .. "/target/debug/" .. name 
                    end
                  end
                end
                
                -- Fallback to manual input
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
            },
          }

          -- Also setup for C/C++
          dap.configurations.c = {
            {
              name = "Launch C program",
              type = "codelldb",
              request = "launch",
              program = function() 
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") 
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
            },
          }

          dap.configurations.cpp = dap.configurations.c
        end,

        -- Bash debugger
        bash = function()
          local dap = require "dap"

          dap.adapters.bashdb = {
            type = "executable",
            command = vim.fn.stdpath "data" .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
            name = "bashdb",
          }

          dap.configurations.sh = {
            {
              type = "bashdb",
              request = "launch",
              name = "Launch Bash script",
              showDebugOutput = true,
              pathBashdb = vim.fn.stdpath "data" .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb",
              pathBashdbLib = vim.fn.stdpath "data" .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir",
              trace = true,
              file = "${file}",
              program = "${file}",
              cwd = "${workspaceFolder}",
              pathCat = "cat",
              pathBash = "/bin/bash",
              pathMkfifo = "mkfifo",
              pathPkill = "pkill",
              args = {},
              env = {},
              terminalKind = "integrated",
            },
          }
        end,
      },
    },
  },
}
