return {
      "scalameta/nvim-metals",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "mfussenegger/nvim-dap",
      },
      ft = { "scala", "sbt", "java" },
      config = function()
        local metals_config = require("metals").bare_config()
        
        -- Enhanced settings
        metals_config.settings = {
          showImplicitArguments = true,
          showImplicitConversionsAndClasses = true,
          showInferredType = true,
          superMethodLensesEnabled = true,
          enableSemanticHighlighting = false,
          excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
        }
        
        metals_config.init_options.statusBarProvider = "on"
        metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()
        
        -- Critical: Proper on_attach function
        metals_config.on_attach = function(client, bufnr)
          -- Setup DAP for Scala
          require("metals").setup_dap()
          
          -- Enable code lenses
          if client.server_capabilities.codeLensProvider then
            vim.lsp.codelens.refresh()
            
            -- Auto-refresh code lenses on various events
            vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
              buffer = bufnr,
              callback = function()
                vim.lsp.codelens.refresh()
              end,
            })
          end
          
          -- Key mappings for Metals-specific actions
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set("n", "<leader>mc", function()
            require("metals").commands()
          end, opts)
          
          vim.keymap.set("n", "<leader>mi", function()
            require("metals").toggle_setting("showImplicitArguments")
          end, opts)
          
          -- Debugging keymaps
          vim.keymap.set("n", "<leader>dc", function()
            require("dap").continue()
          end, opts)
          
          vim.keymap.set("n", "<leader>dr", function()
            require("dap").repl.toggle()
          end, opts)
          
          vim.keymap.set("n", "<leader>dK", function()
            require("dap.ui.widgets").hover()
          end, opts)
          
          vim.keymap.set("n", "<leader>dt", function()
            require("dap").toggle_breakpoint()
          end, opts)
          
          vim.keymap.set("n", "<leader>dso", function()
            require("dap").step_over()
          end, opts)
          
          vim.keymap.set("n", "<leader>dsi", function()
            require("dap").step_into()
          end, opts)
          
          vim.keymap.set("n", "<leader>dl", function()
            require("dap").run_last()
          end, opts)
        end
        
        -- Initialize metals for Scala files
        local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "scala", "sbt", "java" },
          callback = function()
            require("metals").initialize_or_attach(metals_config)
          end,
          group = nvim_metals_group,
        })
        
        -- Import build on VimEnter if in a Scala project
        vim.api.nvim_create_autocmd("VimEnter", {
          callback = function()
            if vim.fn.fnamemodify(vim.fn.getcwd(), ":t") == "zio" then
              vim.defer_fn(function()
                require("metals").import_build()
              end, 1000)
            end
          end,
          group = nvim_metals_group,
        })
      end,
  }
