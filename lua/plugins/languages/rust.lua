-- lua/plugins/languages/rust.lua
-- Rust language server configuration

return {
  servers = {
    -- NOTE: Covered by rustaceanvim
    -- rust_analyzer = {
    --   settings = {
    --     ["rust-analyzer"] = {
    --       cargo = {
    --         allFeatures = true,
    --         loadOutDirsFromCheck = true,
    --         runBuildScripts = true,
    --       },
    --       checkOnSave = {
    --         allFeatures = true,
    --         command = "clippy",
    --         extraArgs = { "--no-deps" },
    --       },
    --       procMacro = {
    --         enable = true,
    --         ignored = {
    --           ["async-trait"] = { "async_trait" },
    --           ["napi-derive"] = { "napi" },
    --           ["async-recursion"] = { "async_recursion" },
    --         },
    --       },
    --       inlayHints = {
    --         bindingModeHints = {
    --           enable = false,
    --         },
    --         chainingHints = {
    --           enable = true,
    --         },
    --         closingBraceHints = {
    --           enable = true,
    --           minLines = 25,
    --         },
    --         closureReturnTypeHints = {
    --           enable = "never",
    --         },
    --         lifetimeElisionHints = {
    --           enable = "never",
    --           useParameterNames = false,
    --         },
    --         maxLength = 25,
    --         parameterHints = {
    --           enable = true,
    --         },
    --         reborrowHints = {
    --           enable = "never",
    --         },
    --         renderColons = true,
    --         typeHints = {
    --           enable = true,
    --           hideClosureInitialization = false,
    --           hideNamedConstructor = false,
    --         },
    --       },
    --     },
    --   },
    -- },
  },

  -- Rust-specific on_attach
  on_attach = function(client, bufnr)
    if client.name == "rust_analyzer" then
      -- Enable inlay hints for Rust
      if client.server_capabilities.inlayHintProvider then vim.lsp.inlay_hint.enable(bufnr, true) end

      -- Rust-specific keymaps can go here
      local opts = { buffer = bufnr, silent = true }
      vim.keymap.set(
        "n",
        "<leader>rr",
        function() vim.cmd "!cargo run" end,
        vim.tbl_extend("force", opts, { desc = "Cargo run" })
      )

      vim.keymap.set(
        "n",
        "<leader>rt",
        function() vim.cmd "!cargo test" end,
        vim.tbl_extend("force", opts, { desc = "Cargo test" })
      )

      vim.keymap.set(
        "n",
        "<leader>rb",
        function() vim.cmd "!cargo build" end,
        vim.tbl_extend("force", opts, { desc = "Cargo build" })
      )
    end
  end,
}
