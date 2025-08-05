-- lua/plugins/dadbod.lua
-- A unified, feature-rich vim-dadbod configuration

return {
  {
    'tpope/vim-dadbod',
    lazy = true,
    cmd = { 'DB' },
  },
  {
    'kristijanhusak/vim-dadbod-completion',
    dependencies = { 'tpope/vim-dadbod' },
    ft = { 'sql', 'sqlite', 'psql', 'mysql', 'plsql' },
    lazy = true,
    config = function()
      -- Ensures dadbod is loaded for completion
      if not vim.g.loaded_dadbod then
        vim.cmd('runtime! plugin/dadbod.vim')
      end
    end,
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      'tpope/vim-dadbod',
      'kristijanhusak/vim-dadbod-completion',
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    -- init is run before the plugin loads, perfect for setting global variables
    init = function()
      -- == General UI Settings ==
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_winwidth = 40
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = vim.fn.stdpath('data') .. '/db_ui'

      -- == Database Connections ==
      vim.g.dbs = {
        test_sqlite = 'sqlite:' .. vim.fn.stdpath('data') .. '/local.db',
        -- Add other connections here
        -- local_pg = 'postgresql://user:password@localhost:5432/dbname',
      }

      -- == Nerd Font Icons (from the second file) ==
      vim.g.db_ui_icons = {
        expanded = { db = '▾ 󰆼', buffers = '▾ 󰈙', saved_queries = '▾ 󰆓', schemas = '▾ 󰦺', schema = '▾ 󰦺', tables = '▾ 󰓫', table = '▾ 󰓫' },
        collapsed = { db = '▸ 󰆼', buffers = '▸ 󰈙', saved_queries = '▸ 󰆓', schemas = '▸ 󰦺', schema = '▸ 󰦺', tables = '▸ 󰓫', table = '▸ 󰓫' },
      }

      -- == Enhanced Table Helpers (from the second file) ==
      vim.g.db_ui_table_helpers = {
        postgresql = {
          Count = 'SELECT COUNT(*) FROM "{table}";',
          Columns = [[SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = '{table}' ORDER BY ordinal_position;]],
          Schema = '\\d+ {table}',
          Sample = 'SELECT * FROM "{table}" LIMIT 10;',
          Explain = 'EXPLAIN (ANALYZE, BUFFERS) {last_query}',
          Indexes = [[SELECT indexname, indexdef FROM pg_indexes WHERE tablename = '{table}';]],
          Size = [[SELECT pg_size_pretty(pg_total_relation_size('{table}'::regclass)) as total_size, pg_size_pretty(pg_relation_size('{table}'::regclass)) as table_size;]],
          FK = [[SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS foreign_table, ccu.column_name AS foreign_column FROM information_schema.table_constraints AS tc JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_name = '{table}';]],
        },
        sqlite = {
          Count = 'SELECT COUNT(*) FROM `{table}`;',
          Columns = 'PRAGMA table_info(`{table}`);',
          Schema = '.schema {table}',
          Sample = 'SELECT * FROM `{table}` LIMIT 10;',
          Explain = 'EXPLAIN QUERY PLAN {last_query}',
          FK = 'PRAGMA foreign_key_list(`{table}`);',
          Indexes = 'PRAGMA index_list(`{table}`);',
        },
      }

      -- == Core Key Mappings ==
      vim.keymap.set('n', '<leader>db', '<cmd>DBUIToggle<cr>', { desc = 'Toggle DBUI' })
      vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Find DB buffer' })
      vim.keymap.set('n', '<leader>dr', '<cmd>DBUIRenameBuffer<cr>', { desc = 'Rename DB buffer' })
      vim.keymap.set('n', '<leader>dq', '<cmd>DBUILastQueryInfo<cr>', { desc = 'Last query info' })
    end,
    -- config is run after the plugin loads, for autocommands and more complex logic
    config = function()
      -- Make sure dadbod runtime is loaded
      if not vim.g.loaded_dadbod then
        vim.cmd('runtime! plugin/dadbod.vim')
      end

      -- Assume these modules exist in your 'lua/' directory
      -- These come from the first file's modular design
      local sql_docs = require('sqldocs')
      local templates = require('sqltemplates')

      -- Helper to create a documentation window (from the first file)
      local function show_help_window(title, lines)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

        local width = math.min(90, vim.o.columns - 4)
        local height = math.min(30, #lines + 2, math.floor(vim.o.lines * 0.7))

        local win = vim.api.nvim_open_win(buf, true, {
          relative = 'cursor',
          width = width,
          height = height,
          row = 1,
          col = 0,
          style = 'minimal',
          border = 'rounded',
          title = ' 🐘 SQL: ' .. title .. ' ',
          title_pos = 'center',
        })

        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', { silent = true, nowait = true })
        vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<cr>', { silent = true, nowait = true })
      end

      -- Helper to format documentation (from the first file)
      local function format_sql_help(info)
        local lines = { "📝 **Description:**", "  " .. info.description, "", "💡 **Syntax:**", "  `" .. info.syntax .. "`", "" }
        if #info.examples > 0 then
          table.insert(lines, "🚀 **Examples:**")
          for _, example in ipairs(info.examples) do
            for line in example:gmatch("[^\n]+") do
table.insert(lines, "  ```sql")
table.insert(lines, "  " .. line)
table.insert(lines, "  ```")
            end
          end
        end
        table.insert(lines, "")
        table.insert(lines, "🏷️ **Category:** " .. (info.category or "General"))
        return lines
      end

      -- Custom user command (from the first file)
      vim.api.nvim_create_user_command('PgLocks', function()
        vim.cmd([[DB SELECT l.locktype, l.relation::regclass, l.mode, l.granted, a.usename, a.query, age(now(), a.query_start) AS duration FROM pg_locks l LEFT JOIN pg_stat_activity a ON l.pid = a.pid WHERE NOT l.granted ORDER BY l.relation;]])
      end, { desc = 'Show waiting PostgreSQL locks' })

      -- Autocommand for SQL filetypes
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sql', 'sqlite', 'psql', 'mysql', 'plsql' },
        callback = function(args)
          local bufnr = args.buf
          local opts = { buffer = bufnr, silent = true }

          -- == The "Super-Charged" K Mapping ==
          vim.keymap.set('n', 'K', function()
            local word = vim.fn.expand('<cword>')
            if not word or word == '' then return end

            local upper_word = string.upper(word)
            local line = vim.api.nvim_get_current_line()

            -- 1. Check for keyword documentation (from the first file's logic)
            if sql_docs[upper_word] then
              local doc_info = sql_docs[upper_word]
              local formatted_lines = format_sql_help(doc_info)
              show_help_window(upper_word, formatted_lines)
              return
            end

            -- 2. Check if it's a table name (from the second file's logic)
            -- This regex looks for patterns like FROM table, JOIN table, UPDATE table, etc.
            if word:match('^[a-zA-Z_][a-zA-Z0-9_]*$') and line:match('%f[%s,]' .. word .. '%f[%s;%)]') then
              vim.ui.select({ '📋 Schema', '📊 Sample (10)', '🔢 Count', '🔗 Foreign Keys', '📈 Indexes', '📏 Size' }, {
                prompt = '🐘 Table Actions for: ' .. word,
              }, function(choice)
                if not choice then return end
                local db_type = vim.b.db_ui_database_type or 'postgresql'
                local helper = vim.g.db_ui_table_helpers[db_type]
                if not helper then vim.notify('No helpers for db type: ' .. db_type, vim.log.levels.WARN); return end

                local action_map = {
                  ['📋 Schema'] = helper.Schema,
                  ['📊 Sample (10)'] = helper.Sample,
                  ['🔢 Count'] = helper.Count,
                  ['🔗 Foreign Keys'] = helper.FK,
                  ['📈 Indexes'] = helper.Indexes,
                  ['📏 Size'] = helper.Size,
                }
                if action_map[choice] then
                  vim.cmd('DB ' .. action_map[choice]:gsub('{table}', word))
                end
              end)
              return
            end

            -- 3. Fallback to LSP hover
            vim.lsp.buf.hover()
          end, vim.tbl_extend('force', opts, { desc = 'Smart SQL Help (Docs/Tables/LSP)' }))

          -- == Additional Helper Mappings (from the first file) ==
          -- SQL Templates
          vim.keymap.set('n', '<leader>sq', function()
            vim.ui.select(templates, { prompt = 'Select SQL template:', format_item = function(item) return item.name end }, function(choice)
              if choice then
                local lines = vim.split(choice.template, '\n')
                vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { '' }) -- Add a blank line
                vim.api.nvim_put(lines, 'c', true, true)
              end
            end)
          end, vim.tbl_extend('force', opts, { desc = 'Insert SQL Template' }))

          -- SQL Function Explorer
          vim.keymap.set('n', '<leader>sh', function()
            local categories = { 'aggregate', 'string', 'datetime', 'conditional', 'conversion', 'window', 'math', 'json', 'clause', 'dml', 'ddl', 'operator' }
            vim.ui.select(categories, { prompt = 'Select SQL function category:' }, function(category)
              if category then
                local functions = {}
                for name, info in pairs(sql_docs) do
                  if info.category == category then table.insert(functions, { name = name, info = info }) end
                end
                table.sort(functions, function(a, b) return a.name < b.name end)
                vim.ui.select(functions, { prompt = 'Select function:', format_item = function(item) return item.name end }, function(choice)
                  if choice then show_help_window(choice.name, format_sql_help(choice.info)) end
                end)
              end
            end)
          end, vim.tbl_extend('force', opts, { desc = 'SQL Function Explorer' }))

          -- == Standard Dadbod Mappings ==
          vim.keymap.set({ 'n', 'v' }, '<leader><leader>', '<Plug>(DBUI_ExecuteQuery)', vim.tbl_extend('force', opts, { desc = 'Execute Query' }))
          vim.keymap.set('n', '<leader>S', '<Plug>(DBUI_SaveQuery)', vim.tbl_extend('force', opts, { desc = 'Save Query' }))
          vim.keymap.set('n', '<leader>E', '<Plug>(DBUI_EditBindParameters)', vim.tbl_extend('force', opts, { desc = 'Edit Bind Parameters' }))
          vim.keymap.set('n', '<leader>W', '<Plug>(DBUI_ToggleResultLayout)', vim.tbl_extend('force', opts, { desc = 'Toggle Result Layout' }))

          -- == Buffer Settings ==
          vim.bo[bufnr].omnifunc = 'vim_dadbod_completion#omni'
          vim.bo[bufnr].commentstring = '-- %s'
        end,
      })
    end,
  },
}
