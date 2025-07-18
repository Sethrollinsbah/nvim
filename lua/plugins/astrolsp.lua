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
              if require("astrolsp").config.features.codelens then 
                vim.lsp.codelens.refresh { bufnr = args.buf } 
              end
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

          -- Add these mappings to your astrocore.lua for comprehensive diagnostics navigation

-- ======= GLOBAL DIAGNOSTICS MAPPINGS =======

-- Find ALL diagnostics across the entire workspace
["<leader>fd"] = {
  function()
    require("telescope.builtin").diagnostics({
      prompt_title = "🔍 All Workspace Diagnostics",
      bufnr = nil, -- All buffers
    })
  end,
  desc = "Find all diagnostics (workspace)",
},

-- Find diagnostics for current buffer only
["<leader>fD"] = {
  function()
    require("telescope.builtin").diagnostics({
      prompt_title = "🔍 Current Buffer Diagnostics",
      bufnr = 0, -- Current buffer only
    })
  end,
  desc = "Find diagnostics (current buffer)",
},

-- Find only ERROR diagnostics (most critical)
["<leader>fe"] = {
  function()
    require("telescope.builtin").diagnostics({
      prompt_title = "🚨 Errors Only",
      severity = vim.diagnostic.severity.ERROR,
    })
  end,
  desc = "Find errors only",
},

-- Find only WARNING diagnostics
["<leader>fw"] = {
  function()
    require("telescope.builtin").diagnostics({
      prompt_title = "⚠️  Warnings Only",
      severity = vim.diagnostic.severity.WARN,
    })
  end,
  desc = "Find warnings only",
},

-- ======= WORKSPACE MEMBER DIAGNOSTICS =======
-- Add these debug commands to your astrocore.lua temporarily
-- Add these commands to help diagnose and fix the build/LSP issues

-- ======= BUILD DIAGNOSTICS =======

-- Check cargo build status with detailed output
["<leader>cb"] = {
  function()
    vim.notify("🔧 Running cargo build with detailed output...", vim.log.levels.INFO)
    
    -- Use jobstart for async execution with real-time output
    local output_lines = {}
    local error_lines = {}
    
    vim.fn.jobstart("cargo build", {
      on_stdout = function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= "" then
              table.insert(output_lines, line)
              vim.notify("📋 " .. line, vim.log.levels.INFO)
            end
          end
        end
      end,
      on_stderr = function(_, data)
        if data then
          for _, line in ipairs(data) do
            if line ~= "" then
              table.insert(error_lines, line)
              vim.notify("🚨 " .. line, vim.log.levels.WARN)
            end
          end
        end
      end,
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("✅ Build successful!", vim.log.levels.INFO)
        else
          vim.notify("❌ Build failed with exit code: " .. exit_code, vim.log.levels.ERROR)
          
          -- Show errors in quickfix
          if #error_lines > 0 then
            vim.notify("Opening build errors in quickfix...", vim.log.levels.INFO)
            vim.fn.setqflist({}, 'r', {
              title = 'Cargo Build Errors',
              lines = error_lines
            })
            vim.cmd('copen')
          end
        end
        
        -- Try to restart LSP after build
        vim.defer_fn(function()
          vim.notify("Restarting rust-analyzer after build...", vim.log.levels.INFO)
          vim.cmd("LspRestart")
        end, 1000)
      end,
    })
  end,
  desc = "Cargo build with diagnostics",
},

-- Check specific build issues
["<leader>cB"] = {
  function()
    vim.notify("🔍 Checking for common build issues...", vim.log.levels.INFO)
    
    -- Check Cargo.toml exists
    local cargo_toml = vim.fn.getcwd() .. "/Cargo.toml"
    if vim.fn.filereadable(cargo_toml) ~= 1 then
      vim.notify("❌ No Cargo.toml found in current directory", vim.log.levels.ERROR)
      return
    end
    
    vim.notify("✅ Cargo.toml found", vim.log.levels.INFO)
    
    -- Check if target directory has issues
    local target_dir = vim.fn.getcwd() .. "/target"
    if vim.fn.isdirectory(target_dir) == 1 then
      vim.notify("✅ Target directory exists", vim.log.levels.INFO)
      
      -- Check if there are lock files that might be causing issues
      local lock_files = vim.fn.glob(target_dir .. "/**/*.lock", false, true)
      if #lock_files > 0 then
        vim.notify("⚠️ Found " .. #lock_files .. " lock files in target/", vim.log.levels.WARN)
        
        vim.ui.select({"Yes", "No"}, {
          prompt = "Clean target directory to fix lock issues?",
        }, function(choice)
          if choice == "Yes" then
            vim.cmd("!cargo clean")
            vim.notify("🧹 Target directory cleaned", vim.log.levels.INFO)
          end
        end)
      end
    end
    
    -- Check Cargo.lock
    local cargo_lock = vim.fn.getcwd() .. "/Cargo.lock"
    if vim.fn.filereadable(cargo_lock) == 1 then
      vim.notify("✅ Cargo.lock found", vim.log.levels.INFO)
    else
      vim.notify("⚠️ No Cargo.lock - this might be intentional", vim.log.levels.WARN)
    end
  end,
  desc = "Check build environment",
},

-- ======= LSP RECOVERY COMMANDS =======

-- Complete LSP reset and restart

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
    local util = require('lspconfig.util')
    local root_dir = util.root_pattern('Cargo.toml')(current_file) or vim.fn.getcwd()
    
    vim.notify("Using root directory: " .. root_dir, vim.log.levels.INFO)
    
    -- Start LSP manually
    vim.lsp.start({
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
    })
  end,
  desc = "Force start rust-analyzer",
},

-- ======= PROJECT HEALTH CHECK =======

-- Comprehensive project health check
["<leader>ch"] = {
  function()
    vim.notify("🏥 Running project health check...", vim.log.levels.INFO)
    
    local issues = {}
    local fixes = {}
    
    -- Check 1: Cargo.toml
    local cargo_toml = vim.fn.getcwd() .. "/Cargo.toml"
    if vim.fn.filereadable(cargo_toml) ~= 1 then
      table.insert(issues, "❌ No Cargo.toml found")
    else
      vim.notify("✅ Cargo.toml exists", vim.log.levels.INFO)
    end
    
    -- Check 2: rust-analyzer
    local ra_path = "/Users/sethr/.cargo/bin/rust-analyzer"
    if vim.fn.executable(ra_path) ~= 1 then
      table.insert(issues, "❌ rust-analyzer not executable")
      table.insert(fixes, "Run: chmod +x " .. ra_path)
    else
      vim.notify("✅ rust-analyzer is executable", vim.log.levels.INFO)
    end
    
    -- Check 3: Current file type
    local ft = vim.bo.filetype
    if ft ~= "rust" then
      table.insert(issues, "❌ File not recognized as Rust (filetype: " .. ft .. ")")
      table.insert(fixes, "Save file with .rs extension")
    else
      vim.notify("✅ File recognized as Rust", vim.log.levels.INFO)
    end
    
    -- Check 4: LSP clients
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    if #clients == 0 then
      table.insert(issues, "❌ No LSP clients active for this buffer")
      table.insert(fixes, "Use <leader>LS to force start rust-analyzer")
    else
      vim.notify("✅ " .. #clients .. " LSP client(s) active", vim.log.levels.INFO)
    end
    
    -- Check 5: Build status
    vim.fn.jobstart("cargo check --message-format=short", {
      on_exit = function(_, exit_code)
        if exit_code ~= 0 then
          table.insert(issues, "❌ Project has build errors")
          table.insert(fixes, "Fix build errors with cargo check")
        else
          vim.notify("✅ Project builds successfully", vim.log.levels.INFO)
        end
        
        -- Show summary
        if #issues > 0 then
          vim.notify("🚨 Found " .. #issues .. " issues:", vim.log.levels.WARN)
          for _, issue in ipairs(issues) do
            vim.notify("  " .. issue, vim.log.levels.WARN)
          end
          
          if #fixes > 0 then
            vim.notify("🔧 Suggested fixes:", vim.log.levels.INFO)
            for _, fix in ipairs(fixes) do
              vim.notify("  " .. fix, vim.log.levels.INFO)
            end
          end
        else
          vim.notify("🎉 All checks passed!", vim.log.levels.INFO)
        end
      end,
    })
  end,
  desc = "Project health check",
},

-- ======= EMERGENCY FIXES =======

-- Nuclear option: clean everything and restart
["<leader>cN"] = {
  function()
    vim.ui.select({"Yes, do it", "No, cancel"}, {
      prompt = "⚠️ This will clean target/ and restart everything. Continue?",
    }, function(choice)
      if choice == "Yes, do it" then
        vim.notify("🧨 Nuclear reset initiated...", vim.log.levels.WARN)
        
        -- Step 1: Stop all LSP
        local clients = vim.lsp.get_active_clients()
        for _, client in ipairs(clients) do
          client.stop()
        end
        
        -- Step 2: Clean cargo
        vim.fn.jobstart("cargo clean", {
          on_exit = function()
            vim.notify("🧹 Cargo clean completed", vim.log.levels.INFO)
            
            -- Step 3: Clear diagnostics
            vim.diagnostic.reset()
            
            -- Step 4: Reload buffer
            vim.defer_fn(function()
              vim.cmd("edit!")
              vim.notify("🔄 Buffer reloaded", vim.log.levels.INFO)
              
              -- Step 5: Try to start rust-analyzer
              vim.defer_fn(function()
                local rust_clients = vim.lsp.get_active_clients({ name = "rust_analyzer" })
                if #rust_clients == 0 then
                  vim.notify("🚀 Starting rust-analyzer...", vim.log.levels.INFO)
                  -- Trigger the force start
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>LS", true, false, true), "n", false)
                end
              end, 2000)
            end, 1000)
          end,
        })
      end
    end)
  end,
  desc = "Nuclear reset (clean + restart everything)",
},
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
    vim.notify("Is .rs file: " .. tostring(filename:match("%.rs$") ~= nil), vim.log.levels.INFO)
    
    -- Check active LSP clients
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
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
    local clients = vim.lsp.get_active_clients({ name = "rust_analyzer" })
    for _, client in ipairs(clients) do
      vim.notify("Stopping client: " .. client.name, vim.log.levels.INFO)
      client.stop()
    end
    
    -- Wait and restart
    vim.defer_fn(function()
      vim.notify("Reloading buffer to restart LSP...", vim.log.levels.INFO)
      vim.cmd("edit!")
      
      -- Check if it restarted
      vim.defer_fn(function()
        local new_clients = vim.lsp.get_active_clients({ name = "rust_analyzer" })
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
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    
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
      rust_analyzer_cmd = vim.fn.expand("~/.cargo/bin/rust-analyzer")
      if vim.fn.executable(rust_analyzer_cmd) ~= 1 then
        vim.notify("❌ rust-analyzer not found!", vim.log.levels.ERROR)
        return
      end
    end
    
    vim.notify("Found rust-analyzer: " .. rust_analyzer_cmd, vim.log.levels.INFO)
    
    -- Start LSP client manually
    local root_dir = vim.fn.getcwd()
    
    vim.lsp.start({
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
    })
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

-- Check rustaceanvim status
["<leader>LR"] = {
  function()
    vim.notify("=== Rustaceanvim Status ===", vim.log.levels.INFO)
    
    -- Check if rustaceanvim is loaded
    local rustacean_loaded = pcall(require, "rustaceanvim")
    vim.notify("Rustaceanvim loaded: " .. tostring(rustacean_loaded), vim.log.levels.INFO)
    
    -- Check config
    local config_set = vim.g.rustaceanvim ~= nil
    vim.notify("Config set: " .. tostring(config_set), vim.log.levels.INFO)
    
    if config_set then
      vim.notify("Config type: " .. type(vim.g.rustaceanvim), vim.log.levels.INFO)
    end
    
    -- Check if we're in a Rust file
    local ft = vim.bo.filetype
    vim.notify("Filetype: " .. ft, vim.log.levels.INFO)
    vim.notify("Should trigger: " .. tostring(ft == "rust"), vim.log.levels.INFO)
  end,
  desc = "Check rustaceanvim status",
},
-- Find diagnostics in specific workspace member
["<leader>fdm"] = {
  function()
    local workspace_utils = require("workspace_utils")
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
        
        require("telescope.builtin").diagnostics({
          prompt_title = "🔍 Diagnostics in " .. choice,
          search_dirs = { member_path },
        })
      end
    end)
  end,
  desc = "Find diagnostics in workspace member",
},

-- Find diagnostics in current workspace member (auto-detect)
["<leader>fdl"] = {
  function()
    local workspace_utils = require("workspace_utils")
    local workspace_info = workspace_utils.get_workspace_info()
    
    if not workspace_info.is_workspace then
      -- Fallback to current buffer diagnostics
      require("telescope.builtin").diagnostics({ bufnr = 0 })
      return
    end
    
    -- Find which workspace member we're currently in
    local current_dir = vim.fn.expand("%:p:h")
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
      require("telescope.builtin").diagnostics({
        prompt_title = "🔍 Diagnostics in " .. current_member,
        search_dirs = { member_path },
      })
    else
      vim.notify("Not currently in a workspace member", vim.log.levels.WARN)
      require("telescope.builtin").diagnostics({ bufnr = 0 })
    end
  end,
  desc = "Find diagnostics in current member",
},

-- ======= NAVIGATION MAPPINGS =======

-- Quick navigation through diagnostics
["]d"] = {
  function()
    vim.diagnostic.goto_next({
      severity = { min = vim.diagnostic.severity.HINT },
      float = true,
    })
  end,
  desc = "Next diagnostic",
},

["[d"] = {
  function()
    vim.diagnostic.goto_prev({
      severity = { min = vim.diagnostic.severity.HINT },
      float = true,
    })
  end,
  desc = "Previous diagnostic",
},

-- Navigate only through errors
["]e"] = {
  function()
    vim.diagnostic.goto_next({
      severity = vim.diagnostic.severity.ERROR,
      float = true,
    })
  end,
  desc = "Next error",
},

["[e"] = {
  function()
    vim.diagnostic.goto_prev({
      severity = vim.diagnostic.severity.ERROR,
      float = true,
    })
  end,
  desc = "Previous error",
},

-- Navigate only through warnings
["]w"] = {
  function()
    vim.diagnostic.goto_next({
      severity = vim.diagnostic.severity.WARN,
      float = true,
    })
  end,
  desc = "Next warning",
},

["[w"] = {
  function()
    vim.diagnostic.goto_prev({
      severity = vim.diagnostic.severity.WARN,
      float = true,
    })
  end,
  desc = "Previous warning",
},

-- ======= DIAGNOSTIC DETAILS =======

-- Show diagnostic details in floating window
["<leader>dd"] = {
  function()
    vim.diagnostic.open_float({
      border = "rounded",
      source = "always",
      scope = "cursor",
    })
  end,
  desc = "Show diagnostic details",
},

-- Show all diagnostics for current line
["<leader>dl"] = {
  function()
    vim.diagnostic.open_float({
      border = "rounded",
      source = "always",
      scope = "line",
    })
  end,
  desc = "Show line diagnostics",
},

-- ======= DIAGNOSTIC QUICKFIX =======

-- Send all workspace diagnostics to quickfix list
["<leader>dq"] = {
  function()
    vim.diagnostic.setqflist({
      title = "Workspace Diagnostics",
      severity = { min = vim.diagnostic.severity.HINT },
    })
    vim.cmd("copen")
  end,
  desc = "Diagnostics to quickfix",
},

-- Send only errors to quickfix list
["<leader>dE"] = {
  function()
    vim.diagnostic.setqflist({
      title = "Workspace Errors",
      severity = vim.diagnostic.severity.ERROR,
    })
    vim.cmd("copen")
  end,
  desc = "Errors to quickfix",
},

-- ======= DIAGNOSTIC SUMMARY =======

-- Show diagnostic summary for workspace
["<leader>ds"] = {
  function()
    local workspace_utils = require("workspace_utils")
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
    require("telescope.builtin").diagnostics({
      prompt_title = "🔧 Clippy Diagnostics",
      -- Filter for clippy messages
      -- Note: This might need adjustment based on how clippy reports appear
    })
  end,
  desc = "Show Clippy diagnostics",
},

-- Run cargo check and show diagnostics
["<leader>dc"] = {
  function()
    vim.notify("Running cargo check...", vim.log.levels.INFO)
    
    vim.fn.jobstart("cargo check", {
      on_exit = function(_, exit_code)
        if exit_code == 0 then
          vim.notify("✓ Cargo check completed successfully", vim.log.levels.INFO)
        else
          vim.notify("✗ Cargo check found issues", vim.log.levels.WARN)
        end
        
        -- Refresh diagnostics
        vim.defer_fn(function()
          require("telescope.builtin").diagnostics({
            prompt_title = "🔍 Updated Diagnostics",
          })
        end, 1000)
      end,
    })
  end,
  desc = "Run cargo check and show diagnostics",
},

-- ======= DIAGNOSTIC FILTERING =======

-- Toggle showing all diagnostics vs errors only
["<leader>dt"] = {
  function()
    local current_config = vim.diagnostic.config()
    local showing_all = current_config.severity_sort
    
    if showing_all then
      -- Show only errors and warnings
      vim.diagnostic.config({
        severity_sort = false,
        virtual_text = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
        signs = {
          severity = { min = vim.diagnostic.severity.WARN },
        },
      })
      vim.notify("📊 Showing errors and warnings only", vim.log.levels.INFO)
    else
      -- Show all diagnostics
      vim.diagnostic.config({
        severity_sort = true,
        virtual_text = true,
        signs = true,
      })
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
        if client.supports_method "textDocument/codeLens" then 
          vim.lsp.codelens.refresh { bufnr = bufnr } 
        end

        -- Load language-specific on_attach for non-rust languages
        for _, lang in ipairs(languages) do
          local config = load_lang_config(lang)
          if config.on_attach and type(config.on_attach) == "function" then 
            config.on_attach(client, bufnr) 
          end
        end
      end,
    }
  end,
}
