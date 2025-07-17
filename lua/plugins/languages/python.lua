-- lua/plugins/languages/python.lua
-- Python language server configuration

return {
  servers = {
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            autoImportCompletions = true,
            diagnosticMode = "workspace",
            stubPath = vim.fn.stdpath "data" .. "/lazy/python-type-stubs",
          },
        },
      },
    },
  },

  -- Python-specific on_attach
  on_attach = function(client, bufnr)
    if client.name == "pyright" then
      -- Python-specific keymaps
      local opts = { buffer = bufnr, silent = true }

      vim.keymap.set(
        "n",
        "<leader>pr",
        function() vim.cmd("!python " .. vim.fn.expand "%") end,
        vim.tbl_extend("force", opts, { desc = "Run Python file" })
      )

      vim.keymap.set(
        "n",
        "<leader>pt",
        function() vim.cmd "!python -m pytest" end,
        vim.tbl_extend("force", opts, { desc = "Run pytest" })
      )

      vim.keymap.set(
        "n",
        "<leader>pi",
        function() vim.cmd "!python -m pip install -r requirements.txt" end,
        vim.tbl_extend("force", opts, { desc = "Install requirements" })
      )
    end
  end,
}
