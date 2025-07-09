-- lua/plugins/scala.lua
-- Comprehensive Scala development setup with nvim-metals and DAP

return {
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
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

      -- Setup DAP for Scala debugging (separate from general DAP)
      local function setup_scala_dap()
        -- Only setup Scala-specific DAP UI behavior
        local dap = require "dap"

        -- Ensure Scala DAP configurations exist
        if not dap.configurations.scala then dap.configurations.scala = {} end

        -- Add Scala-specific DAP listeners (with unique names)
        dap.listeners.after.event_initialized["scala_metals_codelens"] = function() vim.lsp.codelens.refresh() end

        -- Only handle Scala debug sessions
        dap.listeners.after.event_initialized["scala_session_handler"] = function(session)
          if session.config and session.config.type == "scala" then
            vim.notify("Scala debug session started", vim.log.levels.INFO)
          end
        end
      end

      -- Critical: Proper on_attach function
      metals_config.on_attach = function(client, bufnr)
        -- Setup Scala-specific DAP behavior
        setup_scala_dap()

        -- Setup DAP for Scala - this registers the configurations
        require("metals").setup_dap()

        -- Wait a bit and ensure configurations are set
        vim.defer_fn(function()
          local dap = require "dap"
          if not dap.configurations.scala or #dap.configurations.scala == 0 then
            -- Fallback configurations if Metals didn't set them
            dap.configurations.scala = {
              {
                type = "scala",
                request = "launch",
                name = "RunOrTest",
                metals = {
                  runType = "runOrTestFile",
                },
              },
              {
                type = "scala",
                request = "launch",
                name = "Test",
                metals = {
                  runType = "testTarget",
                },
              },
            }
          end

          -- Print debug info
          vim.notify("DAP configurations for Scala: " .. #dap.configurations.scala, vim.log.levels.INFO)
        end, 1000)

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

        -- Key mappings for Metals-specific actions
        local opts = { buffer = bufnr, silent = true }

        -- Metals specific commands
        vim.keymap.set(
          "n",
          "<leader>mc",
          function() require("metals").commands() end,
          vim.tbl_extend("force", opts, { desc = "Metals Commands" })
        )

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
          "<leader>ma",
          function() require("metals").run_doctor() end,
          vim.tbl_extend("force", opts, { desc = "Run Doctor" })
        )

        vim.keymap.set(
          "n",
          "<leader>mR",
          function() require("metals").restart_metals() end,
          vim.tbl_extend("force", opts, { desc = "Restart Metals" })
        )

        -- Compilation commands
        vim.keymap.set(
          "n",
          "<leader>mC",
          function() require("metals").compile_cascade() end,
          vim.tbl_extend("force", opts, { desc = "Compile Cascade" })
        )

        -- Code lens and run commands
        vim.keymap.set(
          "n",
          "<leader>ml",
          function() vim.lsp.codelens.run() end,
          vim.tbl_extend("force", opts, { desc = "Run Code Lens" })
        )

        vim.keymap.set(
          "n",
          "<leader>mr",
          function() require("metals").run_scoped() end,
          vim.tbl_extend("force", opts, { desc = "Run Scoped" })
        )

        -- Test commands
        vim.keymap.set(
          "n",
          "<leader>tr",
          function() require("metals").test_run() end,
          vim.tbl_extend("force", opts, { desc = "Run Test" })
        )

        vim.keymap.set(
          "n",
          "<leader>tt",
          function() require("metals").test_target() end,
          vim.tbl_extend("force", opts, { desc = "Test Target" })
        )

        -- Debug commands
        vim.keymap.set(
          "n",
          "<leader>md",
          function() require("metals").debug_scoped() end,
          vim.tbl_extend("force", opts, { desc = "Debug Scoped" })
        )

        vim.keymap.set(
          "n",
          "<leader>td",
          function() require("metals").test_debug() end,
          vim.tbl_extend("force", opts, { desc = "Debug Test" })
        )

        -- DAP keymaps
        vim.keymap.set(
          "n",
          "<leader>dc",
          function() require("dap").continue() end,
          vim.tbl_extend("force", opts, { desc = "Continue" })
        )

        vim.keymap.set(
          "n",
          "<leader>dr",
          function() require("dap").repl.toggle() end,
          vim.tbl_extend("force", opts, { desc = "Toggle REPL" })
        )

        vim.keymap.set(
          "n",
          "<leader>dK",
          function() require("dap.ui.widgets").hover() end,
          vim.tbl_extend("force", opts, { desc = "Hover" })
        )

        vim.keymap.set(
          "n",
          "<leader>dt",
          function() require("dap").toggle_breakpoint() end,
          vim.tbl_extend("force", opts, { desc = "Toggle Breakpoint" })
        )

        vim.keymap.set(
          "n",
          "<leader>dso",
          function() require("dap").step_over() end,
          vim.tbl_extend("force", opts, { desc = "Step Over" })
        )

        vim.keymap.set(
          "n",
          "<leader>dsi",
          function() require("dap").step_into() end,
          vim.tbl_extend("force", opts, { desc = "Step Into" })
        )

        vim.keymap.set(
          "n",
          "<leader>dl",
          function() require("dap").run_last() end,
          vim.tbl_extend("force", opts, { desc = "Run Last" })
        )

        vim.keymap.set(
          "n",
          "<leader>du",
          function() require("dapui").toggle() end,
          vim.tbl_extend("force", opts, { desc = "Toggle DAP UI" })
        )
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
