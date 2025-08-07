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

-- Suggested location: lua/core/mappings.lua or a new file in lua/plugins/
["<leader>ms"] = {
  function()
    -- 1. Prerequisite Checks
    local has_toggleterm, toggleterm = pcall(require, "toggleterm")
    if not has_toggleterm then
      vim.notify("toggleterm.nvim is not installed.", vim.log.levels.ERROR)
      return
    end

    if vim.fn.executable("psql") == 0 then
      vim.notify("`psql` command not found in your PATH.", vim.log.levels.ERROR)
      return
    end

    -- 2. Function to parse .env for DATABASE_URL
    local function get_database_url()
      local file = io.open(".env", "r")
      if not file then return nil end

      for line in file:lines() do
        local url = line:match("^%s*DATABASE_URL%s*=%s*['\"]?([^'\"]+)['\"]?%s*$")
        if url then
          file:close()
          return url
        end
      end

      file:close()
      return nil
    end

    local db_url = get_database_url()
    if not db_url then
      vim.notify("No .env file found or DATABASE_URL is missing.", vim.log.levels.WARN)
      return
    end

    -- 3. Function to parse the current buffer for SQL queries
    local function find_queries_in_buffer()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, "\n")
      local queries = {}

      -- Split by semicolon and clean up the results
      for query in string.gmatch(content, "([^;]+)") do
        -- Trim whitespace
        query = query:match("^%s*(.-)%s*$")
        if query and #query > 0 then
          table.insert(queries, query)
        end
      end
      return queries
    end

    -- 4. Function to execute a command in ToggleTerm
    local function run_command(cmd_string, title)
      vim.notify("🚀 Running: " .. (title or cmd_string), vim.log.levels.INFO)
      local Terminal = require("toggleterm.terminal").Terminal
      local term = Terminal:new({
        cmd = cmd_string,
        direction = "float",
        close_on_exit = false,
        on_open = function(_) vim.cmd("startinsert!") end,
      })
      term:toggle()
    end

    -- 5. Build and show the menu
    local queries = find_queries_in_buffer()
    if #queries == 0 then
      vim.notify("No runnable SQL queries found in the current buffer.", vim.log.levels.WARN)
      return
    end

    local commands = {}
    for i, query_text in ipairs(queries) do
      -- Create a short preview for the menu
      local preview = query_text:gsub("[\r\n\t]+", " "):gsub("^%s*", "")
      if #preview > 70 then
        preview = preview:sub(1, 67) .. "..."
      end
      table.insert(commands, { display = preview, query = query_text })
    end

    vim.ui.select(commands, {
      prompt = "⚡ Select a query to run:",
      format_item = function(item) return item.display end,
    }, function(choice)
      if not choice then return end

      local psql_base_cmd = 'source .env && psql "' .. db_url .. '"'
      local query_to_run = choice.query
      
      -- Use the -c flag to run a single command string
      local final_cmd = psql_base_cmd .. " -c " .. vim.fn.shellescape(query_to_run)
      run_command(final_cmd, "Run Selected Query")
    end)
  end,
  desc = "PostgreSQL Query Picker",
},
        -- ======= TERMINAL INTEGRATION =======
        -- Node menu
["<leader>mn"] = {
  function()
    -- Ensure toggleterm is loaded and available
    local has_toggleterm, toggleterm = pcall(require, "toggleterm")
    if not has_toggleterm then
      vim.notify("toggleterm.nvim is not installed or configured.", vim.log.levels.ERROR)
      return
    end

    -- Check if package.json exists
    local function has_package_json()
      local file = io.open("package.json", "r")
      if file then
        file:close()
        return true
      end
      return false
    end

    if not has_package_json() then
      vim.notify("No package.json found in current directory.", vim.log.levels.WARN)
      return
    end

    -- Parse package.json to detect project type and available scripts
    local function get_project_info()
      local file = io.open("package.json", "r")
      if not file then return nil end
      
      local content = file:read("*a")
      file:close()
      
      local ok, package_data = pcall(vim.fn.json_decode, content)
      if not ok or not package_data then return nil end
      
      return package_data
    end

    -- Detect package manager
    local function detect_package_manager()
      -- Check for lock files to determine package manager
      local yarn_lock = io.open("yarn.lock", "r")
      local pnpm_lock = io.open("pnpm-lock.yaml", "r")
      local bun_lock = io.open("bun.lockb", "r")
      
      if bun_lock then
        bun_lock:close()
        return "bun"
      elseif pnpm_lock then
        pnpm_lock:close()
        return "pnpm"
      elseif yarn_lock then
        yarn_lock:close()
        return "yarn"
      else
        return "npm"
      end
    end

    -- Detect project type from dependencies
    local function detect_project_type(package_data)
      local deps = {}
      if package_data.dependencies then
        for dep, _ in pairs(package_data.dependencies) do
          deps[dep] = true
        end
      end
      if package_data.devDependencies then
        for dep, _ in pairs(package_data.devDependencies) do
          deps[dep] = true
        end
      end

      local types = {}
      
      -- React
      if deps.react or deps["@types/react"] then
        table.insert(types, "React")
      end
      
      -- Next.js
      if deps.next then
        table.insert(types, "Next.js")
      end
      
      -- Vue
      if deps.vue or deps["@vue/cli-service"] then
        table.insert(types, "Vue.js")
      end
      
      -- Angular
      if deps["@angular/core"] then
        table.insert(types, "Angular")
      end
      
      -- Svelte
      if deps.svelte then
        table.insert(types, "Svelte")
      end
      
      -- Express
      if deps.express then
        table.insert(types, "Express")
      end
      
      -- Fastify
      if deps.fastify then
        table.insert(types, "Fastify")
      end
      
      -- Electron
      if deps.electron then
        table.insert(types, "Electron")
      end
      
      -- TypeScript
      if deps.typescript or deps["@types/node"] then
        table.insert(types, "TypeScript")
      end
      
      -- Testing frameworks
      if deps.jest then
        table.insert(types, "Jest")
      elseif deps.vitest then
        table.insert(types, "Vitest")
      elseif deps.mocha then
        table.insert(types, "Mocha")
      end
      
      -- Bundlers
      if deps.webpack then
        table.insert(types, "Webpack")
      elseif deps.vite then
        table.insert(types, "Vite")
      elseif deps.parcel then
        table.insert(types, "Parcel")
      end

      return types
    end

    local package_data = get_project_info()
    if not package_data then
      vim.notify("Failed to parse package.json", vim.log.levels.ERROR)
      return
    end

    local package_manager = detect_package_manager()
    local project_types = detect_project_type(package_data)
    local scripts = package_data.scripts or {}

    -- Build command with package manager
    local function build_command(cmd)
      return package_manager .. " " .. cmd
    end

    -- Build run command based on package manager
    local function build_run_command(script)
      if package_manager == "npm" then
        return "npm run " .. script
      elseif package_manager == "yarn" then
        return "yarn run " .. script
      elseif package_manager == "pnpm" then
        return "pnpm run " .. script
      elseif package_manager == "bun" then
        return "bun run " .. script
      else
        return package_manager .. " run " .. script
      end
    end

    -- Enhanced command list
    local commands = {
      -- Package Management
      { "📦 Install Dependencies", build_command("install"), "pkg" },
      { "🔄 Update Dependencies", build_command("update"), "pkg" },
    }

    -- Add package manager specific commands
    if package_manager == "npm" then
      table.insert(commands, { "📋 List Dependencies", "npm list", "pkg" })
      table.insert(commands, { "🔍 Outdated Packages", "npm outdated", "pkg" })
    elseif package_manager == "yarn" then
      table.insert(commands, { "📋 List Dependencies", "yarn list", "pkg" })
      table.insert(commands, { "🔍 Outdated Packages", "yarn outdated", "pkg" })
      table.insert(commands, { "🧹 Clean Cache", "yarn cache clean", "pkg" })
    elseif package_manager == "pnpm" then
      table.insert(commands, { "📋 List Dependencies", "pnpm list", "pkg" })
      table.insert(commands, { "🔍 Outdated Packages", "pnpm outdated", "pkg" })
      table.insert(commands, { "🧹 Store Prune", "pnpm store prune", "pkg" })
    elseif package_manager == "bun" then
      table.insert(commands, { "📋 List Dependencies", "bun pm ls", "pkg" })
      table.insert(commands, { "🧹 Clean Cache", "bun pm cache rm", "pkg" })
    end

    -- Common development commands
    local common_scripts = {
      { "dev", "🚀 Development Server", "dev" },
      { "start", "▶️  Start", "dev" },
      { "build", "🔨 Build", "build" },
      { "test", "🧪 Test", "test" },
      { "test:watch", "👁️  Test Watch", "test" },
      { "test:coverage", "📊 Test Coverage", "test" },
      { "lint", "📎 Lint", "quality" },
      { "lint:fix", "🔧 Lint Fix", "quality" },
      { "format", "🎨 Format", "quality" },
      { "type-check", "🔍 Type Check", "quality" },
      { "preview", "👀 Preview", "dev" },
      { "serve", "🌐 Serve", "dev" },
    }

    -- Get all scripts from package.json and categorize them
    local function categorize_script(script_name, script_command)
      -- Check script name patterns
      if script_name:match("^dev") or script_name == "start" or script_name:match("serve") then
        return "dev", "🚀"
      elseif script_name:match("build") or script_name:match("compile") then
        return "build", "🔨"
      elseif script_name:match("test") then
        return "test", "🧪"
      elseif script_name:match("lint") or script_name:match("format") or script_name:match("prettier") or script_name:match("eslint") then
        return "quality", "✨"
      elseif script_name:match("type") and script_name:match("check") then
        return "quality", "🔍"
      elseif script_name:match("preview") or script_name:match("storybook") then
        return "preview", "👀"
      elseif script_name:match("deploy") or script_name:match("publish") then
        return "deploy", "🚀"
      else
        return "script", "📜"
      end
    end

    -- Add all scripts from package.json
    local script_names = {}
    for script_name, _ in pairs(scripts) do
      table.insert(script_names, script_name)
    end
    table.sort(script_names)

    for _, script_name in ipairs(script_names) do
      local script_command = scripts[script_name]
      local category, icon = categorize_script(script_name, script_command)
      
      -- Create display name with script preview
      local display_name = string.format("%s %s", icon, script_name)
      if script_command and #script_command > 0 then
        local preview = script_command
        if #preview > 50 then
          preview = preview:sub(1, 47) .. "..."
        end
        display_name = display_name .. " → " .. preview
      end
      
      table.insert(commands, { display_name, build_run_command(script_name), category })
    end

    -- TypeScript specific commands
    if package_data.devDependencies and package_data.devDependencies.typescript then
      table.insert(commands, { "🔍 TypeScript Check", "npx tsc --noEmit", "quality" })
      table.insert(commands, { "👁️  TypeScript Watch", "npx tsc --watch", "quality" })
    end

    -- Framework specific commands
    for _, project_type in ipairs(project_types) do
      if project_type == "Next.js" then
        table.insert(commands, { "🚀 Next.js Analyze", build_run_command("analyze"), "framework" })
      elseif project_type == "React" then
        table.insert(commands, { "⚛️  React DevTools", "echo 'Install React DevTools browser extension'", "framework" })
      elseif project_type == "Vue.js" then
        table.insert(commands, { "💚 Vue DevTools", "echo 'Install Vue DevTools browser extension'", "framework" })
      end
    end

    -- Development utilities
    table.insert(commands, { "🔍 Node Version", "node --version", "utility" })
    table.insert(commands, { "📋 NPM Version", package_manager .. " --version", "utility" })
    table.insert(commands, { "📊 Bundle Analyzer", "npx webpack-bundle-analyzer", "utility" })
    table.insert(commands, { "🔍 Dependency Tree", build_command("ls"), "utility" })

    -- Custom command input option
    table.insert(commands, { "✏️  Custom Command...", "custom", "custom" })

    local project_info = ""
    if #project_types > 0 then
      project_info = " (" .. table.concat(project_types, ", ") .. ")"
    end

    vim.ui.select(commands, {
      prompt = "📦 Select " .. package_manager .. " command" .. project_info .. ":",
      format_item = function(item)
        local category_icons = {
          pkg = "📦 ",
          dev = "🚀 ",
          build = "🔨 ",
          test = "🧪 ",
          quality = "✨ ",
          preview = "👀 ",
          deploy = "🚀 ",
          script = "📜 ",
          framework = "🎯 ",
          utility = "🛠️  ",
          custom = "✏️ ",
        }
        -- Don't add icon if item[1] already starts with an emoji
        if item[1]:match("^[%z\1-\127]") then
          return item[1]  -- Item already has icon
        else
          local icon = category_icons[item[3]] or "• "
          return icon .. item[1]
        end
      end,
    }, function(choice)
      if choice then
        local command_to_run = choice[2]

        -- Handle custom command
        if command_to_run == "custom" then
          vim.ui.input({
            prompt = "Enter custom " .. package_manager .. " command: ",
            default = package_manager .. " ",
          }, function(custom_cmd)
            if custom_cmd and custom_cmd ~= "" then
              command_to_run = custom_cmd
            else
              return
            end

            -- Execute the custom command
            local Terminal = require("toggleterm.terminal").Terminal

            local term_opts = {
              cmd = custom_cmd,
              direction = "tab",
              close_on_exit = false,
              size = 15,
              on_open = function(term) vim.cmd("startinsert!") end,
            }

            -- Show notification
            vim.notify("Running: " .. custom_cmd, vim.log.levels.INFO)

            -- Create and toggle the terminal
            local terminal = Terminal:new(term_opts)
            terminal:toggle()
          end)
        else
          -- Execute the selected command
          local Terminal = require("toggleterm.terminal").Terminal

          local term_opts = {
            cmd = command_to_run,
            direction = "tab",
            close_on_exit = false,
            size = 15,
            on_open = function(term) vim.cmd("startinsert!") end,
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
  desc = "Node.js/JavaScript command menu",
},

["<leader>mm"] = {
  function()
    -- Ensure toggleterm is loaded and available
    local has_toggleterm, toggleterm = pcall(require, "toggleterm")
    if not has_toggleterm then
      vim.notify("toggleterm.nvim is not installed or configured.", vim.log.levels.ERROR)
      return
    end

    -- Find the project root by looking for a .git directory
    local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
      root = vim.fn.getcwd()
    end

    -- Find the Makefile
    local makefile_path = vim.fn.filereadable(root .. "/Makefile") == 1 and (root .. "/Makefile")
      or (vim.fn.filereadable(root .. "/makefile") == 1 and (root .. "/makefile") or nil)

    if not makefile_path then
      vim.notify("No Makefile found in the project root.", vim.log.levels.WARN)
      return
    end

    -- Parse targets and their comments from the Makefile
    local function get_make_targets()
      local targets = {}
      local file = io.open(makefile_path, "r")
      if not file then return targets end

      for line in file:lines() do
        -- Match targets, ignoring .PHONY and comments, and capture the comment after '##'
        local target, comment = line:match("^([a-zA-Z0-9_%-]+):.*%s*##%s*(.*)")
        
        -- Fallback for targets without a '##' comment
        if not target then
          target = line:match("^([a-zA-Z0-9_%-]+):")
        end

        if target and not target:find("^%.") then
          table.insert(targets, { name = target, comment = comment or "" })
        end
      end
      file:close()
      return targets
    end

    local targets = get_make_targets()
    if #targets == 0 then
      vim.notify("No targets found in the Makefile.", vim.log.levels.INFO)
      return
    end

    vim.ui.select(targets, {
      prompt = "🛠️  Select make command:",
      format_item = function(item)
        if item.comment and item.comment ~= "" then
          return string.format("%-25s → %s", item.name, item.comment)
        else
          return item.name
        end
      end,
    }, function(choice)
      if choice then
        local command_to_run = "make " .. choice.name
        local Terminal = require("toggleterm.terminal").Terminal

        local term = Terminal:new({
          cmd = command_to_run,
          direction = "tab",
          close_on_exit = false,
          on_open = function(t) vim.cmd("startinsert!") end,
        })

        vim.notify("Running: " .. command_to_run, vim.log.levels.INFO)
        term:toggle()
      end
    end)
  end,
  desc = "Make command menu",
},

        -- Interactive cargo command menu
["<leader>mc"] = {
          function()
            -- Ensure toggleterm is loaded and available
            local has_toggleterm, toggleterm = pcall(require, "toggleterm")
            if not has_toggleterm then
              vim.notify("toggleterm.nvim is not installed or configured.", vim.log.levels.ERROR)
              return
            end

            -- Better workspace detection
            local function is_workspace()
              local handle = io.popen("cargo metadata --format-version 1 --no-deps 2>/dev/null")
              if not handle then return false end
              
              local output = handle:read("*a")
              handle:close()
              
              if not output or output == "" then return false end
              
              -- Parse JSON to check if we have multiple packages
              local ok, result = pcall(vim.fn.json_decode, output)
              if not ok or not result or not result.packages then return false end
              
              return #result.packages > 1
            end

            local is_ws = is_workspace()
            local workspace_flag = is_ws and " --workspace" or ""

            -- Get available examples
            local function get_cargo_examples()
              local examples = {}
              local handle = io.popen("ls examples/*.rs 2>/dev/null | xargs -n1 basename -s .rs 2>/dev/null")
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
              local handle = io.popen("cargo metadata --format-version 1 --no-deps 2>/dev/null | jq -r '.packages[].targets[] | select(.kind[] == \"bin\") | .name' 2>/dev/null")
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

            -- Build commands with proper workspace handling
            local function build_command(base_cmd, workspace_flag_type)
              if not is_ws then
                return base_cmd
              end
              
              if workspace_flag_type == "workspace" then
                return base_cmd .. " --workspace"
              elseif workspace_flag_type == "all" then
                return base_cmd .. " --all"
              else
                return base_cmd
              end
            end

            -- Enhanced command list with proper workspace handling
            local commands = {
              -- Basic Commands
              { "🔍 Check" .. (is_ws and " (workspace)" or ""), build_command("cargo check", "workspace"), "basic" },
              { "🔨 Build" .. (is_ws and " (workspace)" or ""), build_command("cargo build", "workspace"), "basic" },
              { "🔨 Build Release" .. (is_ws and " (workspace)" or ""), build_command("cargo build --release", "workspace"), "basic" },
              { "🧪 Test" .. (is_ws and " (workspace)" or ""), build_command("cargo test", "workspace"), "basic" },
              { "🧪 Test Release" .. (is_ws and " (workspace)" or ""), build_command("cargo test --release", "workspace"), "basic" },
              { "📎 Clippy" .. (is_ws and " (workspace)" or ""), build_command("cargo clippy", "workspace") .. " -- -D warnings", "basic" },
              { "🧹 Clean" .. (is_ws and " (workspace)" or ""), build_command("cargo clean", "workspace"), "basic" },

              -- Advanced Build Options
              { "🔍 Check Lib Only", build_command("cargo check --lib", "workspace"), "advanced" },
              { "🔨 Build Lib Only", build_command("cargo build --lib", "workspace"), "advanced" },

              -- Documentation and Formatting
              { "📚 Generate Docs", build_command("cargo doc --open", "workspace"), "docs" },
              { "📚 Generate Docs (No Deps)", build_command("cargo doc --no-deps --open", "workspace"), "docs" },
              { "🎨 Format Code", build_command("cargo fmt", "all"), "docs" },
              { "🎨 Format Check", build_command("cargo fmt --check", "all"), "docs" },

              -- Benchmarks and Performance
              { "⚡ Bench", build_command("cargo bench", "workspace"), "perf" },

              -- Utility Commands - these don't typically support workspace flags
              { "🔍 Expand Macros", "cargo expand", "utility" },
              { "📋 Show Config", "cargo config get", "utility" },

              -- Publishing (usually don't need workspace flag)
              { "📦 Package", "cargo package", "publish" },
              { "🔍 Package List", "cargo package --list", "publish" },
              { "📤 Publish Dry Run", "cargo publish --dry-run", "publish" },
            }

            -- Add workspace-specific commands if in workspace
            if is_ws then
              table.insert(commands, { "🔍 Check All Packages", "cargo check --workspace", "workspace" })
              table.insert(commands, { "🧪 Test All Packages", "cargo test --workspace", "workspace" })
              table.insert(commands, { "📎 Clippy All Packages", "cargo clippy --workspace -- -D warnings", "workspace" })
              table.insert(commands, { "🎨 Format All Packages", "cargo fmt --all", "workspace" })
            end

            -- Add example commands
            for _, example in ipairs(examples) do
              table.insert(commands, { "📖 Run Example: " .. example, "cargo run --example " .. example, "examples" })
              table.insert(commands, { "🔨 Build Example: " .. example, "cargo build --example " .. example, "examples" })
            end

            -- Add binary run commands
            for _, binary in ipairs(binaries) do
              table.insert(commands, { "▶️  Run Binary: " .. binary, "cargo run --bin " .. binary, "binaries" })
              table.insert(commands, { "▶️  Run Binary (Release): " .. binary, "cargo run --release --bin " .. binary, "binaries" })
            end

            -- Custom command input option
            table.insert(commands, { "✏️  Custom Command...", "custom", "custom" })

            -- Terminal direction is fixed to horizontal
            vim.ui.select(commands, {
              prompt = "🦀 Select cargo command" .. (is_ws and " (workspace detected)" or "") .. ":",
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
                  workspace = "🏢 ",
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
                      on_open = function(term) vim.cmd("startinsert!") end,
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
                    on_open = function(term) vim.cmd("startinsert!") end,
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
        },
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
