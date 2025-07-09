---@type LazySpec
return {
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

      -- Setup DAP UI
      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Configure Java/Scala debug adapter
      dap.adapters.java = function(callback)
        -- Use the java-debug-adapter from coursier
        callback {
          type = "server",
          host = "127.0.0.1",
          port = 5005,
        }
      end

      -- Scala configurations using Java debugger
      dap.configurations.scala = {
        {
          type = "java",
          request = "attach",
          name = "Debug Scala (Attach)",
          hostName = "127.0.0.1",
          port = 5005,
        },
        {
          type = "java",
          request = "launch",
          name = "Debug Scala (Launch)",
          mainClass = "",
          args = "",
          console = "integratedTerminal",
        },
      }

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
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
        "cargo-check",
        "markdownlint",
        "svelte-check",
      })
    end,
  },
  -- Debuggers
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = {
        "python",
        "bash",
        "node2", -- Node.js adapter
        "chrome",
        "js",
      },

      handlers = {
        python = function()
          local dap = require "dap"
          dap.adapters.python = {
            type = "executable",
            command = "/usr/bin/python3",
            args = { "-m", "debugpy.adapter" },
          }
          dap.configurations.python = {
            {
              type = "python",
              request = "launch",
              name = "Launch file",
              program = "${file}",
            },
          }
        end,

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
        end,
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require "dap"

      -- Helper to auto-detect binary path from Cargo.toml
      local function get_binary_path()
        local cargo_toml = vim.fn.readfile "Cargo.toml"
        for _, line in ipairs(cargo_toml) do
          local name = line:match '^name%s*=%s*"(.-)"'
          if name then
            local binary_name = name:gsub("-", "_") -- <-- Convert kebab-case to snake_case
            return vim.fn.getcwd() .. "/target/debug/" .. binary_name
          end
        end
        return vim.fn.getcwd() .. "/target/debug/" -- fallback
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath "data" .. "/mason/packages/codelldb/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Launch Rust binary (auto)",
          type = "codelldb",
          request = "launch",
          program = get_binary_path,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
    end,
  },
}
