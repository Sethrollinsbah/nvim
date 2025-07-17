-- lua/plugins/languages/system.lua
-- System and configuration language servers (Bash, JSON, YAML, C/C++)

return {
  servers = {
    bashls = {
      filetypes = { "sh", "bash" },
      settings = {
        bashIde = {
          globPattern = "*@(.sh|.inc|.bash|.command)",
        },
      },
    },

    jsonls = {
      settings = {
        json = {
          validate = { enable = true },
          format = { enable = true },
        },
      },
      setup = {
        commands = {
          Format = {
            function() vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line "$", 0 }) end,
          },
        },
      },
    },

    yamlls = {
      settings = {
        yaml = {
          keyOrdering = false,
          format = {
            enable = true,
          },
          hover = true,
          completion = true,
          validate = true,
          schemaStore = {
            enable = false,
            url = "",
          },
        },
      },
    },

    clangd = {
      capabilities = { offsetEncoding = "utf-8" },
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    },
  },

  -- System languages on_attach
  on_attach = function(client, bufnr)
    local opts = { buffer = bufnr, silent = true }

    if client.name == "bashls" then
      vim.keymap.set(
        "n",
        "<leader>sx",
        function() vim.cmd("!chmod +x " .. vim.fn.expand "%") end,
        vim.tbl_extend("force", opts, { desc = "Make executable" })
      )

      vim.keymap.set(
        "n",
        "<leader>sr",
        function() vim.cmd("!" .. vim.fn.expand "%") end,
        vim.tbl_extend("force", opts, { desc = "Run shell script" })
      )
    end

    if client.name == "clangd" then
      vim.keymap.set(
        "n",
        "<leader>ch",
        function() vim.cmd "ClangdSwitchSourceHeader" end,
        vim.tbl_extend("force", opts, { desc = "Switch source/header" })
      )

      vim.keymap.set(
        "n",
        "<leader>cb",
        function() vim.cmd "!make" end,
        vim.tbl_extend("force", opts, { desc = "Build C/C++" })
      )
    end
  end,
}
