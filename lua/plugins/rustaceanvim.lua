-- lua/plugins/rustaceanvim.lua
-- Fixed configuration with proper inlay hints setup

return {
  "mrcjkb/rustaceanvim",
  version = "^5", 
  lazy = false, -- Load immediately
  ft = { "rust" },
  
  init = function()
    -- Set up rustaceanvim BEFORE any other LSP stuff
    vim.g.rustaceanvim = {
      tools = {
        -- Enable all tools
        on_initialized = function()
          vim.notify("🦀 Rust-analyzer initialized successfully!", vim.log.levels.INFO)
        end,
        
        inlay_hints = {
          auto = true,
          only_current_line = false,
          show_parameter_hints = true,
          parameter_hints_prefix = "<- ",
          other_hints_prefix = "=> ",
        },
        
        hover_actions = {
          auto_focus = false,
          border = "rounded",
        },
        
        runnables = {
          use_telescope = true,
        },
      },
      
      server = {
        -- Explicitly set the command
        cmd = function()
          -- Try to find rust-analyzer in order of preference
          local candidates = {
            "rust-analyzer", -- System PATH
            vim.fn.expand("~/.cargo/bin/rust-analyzer"),
            "/usr/local/bin/rust-analyzer",
          }
          
          for _, cmd in ipairs(candidates) do
            if vim.fn.executable(cmd) == 1 then
              vim.notify("Using rust-analyzer: " .. cmd, vim.log.levels.INFO)
              return { cmd }
            end
          end
          
          vim.notify("⚠️ rust-analyzer not found!", vim.log.levels.ERROR)
          return { "rust-analyzer" } -- fallback
        end,
        
        -- Proper root directory detection
        root_dir = function(fname)
          local util = require("lspconfig.util")
          
          -- Look for Cargo.toml
          local cargo_root = util.root_pattern("Cargo.toml")(fname)
          if cargo_root then
            vim.notify("Found Cargo project at: " .. cargo_root, vim.log.levels.DEBUG)
            return cargo_root
          end
          
          -- Fallback to git root or file directory
          return util.find_git_ancestor(fname) or util.path.dirname(fname)
        end,
        
        -- Comprehensive settings
        default_settings = {
          ["rust-analyzer"] = {
            -- Cargo settings
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            
            -- Check settings
            checkOnSave = {
              enable = true,
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            
            -- Proc macro support
            procMacro = {
              enable = true,
              attributes = {
                enable = true,
              },
            },
            
            -- Diagnostics
            diagnostics = {
              enable = true,
              enableExperimental = true,
            },
            
            -- Completion
            completion = {
              addCallParentheses = true,
              addCallArgumentSnippets = true,
            },
            
            -- Inlay hints
            inlayHints = {
              typeHints = {
                enable = true,
              },
              parameterHints = {
                enable = true,
              },
              chainingHints = {
                enable = true,
              },
            },
            
            -- Lens
            lens = {
              enable = true,
              implementations = {
                enable = true,
              },
              references = {
                trait = { enable = true },
                adt = { enable = true },
                method = { enable = true },
                enumVariant = { enable = true },
              },
              run = {
                enable = true,
              },
            },
          },
        },
        
        -- Enhanced on_attach with FIXED inlay hints
        on_attach = function(client, bufnr)
          vim.notify("🦀 Rust-analyzer attached to buffer " .. bufnr, vim.log.levels.INFO)
          
          -- Verify capabilities
          local caps = client.server_capabilities
          vim.notify("Definition support: " .. tostring(caps.definitionProvider or false), vim.log.levels.DEBUG)
          vim.notify("Hover support: " .. tostring(caps.hoverProvider or false), vim.log.levels.DEBUG)
          vim.notify("References support: " .. tostring(caps.referencesProvider or false), vim.log.levels.DEBUG)
          
          -- FIXED: Enable inlay hints properly
          if caps.inlayHintProvider then
            -- Use pcall to safely enable inlay hints
            local ok, err = pcall(function()
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end)
            
            if not ok then
              -- Fallback method for older Neovim versions
              vim.notify("Using fallback inlay hints method", vim.log.levels.DEBUG)
              pcall(function()
                vim.lsp.inlay_hint.enable(bufnr, true)
              end)
            end
          end
          
          -- Set up keymaps
          local opts = { buffer = bufnr, silent = true }
          
          -- LSP navigation
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, 
            vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          
          vim.keymap.set("n", "gr", vim.lsp.buf.references, 
            vim.tbl_extend("force", opts, { desc = "Find references" }))
          
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, 
            vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
          
          vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, 
            vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
          
          vim.keymap.set("n", "K", vim.lsp.buf.hover, 
            vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
          
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, 
            vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
          
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, 
            vim.tbl_extend("force", opts, { desc = "Code actions" }))
          
          -- Rust-specific commands
          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp("runnables")
          end, vim.tbl_extend("force", opts, { desc = "Rust runnables" }))
          
          vim.keymap.set("n", "<leader>rd", function()
            vim.cmd.RustLsp("debuggables")
          end, vim.tbl_extend("force", opts, { desc = "Rust debuggables" }))
          
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp("testables")
          end, vim.tbl_extend("force", opts, { desc = "Rust testables" }))
          
          vim.keymap.set("n", "<leader>re", function()
            vim.cmd.RustLsp("explainError")
          end, vim.tbl_extend("force", opts, { desc = "Explain error" }))
          
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp("openCargo")
          end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
          
          vim.keymap.set("n", "<leader>rh", function()
            vim.cmd.RustLsp("hover", "actions")
          end, vim.tbl_extend("force", opts, { desc = "Hover actions" }))
        end,
        
        -- Better error handling
        on_new_config = function(config, new_root_dir)
          config.root_dir = new_root_dir
          vim.notify("Rust-analyzer root dir: " .. new_root_dir, vim.log.levels.DEBUG)
        end,
      },
    }
  end,
}
