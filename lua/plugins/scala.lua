return {
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    ft = { "scala", "sbt", "java" },
    config = function()
      local metals_config = require("metals").bare_config()

      -- Enhanced Metals settings
      metals_config.settings = {
        showImplicitArguments = true,
        showImplicitConversionsAndClasses = true,
        showInferredType = true,
        superMethodLensesEnabled = true,
        enableSemanticHighlighting = false,
        excludedPackages = {
          "akka.actor.typed.javadsl",
          "com.github.swagger.akka.javadsl",
        },
        bloopSbtAlreadyInstalled = true,
        serverVersion = "latest.snapshot",
      }

      metals_config.init_options.statusBarProvider = "on"
      metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Simplified on_attach function (no duplicate keymaps)
      metals_config.on_attach = function(client, bufnr)
        -- Setup DAP for Scala
        require("metals").setup_dap()

        -- Enable code lenses
        if client.server_capabilities.codeLensProvider then
          vim.lsp.codelens.refresh { bufnr = bufnr }

          -- Auto-refresh code lenses on various events
          local codelens_group = vim.api.nvim_create_augroup("MetalsCodeLens", { clear = true })
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = bufnr,
            group = codelens_group,
            callback = function() vim.lsp.codelens.refresh { bufnr = bufnr } end,
          })
        end

        -- Only Scala-specific keymaps that aren't in global config
        local opts = { buffer = bufnr, silent = true }

        -- Additional Metals-specific commands not in global config
        vim.keymap.set(
          "n",
          "<leader>mi",
          function() require("metals").toggle_setting "showImplicitArguments" end,
          vim.tbl_extend("force", opts, { desc = "Toggle Implicit Args" })
        )

        vim.keymap.set(
          "n",
          "<leader>mh",
          function() require("metals").hover_worksheet() end,
          vim.tbl_extend("force", opts, { desc = "Hover Worksheet" })
        )

        vim.keymap.set(
          "n",
          "<leader>mt",
          function() require("metals.tvp").toggle_tree_view() end,
          vim.tbl_extend("force", opts, { desc = "Toggle Tree View" })
        )

        vim.keymap.set(
          "n",
          "<leader>mR",
          function() require("metals").restart_metals() end,
          vim.tbl_extend("force", opts, { desc = "Restart Metals" })
        )

        vim.keymap.set(
          "n",
          "<leader>ml",
          function() vim.lsp.codelens.run() end,
          vim.tbl_extend("force", opts, { desc = "Run Code Lens" })
        )

        -- Note: Most other keymaps are now global in astrocore.lua
        -- This includes: debug, test, build, and common Metals commands
      end

      -- Initialize metals for Scala files
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "scala", "sbt", "java" },
        callback = function() require("metals").initialize_or_attach(metals_config) end,
        group = nvim_metals_group,
      })

      -- Import build on VimEnter if in a Scala project
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local cwd = vim.fn.getcwd()
          if
            vim.fn.filereadable(cwd .. "/build.sbt") == 1
            or vim.fn.filereadable(cwd .. "/build.sc") == 1
            or vim.fn.isdirectory(cwd .. "/project") == 1
          then
            vim.defer_fn(function() require("metals").import_build() end, 2000)
          end
        end,
        group = nvim_metals_group,
      })
    end,
  },
}
