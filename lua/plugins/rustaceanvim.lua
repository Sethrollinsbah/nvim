-- lua/plugins/rustaceanvim.lua
-- Enhanced Rust plugin configuration with proper workspace support

return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  ft = { "rust" },
  
  config = function()
    vim.g.rustaceanvim = {
      -- Plugin configuration
      tools = {
        executor = "toggleterm",
        on_initialized = function()
          -- Auto-detect workspace root and notify
          local workspace_root = vim.fn.getcwd()
          local cargo_toml = workspace_root .. "/Cargo.toml"
          
          if vim.fn.filereadable(cargo_toml) == 1 then
            local content = vim.fn.readfile(cargo_toml)
            local is_workspace = false
            
            for _, line in ipairs(content) do
              if line:match("^%[workspace%]") then
                is_workspace = true
                break
              end
            end
            
            if is_workspace then
              vim.notify("Detected Cargo workspace at: " .. workspace_root, vim.log.levels.INFO)
            end
          end
        end,
        reload_workspace_from_cargo_toml = true,
        inlay_hints = {
          auto = true,
          only_current_line = false,
          show_parameter_hints = true,
          parameter_hints_prefix = "<- ",
          other_hints_prefix = "=> ",
          max_len_align = false,
          max_len_align_padding = 1,
          right_align = false,
          right_align_padding = 7,
          highlight = "Comment",
        },
        hover_actions = {
          auto_focus = false,
        },
        runnables = {
          use_telescope = true,
        },
        debuggables = {
          use_telescope = true,
        },
        crate_graph = {
          backend = "x11",
          output = nil,
          full = true,
          enabled_graphviz_backends = { "svg", "png", "dot" },
        },
      },
      
      -- Enhanced LSP configuration for workspaces
      server = {
        on_attach = function(client, bufnr)
          -- Enable inlay hints
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(bufnr, true)
          end
          
          -- Workspace-aware keymaps
          local opts = { buffer = bufnr, silent = true }
          
          -- Enhanced workspace commands
          vim.keymap.set("n", "<leader>rw", function()
            -- Show workspace info
            local workspace_root = vim.lsp.buf.list_workspace_folders()[1] or vim.fn.getcwd()
            local cargo_toml = workspace_root .. "/Cargo.toml"
            
            if vim.fn.filereadable(cargo_toml) == 1 then
              local content = vim.fn.readfile(cargo_toml)
              local members = {}
              local in_workspace = false
              
              for _, line in ipairs(content) do
                if line:match("^%[workspace%]") then
                  in_workspace = true
                elseif in_workspace and line:match("^members") then
                  -- Extract workspace members
                  local members_line = line:gsub("members%s*=%s*%[", ""):gsub("%]", "")
                  for member in members_line:gmatch('"([^"]*)"') do
                    table.insert(members, member)
                  end
                elseif in_workspace and line:match("^%[") and not line:match("^%[workspace") then
                  break
                end
              end
              
              if #members > 0 then
                vim.notify("Workspace members: " .. table.concat(members, ", "), vim.log.levels.INFO)
              else
                vim.notify("Single crate project", vim.log.levels.INFO)
              end
            end
          end, vim.tbl_extend("force", opts, { desc = "Show workspace info" }))
          
          -- Workspace-aware build commands
          vim.keymap.set("n", "<leader>rB", function()
            vim.cmd("!cargo build --workspace")
          end, vim.tbl_extend("force", opts, { desc = "Build workspace" }))
          
          vim.keymap.set("n", "<leader>rT", function()
            vim.cmd("!cargo test --workspace")
          end, vim.tbl_extend("force", opts, { desc = "Test workspace" }))
          
          vim.keymap.set("n", "<leader>rC", function()
            vim.cmd("!cargo check --workspace")
          end, vim.tbl_extend("force", opts, { desc = "Check workspace" }))
          
          vim.keymap.set("n", "<leader>rW", function()
            vim.cmd("!cargo clean --workspace")
          end, vim.tbl_extend("force", opts, { desc = "Clean workspace" }))
          
          -- Package-specific commands
          vim.keymap.set("n", "<leader>rpp", function()
            local package_name = vim.fn.input("Package name: ")
            if package_name ~= "" then
              vim.cmd("!cargo build -p " .. package_name)
            end
          end, vim.tbl_extend("force", opts, { desc = "Build specific package" }))
          
          vim.keymap.set("n", "<leader>rpt", function()
            local package_name = vim.fn.input("Package name: ")
            if package_name ~= "" then
              vim.cmd("!cargo test -p " .. package_name)
            end
          end, vim.tbl_extend("force", opts, { desc = "Test specific package" }))
          
          vim.keymap.set("n", "<leader>rpr", function()
            local package_name = vim.fn.input("Package name: ")
            if package_name ~= "" then
              vim.cmd("!cargo run -p " .. package_name)
            end
          end, vim.tbl_extend("force", opts, { desc = "Run specific package" }))
          
          -- Enhanced runnables with workspace context
          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp('runnables')
          end, vim.tbl_extend("force", opts, { desc = "Runnables (workspace-aware)" }))
          
          -- Regular commands (keeping existing ones)
          vim.keymap.set("n", "<leader>ca", function()
            vim.cmd.RustLsp('codeAction')
          end, vim.tbl_extend("force", opts, { desc = "Code Action" }))
          
          vim.keymap.set("n", "<leader>rd", function()
            vim.cmd.RustLsp('debuggables')
          end, vim.tbl_extend("force", opts, { desc = "Debuggables" }))
          
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp('testables')
          end, vim.tbl_extend("force", opts, { desc = "Testables" }))
          
          -- Enhanced workspace navigation
          vim.keymap.set("n", "<leader>rfc", function()
            -- Find Cargo.toml files in workspace
            require('telescope.builtin').find_files({
              prompt_title = "Cargo.toml Files",
              search_dirs = {vim.fn.getcwd()},
              find_command = {"find", ".", "-name", "Cargo.toml", "-type", "f"},
            })
          end, vim.tbl_extend("force", opts, { desc = "Find Cargo.toml files" }))
          
          vim.keymap.set("n", "<leader>rfr", function()
            -- Find Rust files in workspace
            require('telescope.builtin').find_files({
              prompt_title = "Rust Files",
              search_dirs = {vim.fn.getcwd()},
              find_command = {"find", ".", "-name", "*.rs", "-type", "f"},
            })
          end, vim.tbl_extend("force", opts, { desc = "Find Rust files" }))
          
          -- Other existing keymaps
          vim.keymap.set("n", "<leader>rem", function()
            vim.cmd.RustLsp('expandMacro')
          end, vim.tbl_extend("force", opts, { desc = "Expand macro" }))
          
          vim.keymap.set("n", "<leader>re", function()
            vim.cmd.RustLsp('explainError')
          end, vim.tbl_extend("force", opts, { desc = "Explain error" }))
          
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp('openCargo')
          end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
          
          vim.keymap.set("n", "<leader>rh", function()
            vim.cmd.RustLsp('hover', 'actions')
          end, vim.tbl_extend("force", opts, { desc = "Hover actions" }))
        end,
        
        -- Enhanced settings for workspace support
        default_settings = {
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
              -- Workspace-specific settings
              features = "all",
              noDefaultFeatures = false,
              target = nil, -- Let rust-analyzer detect
              allTargets = true,
            },
            checkOnSave = {
              enable = true,
              allFeatures = true,
              command = "clippy",
              extraArgs = { "--no-deps", "--workspace" },
            },
            -- Enhanced workspace symbol handling
            workspace = {
              symbol = {
                search = {
                  scope = "workspace",
                  kind = "all_symbols",
                },
              },
            },
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            diagnostics = {
              enable = true,
              experimental = {
                enable = true,
              },
            },
            inlayHints = {
              bindingModeHints = {
                enable = false,
              },
              chainingHints = {
                enable = true,
              },
              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
              closureReturnTypeHints = {
                enable = "never",
              },
              lifetimeElisionHints = {
                enable = "never",
                useParameterNames = false,
              },
              maxLength = 25,
              parameterHints = {
                enable = true,
              },
              reborrowHints = {
                enable = "never",
              },
              renderColons = true,
              typeHints = {
                enable = true,
                hideClosureInitialization = false,
                hideNamedConstructor = false,
              },
            },
            -- Improve completion for workspaces
            completion = {
              addCallParentheses = true,
              addCallArgumentSnippets = true,
              postfix = {
                enable = true,
              },
            },
            -- Better import handling for workspaces
            imports = {
              granularity = {
                group = "module",
              },
              prefix = "self",
            },
            -- Lens settings for better workspace navigation
            lens = {
              enable = true,
              implementations = {
                enable = true,
              },
              references = {
                adt = {
                  enable = true,
                },
                enumVariant = {
                  enable = true,
                },
                method = {
                  enable = true,
                },
                trait = {
                  enable = true,
                },
              },
              run = {
                enable = true,
              },
            },
          },
        },
        
        -- Better root directory detection for workspaces
        root_dir = function(fname)
          local util = require('lspconfig.util')
          
          -- Look for workspace Cargo.toml first
          local workspace_root = util.root_pattern('Cargo.toml')(fname)
          
          if workspace_root then
            local cargo_toml = workspace_root .. '/Cargo.toml'
            if vim.fn.filereadable(cargo_toml) == 1 then
              local content = vim.fn.readfile(cargo_toml)
              for _, line in ipairs(content) do
                if line:match('^%[workspace%]') then
                  return workspace_root
                end
              end
            end
          end
          
          -- Fall back to regular detection
          return util.root_pattern('Cargo.toml', 'rust-project.json')(fname)
            or util.find_git_ancestor(fname)
            or util.path.dirname(fname)
        end,
      },
      
      -- Enhanced DAP configuration for workspaces
      dap = {
        adapter = {
          type = "server",
          port = "${port}",
          executable = {
            command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
            args = { "--port", "${port}" },
          },
        },
        configuration = {
          {
            name = "Launch workspace binary",
            type = "codelldb",
            request = "launch",
            program = function()
              -- Let user choose from workspace binaries
              local workspace_root = vim.fn.getcwd()
              local target_dir = workspace_root .. "/target/debug"
              
              if vim.fn.isdirectory(target_dir) == 1 then
                local binaries = {}
                local handle = io.popen("find " .. target_dir .. " -maxdepth 1 -type f -executable 2>/dev/null")
                
                if handle then
                  for file in handle:lines() do
                    if not file:match("%.d$") and not file:match("deps/") then
                      table.insert(binaries, file)
                    end
                  end
                  handle:close()
                end
                
                if #binaries > 1 then
                  local choice = vim.fn.inputlist(
                    vim.list_extend({"Select binary:"}, 
                      vim.tbl_map(function(b) return vim.fn.fnamemodify(b, ":t") end, binaries))
                  )
                  return binaries[choice] or binaries[1]
                elseif #binaries == 1 then
                  return binaries[1]
                end
              end
              
              return vim.fn.input("Path to executable: ", workspace_root .. "/target/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = function()
              local args_string = vim.fn.input("Arguments: ")
              return args_string ~= "" and vim.split(args_string, " ") or {}
            end,
          },
        },
      },
    }
  end,
}
