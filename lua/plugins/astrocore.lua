-- lua/plugins/astrocore.lua
-- Enhanced AstroCore provides a central place to modify mappings, vim options, autocommands, and more!

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 500, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics_mode = 3, -- diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = on)
      highlighturl = true,
      notifications = true,
    },

    -- Diagnostics configuration
    diagnostics = {
      virtual_text = true,
      underline = true,
      signs = true,
      update_in_insert = false,
      severity_sort = true,
    },

    -- vim options
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        scrolloff = 8,
        sidescrolloff = 8,
        timeoutlen = 300,
        updatetime = 250,
        -- Better completion experience
        completeopt = { "menu", "menuone", "noselect" },
        -- Better search
        ignorecase = true,
        smartcase = true,
        -- Better splits
        splitbelow = true,
        splitright = true,
      },
      g = {
        -- configure global vim variables
      },
    },

    -- Enhanced autocommands for workspace detection
    autocmds = {
      -- Rust workspace detection
      rust_workspace = {
        {
          event = { "BufEnter", "BufWinEnter" },
          pattern = "*.rs",
          callback = function()
            -- Auto-detect workspace and set appropriate settings
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
                -- Set workspace-specific options
                vim.opt_local.path:append(workspace_root .. "/*/src")
                vim.opt_local.suffixesadd:append(".rs")
                
                -- Set a buffer variable to track workspace status
                vim.b.rust_workspace = true
                
                -- Show workspace notification (only once per session)
                if not vim.g.rust_workspace_notified then
                  vim.notify("🦀 Rust workspace detected", vim.log.levels.INFO)
                  vim.g.rust_workspace_notified = true
                end
              end
            end
          end,
        },
      },
      
      -- Move workspace detection
      move_workspace = {
        {
          event = { "BufEnter", "BufWinEnter" },
          pattern = "*.move",
          callback = function()
            local move_root = vim.fn.getcwd()
            local move_toml = move_root .. "/Move.toml"
            local sui_toml = move_root .. "/Sui.toml"
            
            if vim.fn.filereadable(move_toml) == 1 or vim.fn.filereadable(sui_toml) == 1 then
              -- Set workspace-specific options
              vim.opt_local.path:append(move_root .. "/sources")
              vim.opt_local.path:append(move_root .. "/*/sources")
              vim.opt_local.suffixesadd:append(".move")
              
              -- Set a buffer variable to track workspace status
              vim.b.move_workspace = true
              
              -- Show workspace notification (only once per session)
              if not vim.g.move_workspace_notified then
                vim.notify("🏗️ Move project detected", vim.log.levels.INFO)
                vim.g.move_workspace_notified = true
              end
            end
          end,
        },
      },
    },

    -- Enhanced Global Mappings configuration
    mappings = {
      n = {
        -- Buffer navigation
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- Buffer management
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },

        -- ======= ENHANCED TELESCOPE MAPPINGS =======
        
        -- Smart find with recent usage priority
        ["<leader>ff"] = {
          function()
            local builtin = require "telescope.builtin"
            local themes = require "telescope.themes"

            -- Smart find priority:
            -- 1. Recent files (oldfiles) if we have history
            -- 2. Git files if in git repo
            -- 3. All files as fallback

            -- Check if we have recent files
            local oldfiles = vim.v.oldfiles or {}
            local cwd = vim.fn.getcwd()
            local recent_in_cwd = {}

            -- Filter oldfiles to current working directory
            for _, file in ipairs(oldfiles) do
              if file:match("^" .. vim.pesc(cwd)) then table.insert(recent_in_cwd, file) end
            end

            if #recent_in_cwd > 3 then
              -- We have recent files in this directory - prioritize them
              builtin.oldfiles(themes.get_dropdown {
                prompt_title = "Recent Files",
                previewer = false,
                layout_config = { width = 0.8, height = 0.8 },
                cwd_only = true,
                only_cwd = true,
              })
            else
              -- Check if we're in a git repo for git files
              local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
              if vim.v.shell_error == 0 then
                -- In git repo: search git files
                builtin.git_files(themes.get_dropdown {
                  show_untracked = true,
                  prompt_title = "Git Files",
                  previewer = false,
                  layout_config = { width = 0.8, height = 0.8 },
                })
              else
                -- Not in git repo: search all files
                builtin.find_files(themes.get_dropdown {
                  hidden = true,
                  prompt_title = "Find Files",
                  previewer = false,
                  layout_config = { width = 0.8, height = 0.8 },
                  find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
                })
              end
            end
          end,
          desc = "Smart find (Recent → Git → All files)",
        },

        -- Original git/all files finder
        ["<leader>fF"] = {
          function()
            local builtin = require "telescope.builtin"
            local themes = require "telescope.themes"

            -- Check if we're in a git repo
            local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            if vim.v.shell_error == 0 then
              -- In git repo: search git files
              builtin.git_files(themes.get_dropdown {
                show_untracked = true,
                prompt_title = "Git Files",
                previewer = false,
                layout_config = { width = 0.8, height = 0.8 },
              })
            else
              -- Not in git repo: search all files
              builtin.find_files(themes.get_dropdown {
                hidden = true,
                prompt_title = "Find Files",
                previewer = false,
                layout_config = { width = 0.8, height = 0.8 },
                find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
              })
            end
          end,
          desc = "Find files (Git → All files)",
        },

        -- All files including ignored
        ["<leader>fa"] = {
          function()
            require("telescope.builtin").find_files {
              hidden = true,
              no_ignore = true,
              find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*" },
            }
          end,
          desc = "Find all files (including ignored)",
        },

        ["<leader>fg"] = {
          function() require("telescope.builtin").live_grep() end,
          desc = "Live grep",
        },

        ["<leader>fb"] = {
          function()
            require("telescope.builtin").buffers {
              prompt_title = "Recent Buffers",
              previewer = false,
              layout_config = { width = 0.8, height = 0.8 },
              sort_lastused = true,
              sort_mru = true,
              ignore_current_buffer = true,
              show_all_buffers = false,
            }
          end,
          desc = "Find recent buffers",
        },

        -- All buffers including current
        ["<leader>fB"] = {
          function()
            require("telescope.builtin").buffers {
              prompt_title = "All Buffers",
              sort_lastused = true,
              show_all_buffers = true,
            }
          end,
          desc = "Find all buffers",
        },

        -- Ultimate smart finder - combines everything with priority
        ["<leader>f<space>"] = {
          function()
            local pickers = require "telescope.pickers"
            local finders = require "telescope.finders"
            local conf = require("telescope.config").values
            local actions = require "telescope.actions"
            local action_state = require "telescope.actions.state"

            -- Create a custom finder that combines recent files, git files, and buffers
            local function smart_finder()
              local results = {}

              -- Add recent buffers (highest priority)
              local buffers = vim.api.nvim_list_bufs()
              for _, buf in ipairs(buffers) do
                if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) ~= "" then
                  local name = vim.api.nvim_buf_get_name(buf)
                  local display_name = vim.fn.fnamemodify(name, ":~:.")
                  table.insert(results, {
                    value = name,
                    display = "📄 " .. display_name,
                    ordinal = display_name,
                    type = "buffer",
                  })
                end
              end

              -- Add recent files
              local oldfiles = vim.v.oldfiles or {}
              local cwd = vim.fn.getcwd()
              for i, file in ipairs(oldfiles) do
                if i > 10 then break end -- Limit to 10 recent files
                if file:match("^" .. vim.pesc(cwd)) then
                  local display_name = vim.fn.fnamemodify(file, ":~:.")
                  table.insert(results, {
                    value = file,
                    display = "🕐 " .. display_name,
                    ordinal = display_name,
                    type = "recent",
                  })
                end
              end

              return results
            end

            pickers
              .new({}, {
                prompt_title = "Smart Find (Buffers + Recent)",
                finder = finders.new_table {
                  results = smart_finder(),
                  entry_maker = function(entry)
                    return {
                      value = entry.value,
                      display = entry.display,
                      ordinal = entry.ordinal,
                    }
                  end,
                },
                sorter = conf.generic_sorter {},
                previewer = false,
                layout_config = { width = 0.8, height = 0.8 },
                attach_mappings = function(prompt_bufnr, map)
                  actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then vim.cmd("edit " .. selection.value) end
                  end)
                  return true
                end,
              })
              :find()
          end,
          desc = "Smart find (buffers + recent files)",
        },

        -- ======= WORKSPACE-SPECIFIC TELESCOPE MAPPINGS =======
        
        -- Workspace-specific telescope pickers
        ["<leader>fwr"] = {
          function()
            require('telescope.builtin').find_files({
              prompt_title = "Workspace Rust Files",
              search_dirs = {vim.fn.getcwd()},
              find_command = {"rg", "--files", "--type", "rust"},
            })
          end,
          desc = "Find Rust files in workspace",
        },
        
        ["<leader>fwc"] = {
          function()
            require('telescope.builtin').find_files({
              prompt_title = "Workspace Cargo Files",
              search_dirs = {vim.fn.getcwd()},
              find_command = {"find", ".", "-name", "Cargo.toml", "-type", "f"},
            })
          end,
          desc = "Find Cargo.toml files",
        },
        
        ["<leader>fwt"] = {
          function()
            require('telescope.builtin').live_grep({
              prompt_title = "Search Tests in Workspace",
              search_dirs = {vim.fn.getcwd()},
              default_text = "#[test]",
              additional_args = {"--type", "rust"},
            })
          end,
          desc = "Find tests in workspace",
        },
        
        ["<leader>fwm"] = {
          function()
            require('telescope.builtin').live_grep({
              prompt_title = "Search Macros in Workspace",
              search_dirs = {vim.fn.getcwd()},
              default_text = "macro_rules!",
              additional_args = {"--type", "rust"},
            })
          end,
          desc = "Find macros in workspace",
        },

        -- ======= ADDITIONAL TELESCOPE MAPPINGS =======
        
        ["<leader>fh"] = {
          function() require("telescope.builtin").help_tags() end,
          desc = "Find help",
        },

        ["<leader>fo"] = {
          function()
            require("telescope.builtin").oldfiles {
              prompt_title = "Recent Files (Global)",
              previewer = false,
              layout_config = { width = 0.8, height = 0.8 },
            }
          end,
          desc = "Find recent files (global)",
        },

        ["<leader>fw"] = {
          function() require("telescope.builtin").grep_string() end,
          desc = "Find word under cursor",
        },

        ["<leader>fc"] = {
          function() require("telescope.builtin").commands() end,
          desc = "Find commands",
        },

        ["<leader>fk"] = {
          function() require("telescope.builtin").keymaps() end,
          desc = "Find keymaps",
        },

        ["<leader>fd"] = {
          function() require("telescope.builtin").diagnostics() end,
          desc = "Find diagnostics",
        },

        ["<leader>fr"] = {
          function() require("telescope.builtin").lsp_references() end,
          desc = "Find references",
        },

        ["<leader>fs"] = {
          function()
            -- Check if any LSP client supports document symbols
            local clients = vim.lsp.get_active_clients { bufnr = 0 }
            local has_document_symbols = false

            for _, client in pairs(clients) do
              if client.server_capabilities.documentSymbolProvider then
                has_document_symbols = true
                break
              end
            end

            if has_document_symbols then
              require("telescope.builtin").lsp_document_symbols {
                prompt_title = "Document Symbols",
                show_line = true,
                symbol_width = 50,
                symbol_type_width = 20,
              }
            else
              -- Fallback to treesitter symbols if available, then to file outline
              local ts_ok, _ = pcall(require, "nvim-treesitter.parsers")
              if ts_ok and require("nvim-treesitter.parsers").has_parser() then
                require("telescope.builtin").treesitter {
                  prompt_title = "Treesitter Symbols",
                  show_line = true,
                }
              else
                -- Final fallback to current buffer lines with symbols
                require("telescope.builtin").current_buffer_fuzzy_find {
                  prompt_title = "Buffer Lines",
                  previewer = false,
                }
              end
            end
          end,
          desc = "Find symbols (LSP/Treesitter/Lines)",
        },

        ["<leader>fS"] = {
          function()
            -- Check if any LSP client supports workspace symbols
            local clients = vim.lsp.get_active_clients()
            local has_workspace_symbols = false

            for _, client in pairs(clients) do
              if client.server_capabilities.workspaceSymbolProvider then
                has_workspace_symbols = true
                break
              end
            end

            if has_workspace_symbols then
              require("telescope.builtin").lsp_workspace_symbols {
                prompt_title = "Workspace Symbols",
                show_line = true,
                symbol_width = 50,
                symbol_type_width = 20,
              }
            else
              -- Fallback to live grep with symbol-like patterns
              require("telescope.builtin").live_grep {
                prompt_title = "Search Workspace (No LSP)",
                additional_args = function() return { "--type-add", "code:*.{rs,java,py,js,ts,lua}" } end,
              }
            end
          end,
          desc = "Find workspace symbols (LSP/Grep)",
        },

        -- Add a comprehensive symbol search across all LSP clients
        ["<leader>fsa"] = {
          function()
            local clients = vim.lsp.get_active_clients { bufnr = 0 }
            local symbol_clients = {}

            -- Collect all clients that support document symbols
            for _, client in pairs(clients) do
              if client.server_capabilities.documentSymbolProvider then table.insert(symbol_clients, client.name) end
            end

            if #symbol_clients > 0 then
              vim.notify("LSP clients with symbols: " .. table.concat(symbol_clients, ", "), vim.log.levels.INFO)
              require("telescope.builtin").lsp_document_symbols {
                prompt_title = "All LSP Document Symbols",
                show_line = true,
                symbol_width = 50,
                symbol_type_width = 20,
              }
            else
              vim.notify("No LSP clients with document symbol support found", vim.log.levels.WARN)
              -- Show available clients
              local all_clients = {}
              for _, client in pairs(clients) do
                table.insert(all_clients, client.name)
              end
              if #all_clients > 0 then
                vim.notify("Active LSP clients: " .. table.concat(all_clients, ", "), vim.log.levels.INFO)
              end
            end
          end,
          desc = "Find symbols from all LSP clients",
        },

        -- ======= WORKSPACE NAVIGATION MAPPINGS =======
        
        -- Quick workspace navigation
        ["<leader>wn"] = {
          function()
            -- Navigate to next package in workspace
            local current_dir = vim.fn.expand("%:p:h")
            local workspace_root = vim.fn.getcwd()
            local cargo_toml = workspace_root .. "/Cargo.toml"
            
            if vim.fn.filereadable(cargo_toml) == 1 then
              local content = vim.fn.readfile(cargo_toml)
              local members = {}
              local in_workspace = false
              
              for _, line in ipairs(content) do
                if line:match("^%[workspace%]") then
                  in_workspace = true
                elseif in_workspace and line:match("^members") then
                  local members_line = line:gsub("members%s*=%s*%[", ""):gsub("%]", "")
                  for member in members_line:gmatch('"([^"]*)"') do
                    table.insert(members, workspace_root .. "/" .. member)
                  end
                elseif in_workspace and line:match("^%[") and not line:match("^%[workspace") then
                  break
                end
              end
              
              if #members > 0 then
                -- Find current package index
                local current_idx = 1
                for i, member in ipairs(members) do
                  if current_dir:match("^" .. vim.pesc(member)) then
                    current_idx = i
                    break
                  end
                end
                
                -- Navigate to next package
                local next_idx = (current_idx % #members) + 1
                local next_member = members[next_idx]
                local src_path = next_member .. "/src"
                
                if vim.fn.isdirectory(src_path) == 1 then
                  local main_file = src_path .. "/main.rs"
                  local lib_file = src_path .. "/lib.rs"
                  
                  if vim.fn.filereadable(main_file) == 1 then
                    vim.cmd("edit " .. main_file)
                  elseif vim.fn.filereadable(lib_file) == 1 then
                    vim.cmd("edit " .. lib_file)
                  else
                    vim.cmd("edit " .. src_path)
                  end
                end
              end
            end
          end,
          desc = "Navigate to next workspace package",
        },
        
        ["<leader>wp"] = {
          function()
            -- Navigate to previous package in workspace
            local current_dir = vim.fn.expand("%:p:h")
            local workspace_root = vim.fn.getcwd()
            local cargo_toml = workspace_root .. "/Cargo.toml"
            
            if vim.fn.filereadable(cargo_toml) == 1 then
              local content = vim.fn.readfile(cargo_toml)
              local members = {}
              local in_workspace = false
              
              for _, line in ipairs(content) do
                if line:match("^%[workspace%]") then
                  in_workspace = true
                elseif in_workspace and line:match("^members") then
                  local members_line = line:gsub("members%s*=%s*%[", ""):gsub("%]", "")
                  for member in members_line:gmatch('"([^"]*)"') do
                    table.insert(members, workspace_root .. "/" .. member)
                  end
                elseif in_workspace and line:match("^%[") and not line:match("^%[workspace") then
                  break
                end
              end
              
              if #members > 0 then
                -- Find current package index
                local current_idx = 1
                for i, member in ipairs(members) do
                  if current_dir:match("^" .. vim.pesc(member)) then
                    current_idx = i
                    break
                  end
                end
                
                -- Navigate to previous package
                local prev_idx = current_idx == 1 and #members or current_idx - 1
                local prev_member = members[prev_idx]
                local src_path = prev_member .. "/src"
                
                if vim.fn.isdirectory(src_path) == 1 then
                  local main_file = src_path .. "/main.rs"
                  local lib_file = src_path .. "/lib.rs"
                  
                  if vim.fn.filereadable(main_file) == 1 then
                    vim.cmd("edit " .. main_file)
                  elseif vim.fn.filereadable(lib_file) == 1 then
                    vim.cmd("edit " .. lib_file)
                  else
                    vim.cmd("edit " .. src_path)
                  end
                end
              end
            end
          end,
          desc = "Navigate to previous workspace package",
        },
        
        -- Workspace overview
        ["<leader>wo"] = {
          function()
            local workspace_root = vim.fn.getcwd()
            local cargo_toml = workspace_root .. "/Cargo.toml"
            
            if vim.fn.filereadable(cargo_toml) == 1 then
              local content = vim.fn.readfile(cargo_toml)
              local members = {}
              local in_workspace = false
              local lines = {"📦 Cargo Workspace Overview", ""}
              
              for _, line in ipairs(content) do
                if line:match("^%[workspace%]") then
                  in_workspace = true
                elseif in_workspace and line:match("^members") then
                  local members_line = line:gsub("members%s*=%s*%[", ""):gsub("%]", "")
                  for member in members_line:gmatch('"([^"]*)"') do
                    table.insert(members, member)
                  end
                elseif in_workspace and line:match("^%[") and not line:match("^%[workspace") then
                  break
                end
              end
              
              if #members > 0 then
                table.insert(lines, "📁 Workspace Members:")
                for _, member in ipairs(members) do
                  local member_cargo = workspace_root .. "/" .. member .. "/Cargo.toml"
                  if vim.fn.filereadable(member_cargo) == 1 then
                    local member_content = vim.fn.readfile(member_cargo)
                    local package_name = ""
                    for _, m_line in ipairs(member_content) do
                      local name = m_line:match('^name%s*=%s*"(.-)"')
                      if name then
                        package_name = name
                        break
                      end
                    end
                    table.insert(lines, "  • " .. member .. " (" .. package_name .. ")")
                  else
                    table.insert(lines, "  • " .. member)
                  end
                end
              else
                table.insert(lines, "Single package project")
              end
              
              -- Create floating window
              local buf = vim.api.nvim_create_buf(false, true)
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
              vim.api.nvim_buf_set_option(buf, "modifiable", false)
              vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
              
              local width = 60
              local height = #lines + 2
              local win = vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width = width,
                height = height,
                row = math.floor((vim.o.lines - height) / 2),
                col = math.floor((vim.o.columns - width) / 2),
                style = "minimal",
                border = "rounded",
                title = " Workspace Overview ",
                title_pos = "center",
              })
              
              vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<cr>", { silent = true })
              vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<cr>", { silent = true })
            end
          end,
          desc = "Show workspace overview",
        },

        -- ======= LSP MAPPINGS =======
        
        -- LSP info command
        ["<leader>li"] = {
          function()
            local clients = vim.lsp.get_active_clients { bufnr = 0 }
            if #clients == 0 then
              vim.notify("No LSP clients attached to current buffer", vim.log.levels.WARN)
              return
            end

            local info = {}
            for _, client in pairs(clients) do
              local capabilities = {
                name = client.name,
                document_symbols = client.server_capabilities.documentSymbolProvider or false,
                workspace_symbols = client.server_capabilities.workspaceSymbolProvider or false,
                code_actions = client.server_capabilities.codeActionProvider or false,
                formatting = client.server_capabilities.documentFormattingProvider or false,
                hover = client.server_capabilities.hoverProvider or false,
                references = client.server_capabilities.referencesProvider or false,
                rename = client.server_capabilities.renameProvider or false,
                definition = client.server_capabilities.definitionProvider or false,
              }
              table.insert(info, capabilities)
            end

            -- Create a nice display
            local lines = { "LSP Client Capabilities:", "" }
            for _, client_info in pairs(info) do
              table.insert(lines, "📋 " .. client_info.name .. ":")
              table.insert(lines, "  • Document Symbols: " .. (client_info.document_symbols and "✅" or "❌"))
              table.insert(lines, "  • Workspace Symbols: " .. (client_info.workspace_symbols and "✅" or "❌"))
              table.insert(lines, "  • Code Actions: " .. (client_info.code_actions and "✅" or "❌"))
              table.insert(lines, "  • Formatting: " .. (client_info.formatting and "✅" or "❌"))
              table.insert(lines, "  • Hover: " .. (client_info.hover and "✅" or "❌"))
              table.insert(lines, "  • References: " .. (client_info.references and "✅" or "❌"))
              table.insert(lines, "  • Rename: " .. (client_info.rename and "✅" or "❌"))
              table.insert(lines, "  • Definition: " .. (client_info.definition and "✅" or "❌"))
              table.insert(lines, "")
            end

            -- Display in a floating window
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(buf, "modifiable", false)
            vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

            local width = 50
            local height = #lines
            local win = vim.api.nvim_open_win(buf, true, {
              relative = "editor",
              width = width,
              height = height,
              row = math.floor((vim.o.lines - height) / 2),
              col = math.floor((vim.o.columns - width) / 2),
              style = "minimal",
              border = "rounded",
              title = " LSP Info ",
              title_pos = "center",
            })

            -- Close on escape or q
            vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<cr>", { silent = true })
            vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<cr>", { silent = true })
          end,
          desc = "Show LSP client capabilities",
        },

        -- Global LSP mappings (work for all languages)
        ["gd"] = {
          function() vim.lsp.buf.definition() end,
          desc = "Go to definition",
        },
        ["gr"] = {
          function() vim.lsp.buf.references() end,
          desc = "Go to references",
        },
        ["gi"] = {
          function() vim.lsp.buf.implementation() end,
          desc = "Go to implementation",
        },
        ["gt"] = {
          function() vim.lsp.buf.type_definition() end,
          desc = "Go to type definition",
        },
        ["K"] = {
          function() vim.lsp.buf.hover() end,
          desc = "Hover documentation",
        },
        ["<leader>la"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "Code action",
        },
        ["<leader>rn"] = {
          function() vim.lsp.buf.rename() end,
          desc = "Rename symbol",
        },
        ["<leader>D"] = {
          function() vim.diagnostic.open_float() end,
          desc = "Show line diagnostics",
        },
        ["[d"] = {
          function() vim.diagnostic.goto_prev() end,
          desc = "Previous diagnostic",
        },
        ["]d"] = {
          function() vim.diagnostic.goto_next() end,
          desc = "Next diagnostic",
        },

        -- ======= DAP MAPPINGS =======
        
        -- Global DAP mappings (work for all languages)
        ["<leader>db"] = {
          function() require("dap").toggle_breakpoint() end,
          desc = "Toggle breakpoint",
        },
        ["<leader>dB"] = {
          function() require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ") end,
          desc = "Set conditional breakpoint",
        },
        ["<leader>dc"] = {
          function()
            local dap = require "dap"
            local ft = vim.bo.filetype

            -- Language-specific debug start logic
            if ft == "rust" then
              -- For Rust, build first then debug
              vim.fn.system "cargo build"
              dap.continue()
            else
              -- For other languages, just continue
              dap.continue()
            end
          end,
          desc = "Start/Continue debugging",
        },
        ["<leader>dC"] = {
          function() require("dap").run_to_cursor() end,
          desc = "Run to cursor",
        },
        ["<leader>dg"] = {
          function() require("dap").goto_() end,
          desc = "Go to line (no execute)",
        },
        ["<leader>di"] = {
          function() require("dap").step_into() end,
          desc = "Step into",
        },
        ["<leader>dj"] = {
          function() require("dap").down() end,
          desc = "Down",
        },
        ["<leader>dk"] = {
          function() require("dap").up() end,
          desc = "Up",
        },
        ["<leader>dl"] = {
          function() require("dap").run_last() end,
          desc = "Run last",
        },
        ["<leader>do"] = {
          function() require("dap").step_out() end,
          desc = "Step out",
        },
        ["<leader>dO"] = {
          function() require("dap").step_over() end,
          desc = "Step over",
        },
        ["<leader>dp"] = {
          function() require("dap").pause() end,
          desc = "Pause",
        },
        ["<leader>dr"] = {
          function() require("dap").repl.toggle() end,
          desc = "Toggle REPL",
        },
        ["<leader>ds"] = {
          function() require("dap").session() end,
          desc = "Session",
        },
        ["<leader>dt"] = {
          function() require("dap").terminate() end,
          desc = "Terminate",
        },
        ["<leader>du"] = {
          function() require("dapui").toggle() end,
          desc = "Toggle DAP UI",
        },
        ["<leader>dw"] = {
          function() require("dap.ui.widgets").hover() end,
          desc = "Widgets",
        },

        -- ======= TEST MAPPINGS =======
        
        -- Global Test mappings (work for all languages)
        ["<leader>tr"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              -- Check if we're in a workspace
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
                  vim.cmd("!cargo test --workspace")
                else
                  vim.cmd("!cargo test")
                end
              else
                vim.cmd("!cargo test")
              end
            else
              vim.notify("No test runner configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Run tests",
        },
        ["<leader>tt"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              vim.cmd("!cargo test --all")
            else
              vim.notify("No test target configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Run all tests",
        },
        ["<leader>td"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              vim.notify("Rust test debugging - use DAP with test binary", vim.log.levels.INFO)
            else
              vim.notify("No test debug configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Debug tests",
        },

        -- ======= BUILD/RUN MAPPINGS =======
        
        -- Global Build/Run mappings with workspace awareness
        ["<leader>br"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              -- Check if we're in a workspace
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
                  -- In workspace, ask which package to run
                  local package_name = vim.fn.input("Package name (or Enter for default): ")
                  if package_name ~= "" then
                    vim.cmd("!cargo run -p " .. package_name)
                  else
                    vim.cmd("!cargo run")
                  end
                else
                  vim.cmd("!cargo run")
                end
              else
                vim.cmd("!cargo run")
              end
            else
              vim.notify("No run command configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Build and run",
        },
        ["<leader>bb"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              -- Check if we're in a workspace
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
                  vim.cmd("!cargo build --workspace")
                else
                  vim.cmd("!cargo build")
                end
              else
                vim.cmd("!cargo build")
              end
            else
              vim.notify("No build command configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Build project",
        },
        ["<leader>bc"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              -- Check if we're in a workspace
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
                  vim.cmd("!cargo clean --workspace")
                else
                  vim.cmd("!cargo clean")
                end
              else
                vim.cmd("!cargo clean")
              end
            else
              vim.notify("No clean command configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Clean project",
        },

        -- ======= TERMINAL MAPPINGS =======
        
        -- Terminal mappings
        ["<leader>tf"] = {
          function() require("toggleterm").toggle() end,
          desc = "Toggle floating terminal",
        },
        ["<leader>th"] = {
          function() require("toggleterm").toggle(vim.v.count, 15, vim.fn.getcwd(), "horizontal") end,
          desc = "Toggle horizontal terminal",
        },
        ["<leader>tv"] = {
          function() require("toggleterm").toggle(vim.v.count, vim.o.columns * 0.4, vim.fn.getcwd(), "vertical") end,
          desc = "Toggle vertical terminal",
        },

        -- ======= ADDITIONAL UTILITY MAPPINGS =======
        
        -- Quick config editing
        ["<leader>ve"] = {
          function() vim.cmd("edit " .. vim.fn.stdpath("config") .. "/init.lua") end,
          desc = "Edit init.lua",
        },
        ["<leader>vr"] = {
          function() vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua") end,
          desc = "Reload config",
        },
        
        -- Quick save
        ["<leader>w"] = {
          function() vim.cmd("write") end,
          desc = "Save file",
        },
        
        -- Clear search highlighting
        ["<leader>nh"] = {
          function() vim.cmd("nohlsearch") end,
          desc = "Clear search highlights",
        },
        
        -- Toggle wrap
        ["<leader>uw"] = {
          function() 
            vim.opt_local.wrap = not vim.opt_local.wrap:get()
            vim.notify("Wrap " .. (vim.opt_local.wrap:get() and "enabled" or "disabled"))
          end,
          desc = "Toggle wrap",
        },
        
        -- Toggle relative numbers
        ["<leader>un"] = {
          function() 
            vim.opt_local.relativenumber = not vim.opt_local.relativenumber:get()
            vim.notify("Relative numbers " .. (vim.opt_local.relativenumber:get() and "enabled" or "disabled"))
          end,
          desc = "Toggle relative numbers",
        },
      },

      -- ======= VISUAL MODE MAPPINGS =======
      
      -- Visual mode mappings
      v = {
        ["<leader>la"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "Code action",
        },
        
        -- Better indenting
        ["<"] = { "<gv", desc = "Indent left" },
        [">"] = { ">gv", desc = "Indent right" },
        
        -- Move selected lines
        ["J"] = { ":m '>+1<CR>gv=gv", desc = "Move selection down" },
        ["K"] = { ":m '<-2<CR>gv=gv", desc = "Move selection up" },
      },

      -- ======= INSERT MODE MAPPINGS =======
      
      -- Insert mode mappings
      i = {
        -- Better escape
        ["jk"] = { "<ESC>", desc = "Escape insert mode" },
        ["kj"] = { "<ESC>", desc = "Escape insert mode" },
        
        -- Save in insert mode
        ["<C-s>"] = { "<cmd>w<cr><ESC>", desc = "Save file" },
      },

      -- ======= TERMINAL MODE MAPPINGS =======
      
      -- Terminal mode mappings
      t = {
        -- Better terminal navigation
        ["<C-h>"] = { "<C-\\><C-N><C-w>h", desc = "Terminal left window navigation" },
        ["<C-j>"] = { "<C-\\><C-N><C-w>j", desc = "Terminal down window navigation" },
        ["<C-k>"] = { "<C-\\><C-N><C-w>k", desc = "Terminal up window navigation" },
        ["<C-l>"] = { "<C-\\><C-N><C-w>l", desc = "Terminal right window navigation" },
        ["<esc>"] = { "<C-\\><C-n>", desc = "Terminal normal mode" },
        
        -- Better escape for terminal
        ["jk"] = { "<C-\\><C-n>", desc = "Terminal normal mode" },
        ["kj"] = { "<C-\\><C-n>", desc = "Terminal normal mode" },
      },
    },
  },
}
