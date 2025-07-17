-- lua/plugins/languages/lua.lua
-- Lua language server configuration

return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
          completion = {
            callSnippet = "Replace",
          },
          format = {
            enable = false, -- Use stylua instead
          },
        },
      },
    },
  },
  -- Language-specific on_attach
  on_attach = function(client, bufnr)
    -- Lua-specific setup
    if client.name == "lua_ls" then
      -- Disable formatting if using stylua
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,
}
