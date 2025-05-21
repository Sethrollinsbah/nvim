---@type LazySpec[]
return {
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
