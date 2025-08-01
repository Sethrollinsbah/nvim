-- lua/plugins/astrocore.lua
-- Enhanced AstroCore provides a central place to modify mappings, vim options, autocommands, and more!

-- Load the workspace utilities at the top level
local workspace_utils = require "workspace_utils"

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
            -- Use the improved workspace detection
            local workspace_info = workspace_utils.get_workspace_info()

            if workspace_info.is_workspace then
              -- Set workspace-specific options
              vim.opt_local.path:append(workspace_info.root .. "/*/src")
              vim.opt_local.suffixesadd:append ".rs"

              -- Set a buffer variable to track workspace status
              vim.b.rust_workspace = true

              -- Show workspace notification (only once per session)
              if not vim.g.rust_workspace_notified then
                vim.notify(
                  "🦀 Rust workspace detected (" .. #workspace_info.members .. " members)",
                  vim.log.levels.INFO
                )
                vim.g.rust_workspace_notified = true
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
              vim.opt_local.suffixesadd:append ".move"

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

        -- ======= ENHANCED WORKSPACE NAVIGATION MAPPINGS =======

        -- Quick workspace navigation
        ["<leader>wn"] = {
          function() workspace_utils.navigate_workspace_member "next" end,
          desc = "Navigate to next workspace package",
        },

        ["<leader>wp"] = {
          function() workspace_utils.navigate_workspace_member "prev" end,
          desc = "Navigate to previous workspace package",
        },

        -- Workspace overview
        ["<leader>wo"] = {
          function() workspace_utils.show_workspace_overview() end,
          desc = "Show workspace overview",
        },

        -- Debug workspace parsing
        ["<leader>wd"] = {
          function() workspace_utils.test_workspace_parsing() end,
          desc = "Debug workspace parsing",
        },

        -- Enhanced workspace info
        ["<leader>wi"] = {
          function()
            local workspace_info = workspace_utils.get_workspace_info()
            local message = string.format(
              "Workspace: %s | Members: %d | Root: %s",
              workspace_info.is_workspace and "Yes" or "No",
              #workspace_info.members,
              vim.fn.fnamemodify(workspace_info.root, ":t")
            )
            vim.notify(message, vim.log.levels.INFO)
          end,
          desc = "Show workspace info",
        },

        -- Workspace member picker
        ["<leader>wm"] = {
          function()
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace or #workspace_info.members == 0 then
              vim.notify("No workspace members found", vim.log.levels.WARN)
              return
            end

            -- Use vim.ui.select for member selection
            vim.ui.select(workspace_info.members, {
              prompt = "Select workspace member:",
              format_item = function(item) return item end,
            }, function(choice)
              if choice then
                local target_path = workspace_info.root .. "/" .. choice
                local src_path = target_path .. "/src"

                local files_to_try = {
                  src_path .. "/main.rs",
                  src_path .. "/lib.rs",
                  target_path .. "/Cargo.toml",
                }

                for _, file in ipairs(files_to_try) do
                  if vim.fn.filereadable(file) == 1 then
                    vim.cmd("edit " .. file)
                    vim.notify("Opened " .. choice, vim.log.levels.INFO)
                    return
                  end
                end

                vim.notify("Could not find files for " .. choice, vim.log.levels.WARN)
              end
            end)
          end,
          desc = "Select workspace member",
        },

        -- Enhanced workspace commands
        ["<leader>wc"] = {
          function()
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace then
              vim.notify("Not in a workspace", vim.log.levels.WARN)
              return
            end

            -- Show workspace command menu
            local commands = {
              { "Build workspace", "!cargo build --workspace" },
              { "Test workspace", "!cargo test --workspace" },
              { "Check workspace", "!cargo check --workspace" },
              { "Clean workspace", "!cargo clean --workspace" },
              { "Update workspace", "!cargo update --workspace" },
            }

            vim.ui.select(commands, {
              prompt = "Select workspace command:",
              format_item = function(item) return item[1] end,
            }, function(choice)
              if choice then vim.cmd(choice[2]) end
            end)
          end,
          desc = "Workspace commands",
        },

        -- ======= TERMINAL INTEGRATION =======
        -- Interactive cargo command menu
        -- Enhanced interactive cargo command menu with all targets and popup terminal
        ["<leader>mc"] = {
          function()
            -- Ensure toggleterm is loaded and available
            local has_toggleterm, toggleterm = pcall(require, "toggleterm")
            if not has_toggleterm then
              vim.notify("toggleterm.nvim is not installed or configured.", vim.log.levels.ERROR)
              return
            end
            local workspace_info = workspace_utils.get_workspace_info()
            local workspace_suffix = workspace_info.is_workspace and " --workspace" or ""

            -- Get available examples
            local function get_cargo_examples()
              local examples = {}
              local handle = io.popen "ls examples/*.rs 2>/dev/null | xargs -n1 basename -s .rs 2>/dev/null"
              if handle then
                for line in handle:lines() do
                  if line and line ~= "" then table.insert(examples, line) end
                end
                handle:close()
              end
              return examples
            end

            -- Get available binaries (only from current package)
            local function get_cargo_binaries()
              local binaries = {}
              local handle =
                io.popen "cargo metadata --format-version 1 --no-deps 2>/dev/null | jq -r '.packages[].targets[] | select(.kind[] == \"bin\") | .name' 2>/dev/null"
              if handle then
                for line in handle:lines() do
                  if line and line ~= "" then table.insert(binaries, line) end
                end
                handle:close()
              end
              return binaries
            end

            local examples = get_cargo_examples()
            local binaries = get_cargo_binaries()

            -- Enhanced command list with categories (removed dependency management)
            local commands = {
              -- Basic Commands
              { "🔍 Check" .. workspace_suffix, "cargo check" .. workspace_suffix, "basic" },
              { "🔨 Build" .. workspace_suffix, "cargo build" .. workspace_suffix, "basic" },
              { "🔨 Build Release" .. workspace_suffix, "cargo build --release" .. workspace_suffix, "basic" },
              { "🧪 Test" .. workspace_suffix, "cargo test" .. workspace_suffix, "basic" },
              { "🧪 Test Release", "cargo test --release" .. workspace_suffix, "basic" },
              { "📎 Clippy" .. workspace_suffix, "cargo clippy" .. workspace_suffix .. " -- -D warnings", "basic" },
              { "🧹 Clean" .. workspace_suffix, "cargo clean" .. workspace_suffix, "basic" },

              -- Advanced Build Options
              { "🔍 Check Lib Only", "cargo check --lib" .. workspace_suffix, "advanced" },
              { "🔨 Build Lib Only", "cargo build --lib" .. workspace_suffix, "advanced" },

              -- Documentation and Formatting
              { "📚 Generate Docs", "cargo doc --open" .. workspace_suffix, "docs" },
              { "📚 Generate Docs (No Deps)", "cargo doc --no-deps --open" .. workspace_suffix, "docs" },
              { "🎨 Format Code", "cargo fmt" .. workspace_suffix, "docs" },
              { "🎨 Format Check", "cargo fmt --check" .. workspace_suffix, "docs" },

              -- Benchmarks and Performance
              { "⚡ Bench" .. workspace_suffix, "cargo bench" .. workspace_suffix, "perf" },

              -- Utility Commands
              { "🔍 Expand Macros", "cargo expand", "utility" },
              { "📋 Show Config", "cargo config get", "utility" },

              -- Publishing
              { "📦 Package", "cargo package", "publish" },
              { "🔍 Package List", "cargo package --list", "publish" },
              { "📤 Publish Dry Run", "cargo publish --dry-run", "publish" },
            }

            -- Add example commands
            for _, example in ipairs(examples) do
              table.insert(commands, { "📖 Run Example: " .. example, "cargo run --example " .. example, "examples" })
              table.insert(
                commands,
                { "🔨 Build Example: " .. example, "cargo build --example " .. example, "examples" }
              )
            end

            -- Add binary run commands
            for _, binary in ipairs(binaries) do
              table.insert(commands, { "▶️  Run Binary: " .. binary, "cargo run --bin " .. binary, "binaries" })
              table.insert(
                commands,
                { "▶️  Run Binary (Release): " .. binary, "cargo run --release --bin " .. binary, "binaries" }
              )
            end

            -- Custom command input option
            table.insert(commands, { "✏️  Custom Command...", "custom", "custom" })

            -- Terminal direction is fixed to horizontal
            vim.ui.select(commands, {
              prompt = "🦀 Select cargo command:",
              format_item = function(item)
                local category_icons = {
                  basic = "⚙️ ",
                  advanced = "🔧 ",
                  docs = "📚 ",
                  perf = "⚡ ",
                  utility = "🛠️  ",
                  publish = "📤 ",
                  examples = "📖 ",
                  binaries = "▶️ ",
                  custom = "✏️ ",
                }
                local icon = category_icons[item[3]] or "• "
                return icon .. item[1]
              end,
            }, function(choice)
              if choice then
                local command_to_run = choice[2]

                -- Handle custom command
                if command_to_run == "custom" then
                  vim.ui.input({
                    prompt = "Enter custom cargo command: ",
                    default = "cargo ",
                  }, function(custom_cmd)
                    if custom_cmd and custom_cmd ~= "" then
                      command_to_run = custom_cmd
                    else
                      return
                    end

                    -- Execute the custom command using Terminal:new() for more reliable execution
                    local Terminal = require("toggleterm.terminal").Terminal

                    local term_opts = {
                      cmd = custom_cmd,
                      direction = "tab",
                      close_on_exit = false,
                      size = 15,
                      on_open = function(term) vim.cmd "startinsert!" end,
                    }

                    -- Show notification
                    vim.notify("Running: " .. custom_cmd, vim.log.levels.INFO)

                    -- Create and toggle the terminal
                    local terminal = Terminal:new(term_opts)
                    terminal:toggle()
                  end)
                else
                  -- Execute the selected command using Terminal:new() for more reliable execution
                  local Terminal = require("toggleterm.terminal").Terminal

                  local term_opts = {
                    cmd = command_to_run,
                    direction = "tab",
                    close_on_exit = false,
                    size = 15,
                    on_open = function(term) vim.cmd "startinsert!" end,
                  }

                  -- Show notification with command being executed
                  vim.notify("Running: " .. command_to_run, vim.log.levels.INFO)

                  -- Create and toggle the terminal
                  local terminal = Terminal:new(term_opts)
                  terminal:toggle()
                end
              end
            end)
          end,
          desc = "Cargo command menu",
        }, -- Smart workspace file finder
        ["<leader>fwf"] = {
          function()
            local workspace_utils = require "workspace_utils"
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace then
              -- Fallback to regular file search
              require("telescope.builtin").find_files()
              return
            end

            -- Build search directories for all workspace members
            local search_dirs = { workspace_info.root }
            for _, member in ipairs(workspace_info.members) do
              table.insert(search_dirs, workspace_info.root .. "/" .. member)
            end

            require("telescope.builtin").find_files {
              prompt_title = "Workspace Files",
              search_dirs = search_dirs,
              find_command = { "rg", "--files", "--type", "rust", "--hidden", "--glob", "!target/**" },
            }
          end,
          desc = "Find files in workspace",
        },

        -- Live grep within workspace
        ["<leader>fwg"] = {
          function()
            local workspace_utils = require "workspace_utils"
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace then
              -- Fallback to regular live grep
              require("telescope.builtin").live_grep()
              return
            end

            -- Build search directories for all workspace members
            local search_dirs = {}
            for _, member in ipairs(workspace_info.members) do
              table.insert(search_dirs, workspace_info.root .. "/" .. member .. "/src")
            end

            require("telescope.builtin").live_grep {
              prompt_title = "Live Grep in Workspace",
              search_dirs = search_dirs,
              additional_args = { "--type", "rust", "--hidden", "--glob", "!target/**" },
            }
          end,
          desc = "Live grep in workspace",
        },

        -- Find Rust files specifically
        ["<leader>fwr"] = {
          function()
            local workspace_utils = require "workspace_utils"
            local workspace_info = workspace_utils.get_workspace_info()

            local search_dirs = { vim.fn.getcwd() }
            if workspace_info.is_workspace then
              search_dirs = {}
              for _, member in ipairs(workspace_info.members) do
                table.insert(search_dirs, workspace_info.root .. "/" .. member)
              end
            end

            require("telescope.builtin").find_files {
              prompt_title = "Rust Files in Workspace",
              search_dirs = search_dirs,
              find_command = { "rg", "--files", "--type", "rust", "--glob", "!target/**" },
            }
          end,
          desc = "Find Rust files in workspace",
        },

        -- Find test files
        ["<leader>fwc"] = {
  function()
    local workspace_utils = require "workspace_utils"
    local workspace_info = workspace_utils.get_workspace_info()
    local search_dirs = { vim.fn.getcwd() }
    if workspace_info.is_workspace then
      search_dirs = { workspace_info.root }
      for _, member in ipairs(workspace_info.members) do
        table.insert(search_dirs, workspace_info.root .. "/" .. member)
      end
    end

    -- Detect project type and define config files
    local function get_config_patterns()
      local patterns = {}
      local project_types = {}

      -- Check for different project types in search directories
      for _, dir in ipairs(search_dirs) do
        -- Rust projects
        if vim.fn.filereadable(dir .. "/Cargo.toml") == 1 then
          table.insert(patterns, { name = "Cargo.toml", pattern = "Cargo.toml" })
          table.insert(project_types, "Rust")
        end
        
        -- Node.js projects
        if vim.fn.filereadable(dir .. "/package.json") == 1 then
          table.insert(patterns, { name = "package.json", pattern = "package.json" })
          table.insert(project_types, "Node.js")
        end
        
        -- Python projects
        if vim.fn.filereadable(dir .. "/pyproject.toml") == 1 then
          table.insert(patterns, { name = "pyproject.toml", pattern = "pyproject.toml" })
          table.insert(project_types, "Python")
        end
        if vim.fn.filereadable(dir .. "/setup.py") == 1 then
          table.insert(patterns, { name = "setup.py", pattern = "setup.py" })
          table.insert(project_types, "Python")
        end
        if vim.fn.filereadable(dir .. "/requirements.txt") == 1 then
          table.insert(patterns, { name = "requirements.txt", pattern = "requirements.txt" })
          table.insert(project_types, "Python")
        end
        
        -- Go projects
        if vim.fn.filereadable(dir .. "/go.mod") == 1 then
          table.insert(patterns, { name = "go.mod", pattern = "go.mod" })
          table.insert(project_types, "Go")
        end
        
        -- C/C++ projects
        if vim.fn.filereadable(dir .. "/CMakeLists.txt") == 1 then
          table.insert(patterns, { name = "CMakeLists.txt", pattern = "CMakeLists.txt" })
          table.insert(project_types, "C/C++")
        end
        if vim.fn.filereadable(dir .. "/Makefile") == 1 then
          table.insert(patterns, { name = "Makefile", pattern = "Makefile" })
          table.insert(project_types, "C/C++")
        end
        
        -- Java projects
        if vim.fn.filereadable(dir .. "/pom.xml") == 1 then
          table.insert(patterns, { name = "pom.xml", pattern = "pom.xml" })
          table.insert(project_types, "Java/Maven")
        end
        if vim.fn.filereadable(dir .. "/build.gradle") == 1 or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1 then
          table.insert(patterns, { name = "build.gradle*", pattern = "build.gradle*" })
          table.insert(project_types, "Java/Gradle")
        end
        
        -- Docker
        if vim.fn.filereadable(dir .. "/Dockerfile") == 1 then
          table.insert(patterns, { name = "Dockerfile", pattern = "Dockerfile*" })
          table.insert(project_types, "Docker")
        end
        if vim.fn.filereadable(dir .. "/docker-compose.yml") == 1 or vim.fn.filereadable(dir .. "/docker-compose.yaml") == 1 then
          table.insert(patterns, { name = "docker-compose.y*ml", pattern = "docker-compose.y*ml" })
          table.insert(project_types, "Docker")
        end
        
        -- Generic config files
        if vim.fn.filereadable(dir .. "/.env") == 1 then
          table.insert(patterns, { name = ".env*", pattern = ".env*" })
        end
      end

      -- Remove duplicates
      local seen = {}
      local unique_patterns = {}
      for _, pattern in ipairs(patterns) do
        if not seen[pattern.name] then
          seen[pattern.name] = true
          table.insert(unique_patterns, pattern)
        end
      end

      return unique_patterns, project_types
    end

    local config_patterns, detected_types = get_config_patterns()
    
    if #config_patterns == 0 then
      -- Fallback: search for common config files
      config_patterns = {
        { name = "All Config Files", pattern = "*" }
      }
    end

    -- Add option to search all config files
    table.insert(config_patterns, 1, { name = "🔍 All Config Files", pattern = "*" })

    local project_type_str = #detected_types > 0 and " (" .. table.concat(detected_types, ", ") .. ")" or ""

    vim.ui.select(config_patterns, {
      prompt = "Select config files to find" .. project_type_str .. ":",
      format_item = function(item) return item.name end,
    }, function(choice)
      if choice then
        local find_command
        local prompt_title
        
        if choice.pattern == "*" then
          -- Search for all common config files
          find_command = { 
            "find", ".", 
            "\\(", 
              "-name", "*.toml", "-o",
              "-name", "*.json", "-o", 
              "-name", "*.yml", "-o", 
              "-name", "*.yaml", "-o",
              "-name", "Makefile", "-o",
              "-name", "Dockerfile*", "-o",
              "-name", ".env*", "-o",
              "-name", "*.lock", "-o",
              "-name", "*.mod", "-o",
              "-name", "*.gradle*", "-o",
              "-name", "*.xml", 
            "\\)",
            "-type", "f", 
            "!", "-path", "*/target/*",
            "!", "-path", "*/node_modules/*",
            "!", "-path", "*/.git/*",
            "!", "-path", "*/build/*"
          }
          prompt_title = "All Config Files in Workspace"
        else
          find_command = { 
            "find", ".", "-name", choice.pattern, "-type", "f", 
            "!", "-path", "*/target/*",
            "!", "-path", "*/node_modules/*", 
            "!", "-path", "*/.git/*",
            "!", "-path", "*/build/*"
          }
          prompt_title = choice.name .. " Files in Workspace"
        end

        require("telescope.builtin").find_files {
          prompt_title = prompt_title,
          search_dirs = search_dirs,
          find_command = find_command,
        }
      end
    end)
  end,
  desc = "Find config files in workspace",
},

        -- Quick workspace overview with file counts
        ["<leader>fwi"] = {
          function()
            local workspace_utils = require "workspace_utils"
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace then
              vim.notify("Not in a workspace", vim.log.levels.INFO)
              return
            end

            local lines = { "🦀 Workspace File Overview", "" }

            for _, member in ipairs(workspace_info.members) do
              local member_path = workspace_info.root .. "/" .. member
              local src_path = member_path .. "/src"

              -- Count Rust files
              local rust_count = 0
              if vim.fn.isdirectory(src_path) == 1 then
                local files = vim.fn.globpath(src_path, "**/*.rs", false, true)
                rust_count = #files
              end

              table.insert(lines, string.format("📦 %s: %d Rust files", member, rust_count))
            end

            -- Display in notification or floating window
            local message = table.concat(lines, "\n")
            vim.notify(message, vim.log.levels.INFO)
          end,
          desc = "Show workspace file overview",
        },

        -- Search within current workspace member only
        ["<leader>fwl"] = {
          function()
            local workspace_utils = require "workspace_utils"
            local workspace_info = workspace_utils.get_workspace_info()

            if not workspace_info.is_workspace then
              -- Search in current directory if not in workspace
              require("telescope.builtin").find_files { search_dirs = { vim.fn.getcwd() } }
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
              require("telescope.builtin").find_files {
                prompt_title = "Files in " .. current_member,
                search_dirs = { member_path },
                find_command = { "rg", "--files", "--type", "rust", "--glob", "!target/**" },
              }
            else
              vim.notify("Not currently in a workspace member", vim.log.levels.WARN)
            end
          end,
          desc = "Find files in current workspace member",
        }, -- ======= REMAINING TELESCOPE MAPPINGS =======

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

        -- ======= BUILD/RUN MAPPINGS with workspace awareness =======

        -- Global Build/Run mappings with workspace awareness
        ["<leader>br"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              local workspace_info = workspace_utils.get_workspace_info()

              if workspace_info.is_workspace then
                -- In workspace, ask which package to run
                local package_name = vim.fn.input "Package name (or Enter for default): "
                if package_name ~= "" then
                  vim.cmd("!cargo run -p " .. package_name)
                else
                  vim.cmd "!cargo run"
                end
              else
                vim.cmd "!cargo run"
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
              local workspace_info = workspace_utils.get_workspace_info()

              if workspace_info.is_workspace then
                vim.cmd "!cargo build --workspace"
              else
                vim.cmd "!cargo build"
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
              local workspace_info = workspace_utils.get_workspace_info()

              if workspace_info.is_workspace then
                vim.cmd "!cargo clean --workspace"
              else
                vim.cmd "!cargo clean"
              end
            else
              vim.notify("No clean command configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Clean project",
        },

        -- ======= TEST MAPPINGS =======

        -- Global Test mappings (work for all languages)
        ["<leader>tr"] = {
          function()
            local ft = vim.bo.filetype
            if ft == "rust" then
              local workspace_info = workspace_utils.get_workspace_info()

              if workspace_info.is_workspace then
                vim.cmd "!cargo test --workspace"
              else
                vim.cmd "!cargo test"
              end
            else
              vim.notify("No test runner configured for " .. ft, vim.log.levels.WARN)
            end
          end,
          desc = "Run tests",
        },

        -- ======= ADDITIONAL UTILITY MAPPINGS =======

        -- Quick save
        ["<leader>w"] = {
          function() vim.cmd "write" end,
          desc = "Save file",
        },

        -- Clear search highlighting
        ["<leader>nh"] = {
          function() vim.cmd "nohlsearch" end,
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
