return {
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
}
