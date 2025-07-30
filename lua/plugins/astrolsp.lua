-- lua/plugins/astrolsp.lua
-- Main AstroLSP configuration that loads language-specific configs

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = function()
    -- Load language-specific configurations
    local lang_configs = {}

    -- Helper function to safely load language configs
    local function load_lang_config(name)
      local ok, config = pcall(require, "plugins.languages." .. name)
      if ok and config then
        return config
      else
        vim.notify("Failed to load language config: " .. name, vim.log.levels.WARN)
        return {}
      end
    end

    -- Load all language configurations EXCEPT rust (handled by rustaceanvim)
    local languages = {
      "lua",
      "typescript",
      "python",
      "web",
      "system",
      -- NOTE: "rust" is excluded - handled by rustaceanvim
    }

    for _, lang in ipairs(languages) do
      local config = load_lang_config(lang)
      if config.servers then
        for server, opts in pairs(config.servers) do
          lang_configs[server] = opts
        end
      end
    end

    return {
      -- Configuration table of features provided by AstroLSP
      features = {
        autoformat = true,
        codelens = true,
        inlay_hints = false, -- Let rustaceanvim handle inlay hints for Rust
        semantic_tokens = true,
      },

      -- customize lsp formatting options
      formatting = {
        format_on_save = {
          enabled = true,
          allow_filetypes = {
            "lua",
            "javascript",
            "typescript",
            "json",
            "yaml",
            "python",
            "move",
            "html",
            "css",
            "svelte",
            -- NOTE: "rust" formatting is handled by rustaceanvim
          },
        },
        disabled = {
          -- Disable rust_analyzer formatting - rustaceanvim handles it
          "rust_analyzer",
        },
        timeout_ms = 3000,
      },

      -- IMPORTANT: Do not include rust_analyzer here
      servers = {
        -- Explicitly exclude rust_analyzer
      },

      -- Use the loaded language configurations (no rust configs)
      config = lang_configs,

      -- Setup handlers - explicitly prevent rust_analyzer
      setup_handlers = {
        -- Prevent rust_analyzer from being set up by astrolsp
        rust_analyzer = function(server_name, opts)
          vim.notify("Rust analyzer handled by rustaceanvim, skipping astrolsp setup", vim.log.levels.INFO)
          return false -- Don't setup
        end,
      },

      -- Configure buffer local auto commands
      autocmds = {
        lsp_codelens_refresh = {
          {
            event = { "InsertLeave", "BufEnter" },
            desc = "Refresh codelens (buffer)",
            callback = function(args)
              if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
            end,
          },
        },
      },

      -- mappings to be set up on attaching of a language server
      mappings = {
        n = {
          -- Standard LSP mappings (will work for all languages except Rust)
          gD = {
            function() vim.lsp.buf.declaration() end,
            desc = "Declaration of current symbol",
            cond = "textDocument/declaration",
          },

          ["<Leader>uY"] = {
            function() require("astrolsp.toggles").buffer_semantic_tokens() end,
            desc = "Toggle LSP semantic highlight (buffer)",
            cond = function(client)
              return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens
            end,
          },

          -- ======= GLOBAL DIAGNOSTICS MAPPINGS =======
          -- Find ALL diagnostics across the entire workspace
          ["<leader>fd"] = {
            function()
              require("telescope.builtin").diagnostics {
                prompt_title = "🔍 All Workspace Diagnostics",
                bufnr = nil, -- All buffers
              }
            end,
            desc = "Find all diagnostics (workspace)",
          },

          -- Find diagnostics for current buffer only
          ["<leader>fD"] = {
            function()
              require("telescope.builtin").diagnostics {
                prompt_title = "🔍 Current Buffer Diagnostics",
                bufnr = 0, -- Current buffer only
              }
            end,
            desc = "Find diagnostics (current buffer)",
          },

          -- Find only ERROR diagnostics (most critical)
          ["<leader>fe"] = {
            function()
              require("telescope.builtin").diagnostics {
                prompt_title = "🚨 Errors Only",
                severity = vim.diagnostic.severity.ERROR,
              }
            end,
            desc = "Find errors only",
          },

          -- Find only WARNING diagnostics
          ["<leader>fw"] = {
            function()
              require("telescope.builtin").diagnostics {
                prompt_title = "⚠️  Warnings Only",
                severity = vim.diagnostic.severity.WARN,
              }
            end,
            desc = "Find warnings only",
          },

          -- ======= WORKSPACE MEMBER DIAGNOSTICS =======
          -- Add these debug commands to your astrocore.lua temporarily
          -- Add these commands to help diagnose and fix the build/LSP issues

          -- ======= BUILD DIAGNOSTICS =======
          -- Force start rust-analyzer with explicit path
          ["<leader>LS"] = {
            function()
              vim.notify("🚀 Force starting rust-analyzer...", vim.log.levels.INFO)

              -- Use the explicit path we know works
              local rust_analyzer_path = "/Users/sethr/.cargo/bin/rust-analyzer"

              if vim.fn.executable(rust_analyzer_path) ~= 1 then
                vim.notify("❌ rust-analyzer not found at: " .. rust_analyzer_path, vim.log.levels.ERROR)
                return
              end

              -- Get current file's root directory
              local current_file = vim.api.nvim_buf_get_name(0)
              local util = require "lspconfig.util"
              local root_dir = util.root_pattern "Cargo.toml"(current_file) or vim.fn.getcwd()

              vim.notify("Using root directory: " .. root_dir, vim.log.levels.INFO)

              -- Start LSP manually
              vim.lsp.start {
                name = "rust_analyzer",
                cmd = { rust_analyzer_path },
                root_dir = root_dir,
                filetypes = { "rust" },
                settings = {
                  ["rust-analyzer"] = {
                    cargo = {
                      allFeatures = true,
                      loadOutDirsFromCheck = true,
                    },
                    checkOnSave = {
                      enable = true,
                      command = "clippy",
                    },
                    procMacro = {
                      enable = true,
                    },
                  },
                },
                on_attach = function(client, bufnr)
                  vim.notify("🎉 rust-analyzer attached! Client ID: " .. client.id, vim.log.levels.INFO)

                  -- Set up basic keymaps
                  local opts = { buffer = bufnr, silent = true }
                  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

                  vim.notify("LSP keymaps set up successfully", vim.log.levels.INFO)
                end,
              }
            end,
            desc = "Force start rust-analyzer",
          },

          -- ======= PROJECT HEALTH CHECK =======
          -- Debug LSP attachment
          ["<leader>Ld"] = {
            function()
              vim.notify("=== LSP Debug Info ===", vim.log.levels.INFO)

              -- Check file type
              local ft = vim.bo.filetype
              vim.notify("File type: " .. ft, vim.log.levels.INFO)

              -- Check if file is detected as Rust
              local filename = vim.api.nvim_buf_get_name(0)
              vim.notify("File: " .. filename, vim.log.levels.INFO)
              vim.notify("Is .rs file: " .. tostring(filename:match "%.rs$" ~= nil), vim.log.levels.INFO)

              -- Check active LSP clients
              local clients = vim.lsp.get_active_clients { bufnr = 0 }
              vim.notify("Active LSP clients for this buffer: " .. #clients, vim.log.levels.INFO)

              for _, client in ipairs(clients) do
                vim.notify("  - " .. client.name .. " (ID: " .. client.id .. ")", vim.log.levels.INFO)

                -- Check capabilities
                local caps = client.server_capabilities
                vim.notify("    Definition: " .. tostring(caps.definitionProvider or false), vim.log.levels.INFO)
                vim.notify("    Hover: " .. tostring(caps.hoverProvider or false), vim.log.levels.INFO)
                vim.notify("    References: " .. tostring(caps.referencesProvider or false), vim.log.levels.INFO)
              end

              -- Check all LSP clients (not just for this buffer)
              local all_clients = vim.lsp.get_active_clients()
              vim.notify("Total active LSP clients: " .. #all_clients, vim.log.levels.INFO)

              for _, client in ipairs(all_clients) do
                vim.notify("  - " .. client.name, vim.log.levels.INFO)
              end
            end,
            desc = "Debug LSP attachment",
          },

          -- Force restart rust-analyzer
          ["<leader>Lr"] = {
            function()
              vim.notify("Restarting rust-analyzer...", vim.log.levels.INFO)

              -- Stop existing rust-analyzer clients
              local clients = vim.lsp.get_active_clients { name = "rust_analyzer" }
              for _, client in ipairs(clients) do
                vim.notify("Stopping client: " .. client.name, vim.log.levels.INFO)
                client.stop()
              end

              -- Wait and restart
              vim.defer_fn(function()
                vim.notify("Reloading buffer to restart LSP...", vim.log.levels.INFO)
                vim.cmd "edit!"

                -- Check if it restarted
                vim.defer_fn(function()
                  local new_clients = vim.lsp.get_active_clients { name = "rust_analyzer" }
                  if #new_clients > 0 then
                    vim.notify("✅ rust-analyzer restarted successfully!", vim.log.levels.INFO)
                  else
                    vim.notify("❌ Failed to restart rust-analyzer", vim.log.levels.ERROR)
                  end
                end, 3000)
              end, 1000)
            end,
            desc = "Restart rust-analyzer",
          },

          -- Test LSP manually
          ["<leader>Lt"] = {
            function()
              vim.notify("Testing LSP functionality...", vim.log.levels.INFO)

              -- Check if we can call LSP methods
              local clients = vim.lsp.get_active_clients { bufnr = 0 }

              if #clients == 0 then
                vim.notify("❌ No LSP clients active", vim.log.levels.ERROR)
                return
              end

              vim.notify("✅ Found " .. #clients .. " active clients", vim.log.levels.INFO)

              -- Test hover
              vim.notify("Testing hover...", vim.log.levels.INFO)
              vim.lsp.buf.hover()

              -- Test if definition is available
              local pos = vim.api.nvim_win_get_cursor(0)
              vim.notify("Cursor position: line " .. pos[1] .. ", col " .. pos[2], vim.log.levels.INFO)
            end,
            desc = "Test LSP functionality",
          },

          -- Force start rust-analyzer manually
          ["<leader>Ls"] = {
            function()
              vim.notify("Manually starting rust-analyzer...", vim.log.levels.INFO)

              -- Check if rust-analyzer is available
              local rust_analyzer_cmd = "rust-analyzer"
              if vim.fn.executable(rust_analyzer_cmd) ~= 1 then
                rust_analyzer_cmd = vim.fn.expand "~/.cargo/bin/rust-analyzer"
                if vim.fn.executable(rust_analyzer_cmd) ~= 1 then
                  vim.notify("❌ rust-analyzer not found!", vim.log.levels.ERROR)
                  return
                end
              end

              vim.notify("Found rust-analyzer: " .. rust_analyzer_cmd, vim.log.levels.INFO)

              -- Start LSP client manually
              local root_dir = vim.fn.getcwd()

              vim.lsp.start {
                name = "rust_analyzer",
                cmd = { rust_analyzer_cmd },
                root_dir = root_dir,
                settings = {
                  ["rust-analyzer"] = {
                    cargo = {
                      allFeatures = true,
                    },
                    checkOnSave = {
                      command = "clippy",
                    },
                  },
                },
                on_attach = function(client, bufnr)
                  vim.notify("🎉 Manually started rust-analyzer!", vim.log.levels.INFO)

                  -- Set up basic keymaps
                  local opts = { buffer = bufnr, silent = true }
                  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                end,
              }
            end,
            desc = "Manually start rust-analyzer",
          },

          -- Show LSP log
          ["<leader>Ll"] = {
            function()
              local log_path = vim.lsp.get_log_path()
              vim.cmd("edit " .. log_path)
              vim.notify("Opened LSP log: " .. log_path, vim.log.levels.INFO)
            end,
            desc = "Show LSP log",
          },

          -- Find diagnostics in specific workspace member
          ["<leader>fdm"] = {
            function()
              local workspace_utils = require "workspace_utils"
              local workspace_info = workspace_utils.get_workspace_info()

              if not workspace_info.is_workspace or #workspace_info.members == 0 then
                vim.notify("No workspace members found", vim.log.levels.WARN)
                return
              end

              -- Let user select workspace member
              vim.ui.select(workspace_info.members, {
                prompt = "Select workspace member for diagnostics:",
                format_item = function(item) return item end,
              }, function(choice)
                if choice then
                  local member_path = workspace_info.root .. "/" .. choice

                  require("telescope.builtin").diagnostics {
                    prompt_title = "🔍 Diagnostics in " .. choice,
                    search_dirs = { member_path },
                  }
                end
              end)
            end,
            desc = "Find diagnostics in workspace member",
          },

          -- Find diagnostics in current workspace member (auto-detect)
          ["<leader>fdl"] = {
            function()
              local workspace_utils = require "workspace_utils"
              local workspace_info = workspace_utils.get_workspace_info()

              if not workspace_info.is_workspace then
                -- Fallback to current buffer diagnostics
                require("telescope.builtin").diagnostics { bufnr = 0 }
                return
              end

              -- Find which workspace member we're currently in
              local current_dir = vim.fn.expand "%:p:h"
              local current_member = nil

              for _, member in ipairs(workspace_info.members) do
                local member_path = workspace_info.root .. "/" .. member
                if current_dir:match("^" .. vim.pesc(member_path)) then
                  current_member = member
                  break
                end
              end

              if current_member then
                local member_path = workspace_info.root .. "/" .. current_member
                require("telescope.builtin").diagnostics {
                  prompt_title = "🔍 Diagnostics in " .. current_member,
                  search_dirs = { member_path },
                }
              else
                vim.notify("Not currently in a workspace member", vim.log.levels.WARN)
                require("telescope.builtin").diagnostics { bufnr = 0 }
              end
            end,
            desc = "Find diagnostics in current member",
          },

          -- ======= NAVIGATION MAPPINGS =======

          -- Quick navigation through diagnostics
          ["]d"] = {
            function()
              vim.diagnostic.goto_next {
                severity = { min = vim.diagnostic.severity.HINT },
                float = true,
              }
            end,
            desc = "Next diagnostic",
          },

          ["[d"] = {
            function()
              vim.diagnostic.goto_prev {
                severity = { min = vim.diagnostic.severity.HINT },
                float = true,
              }
            end,
            desc = "Previous diagnostic",
          },

          -- Navigate only through errors
          ["]e"] = {
            function()
              vim.diagnostic.goto_next {
                severity = vim.diagnostic.severity.ERROR,
                float = true,
              }
            end,
            desc = "Next error",
          },

          ["[e"] = {
            function()
              vim.diagnostic.goto_prev {
                severity = vim.diagnostic.severity.ERROR,
                float = true,
              }
            end,
            desc = "Previous error",
          },

          -- Navigate only through warnings
          ["]w"] = {
            function()
              vim.diagnostic.goto_next {
                severity = vim.diagnostic.severity.WARN,
                float = true,
              }
            end,
            desc = "Next warning",
          },

          ["[w"] = {
            function()
              vim.diagnostic.goto_prev {
                severity = vim.diagnostic.severity.WARN,
                float = true,
              }
            end,
            desc = "Previous warning",
          },

          -- ======= DIAGNOSTIC DETAILS =======

                  -- ======= DIAGNOSTIC QUICKFIX =======

          -- Send all workspace diagnostics to quickfix list
          ["<leader>dq"] = {
            function()
              vim.diagnostic.setqflist {
                title = "Workspace Diagnostics",
                severity = { min = vim.diagnostic.severity.HINT },
              }
              vim.cmd "copen"
            end,
            desc = "Diagnostics to quickfix",
          },

          -- Send only errors to quickfix list
          ["<leader>dE"] = {
            function()
              vim.diagnostic.setqflist {
                title = "Workspace Errors",
                severity = vim.diagnostic.severity.ERROR,
              }
              vim.cmd "copen"
            end,
            desc = "Errors to quickfix",
          },

          -- ======= DIAGNOSTIC SUMMARY =======

          -- Show diagnostic summary for workspace
          ["<leader>ds"] = {
            function()
              local workspace_utils = require "workspace_utils"
              local workspace_info = workspace_utils.get_workspace_info()

              -- Get all diagnostics
              local all_diagnostics = vim.diagnostic.get()

              -- Count by severity
              local counts = {
                [vim.diagnostic.severity.ERROR] = 0,
                [vim.diagnostic.severity.WARN] = 0,
                [vim.diagnostic.severity.INFO] = 0,
                [vim.diagnostic.severity.HINT] = 0,
              }

              for _, diag in ipairs(all_diagnostics) do
                counts[diag.severity] = counts[diag.severity] + 1
              end

              -- Create summary
              local lines = {
                "🔍 Diagnostic Summary",
                "",
                string.format("🚨 Errors: %d", counts[vim.diagnostic.severity.ERROR]),
                string.format("⚠️  Warnings: %d", counts[vim.diagnostic.severity.WARN]),
                string.format("ℹ️  Info: %d", counts[vim.diagnostic.severity.INFO]),
                string.format("💡 Hints: %d", counts[vim.diagnostic.severity.HINT]),
                "",
                string.format("📊 Total: %d diagnostics", #all_diagnostics),
              }

              if workspace_info.is_workspace then
                table.insert(lines, "")
                table.insert(lines, "🦀 Workspace: " .. workspace_info.root)
                table.insert(lines, "📦 Members: " .. #workspace_info.members)
              end

              -- Show in notification
              local message = table.concat(lines, "\n")
              vim.notify(message, vim.log.levels.INFO)
            end,
            desc = "Show diagnostic summary",
          },

          -- ======= RUST-SPECIFIC DIAGNOSTICS =======

          -- Show Clippy diagnostics only
          ["<leader>dC"] = {
            function()
              require("telescope.builtin").diagnostics {
                prompt_title = "🔧 Clippy Diagnostics",
                -- Filter for clippy messages
                -- Note: This might need adjustment based on how clippy reports appear
              }
            end,
            desc = "Show Clippy diagnostics",
          },
          -- ======= DIAGNOSTIC FILTERING =======

          -- Toggle showing all diagnostics vs errors only
          ["<leader>dt"] = {
            function()
              local current_config = vim.diagnostic.config()
              local showing_all = current_config.severity_sort

              if showing_all then
                -- Show only errors and warnings
                vim.diagnostic.config {
                  severity_sort = false,
                  virtual_text = {
                    severity = { min = vim.diagnostic.severity.WARN },
                  },
                  signs = {
                    severity = { min = vim.diagnostic.severity.WARN },
                  },
                }
                vim.notify("📊 Showing errors and warnings only", vim.log.levels.INFO)
              else
                -- Show all diagnostics
                vim.diagnostic.config {
                  severity_sort = true,
                  virtual_text = true,
                  signs = true,
                }
                vim.notify("📊 Showing all diagnostics", vim.log.levels.INFO)
              end
            end,
            desc = "Toggle diagnostic visibility",
          },
        },
      },

      -- General on_attach for NON-RUST servers
      on_attach = function(client, bufnr)
        -- Skip rust_analyzer completely - rustaceanvim handles it
        if client.name == "rust_analyzer" then
          vim.notify("Rust analyzer managed by rustaceanvim, skipping astrolsp on_attach", vim.log.levels.INFO)
          return
        end

        -- General LSP on_attach logic for other languages
        if client.supports_method "textDocument/codeLens" then vim.lsp.codelens.refresh { bufnr = bufnr } end

        -- Load language-specific on_attach for non-rust languages
        for _, lang in ipairs(languages) do
          local config = load_lang_config(lang)
          if config.on_attach and type(config.on_attach) == "function" then config.on_attach(client, bufnr) end
        end
      end,
    }
  end,
}
