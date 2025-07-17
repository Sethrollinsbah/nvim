-- lua/plugins/languages/typescript.lua
-- TypeScript/JavaScript language server configuration

return {
  servers = {
    ts_ls = {
      settings = {
        typescript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
        },
        javascript = {
          inlayHints = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
          },
        },
      },
    },

    eslint = {
      settings = {
        workingDirectories = { mode = "auto" },
      },
    },
  },

  -- TypeScript-specific on_attach
  on_attach = function(client, bufnr)
    if client.name == "ts_ls" then
      -- TypeScript-specific keymaps
      local opts = { buffer = bufnr, silent = true }

      vim.keymap.set(
        "n",
        "<leader>to",
        function()
          vim.lsp.buf.execute_command {
            command = "_typescript.organizeImports",
            arguments = { vim.api.nvim_buf_get_name(0) },
          }
        end,
        vim.tbl_extend("force", opts, { desc = "Organize imports" })
      )

      vim.keymap.set(
        "n",
        "<leader>tr",
        function()
          vim.lsp.buf.execute_command {
            command = "_typescript.removeUnused",
            arguments = { vim.api.nvim_buf_get_name(0) },
          }
        end,
        vim.tbl_extend("force", opts, { desc = "Remove unused imports" })
      )
    end
  end,
}
