-- lua/plugins/mason.lua
-- Complete Mason configuration with fixed Rust debugger

---@type LazySpec
return {
  -- DAP Setup - moved here to ensure proper initialization
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      -- Setup DAP UI for non-Scala debugging
      dapui.setup {
        controls = {
          element = "repl",
          enabled = true,
        },
        expand_lines = true,
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        force_buffers = true,
        icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              { id = "breakpoints", size = 0.25 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            position = "bottom",
            size = 10,
          },
        },
        mappings = {
          edit = "e",
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
        render = {
          indent = 1,
          max_value_lines = 100,
        },
      }

      -- Setup virtual text for all languages
      require("nvim-dap-virtual-text").setup {
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        clear_on_continue = false,
        display_callback = function(variable, buf, stackframe, node, options)
          if options.virt_text_pos == "inline" then
            return " = " .. variable.value
          else
            return variable.name .. " = " .. variable.value
          end
        end,
      }

      -- Auto open/close DAP UI for non-Scala sessions
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  -- LSP Server Management
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "lua_ls",
        "rust_analyzer",
        "ts_ls",
        "svelte",
        "jsonls",
        "yamlls",
        "pyright",
        "bashls",
        -- Note: metals is handled by nvim-metals, not mason
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
        "codelldb",
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
            {
              type = "python",
              request = "launch",
              name = "Launch file with args",
              program = "${file}",
              args = function()
                local args_string = vim.fn.input "Arguments: "
                return vim.split(args_string, " ")
              end,
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
            {
              name = "Launch file with args",
              type = "node2",
              request = "launch",
              program = "${file}",
              cwd = vim.fn.getcwd(),
              sourceMaps = true,
              protocol = "inspector",
              console = "integratedTerminal",
              args = function()
                local args_string = vim.fn.input "Arguments: "
                return vim.split(args_string, " ")
              end,
            },
          }

          -- TypeScript configurations
          dap.configurations.typescript = dap.configurations.javascript
        end,

        -- Fixed Rust debugger
        codelldb = function()
          local dap = require "dap"

          -- Helper to auto-detect binary path from Cargo.toml
          local function get_binary_path()
            local cargo_toml_path = vim.fn.getcwd() .. "/Cargo.toml"
            if vim.fn.filereadable(cargo_toml_path) == 1 then
              local cargo_toml = vim.fn.readfile(cargo_toml_path)
              for _, line in ipairs(cargo_toml) do
                local name = line:match '^name%s*=%s*"(.-)"'
                if name then return vim.fn.getcwd() .. "/target/debug/" .. name end
              end
            end
            return vim.fn.getcwd() .. "/target/debug/main" -- fallback
          end

          -- Fixed adapter configuration
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
              name = "Launch Rust binary (auto-detect)",
              type = "codelldb",
              request = "launch",
              program = function()
                -- Build before debugging
                vim.fn.system "cargo build"
                return get_binary_path()
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
              runInTerminal = false,
            },
            {
              name = "Launch Rust binary (manual)",
              type = "codelldb",
              request = "launch",
              program = function()
                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
              runInTerminal = false,
            },
            {
              name = "Launch Rust binary with args",
              type = "codelldb",
              request = "launch",
              program = function()
                vim.fn.system "cargo build"
                return get_binary_path()
              end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = function()
                local args_string = vim.fn.input "Arguments: "
                return vim.split(args_string, " ")
              end,
              runInTerminal = false,
            },
          }

          -- Also setup for C/C++
          dap.configurations.c = {
            {
              name = "Launch C program",
              type = "codelldb",
              request = "launch",
              program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
              runInTerminal = false,
            },
          }

          dap.configurations.cpp = {
            {
              name = "Launch C++ program",
              type = "codelldb",
              request = "launch",
              program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
              cwd = "${workspaceFolder}",
              stopOnEntry = false,
              args = {},
              runInTerminal = false,
            },
          }
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
