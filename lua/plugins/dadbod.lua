-- lua/plugins/dadbod.lua
-- Enhanced vim-dadbod configuration with PostgreSQL hover documentation

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
      vim.cmd('runtime! plugin/dadbod.vim')
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
    init = function()
      -- Basic UI configuration
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_help = 0
      vim.g.db_ui_winwidth = 40
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = vim.fn.stdpath('data') .. '/db_ui'
      
      -- Database connections
      vim.g.dbs = {
        test_sqlite = 'sqlite:/Users/sethr/dev/outdoor-tranformations/local.db',
        -- Add your PostgreSQL connections here:
        -- local_pg = 'postgresql://user:password@localhost:5432/dbname',
        -- dev_pg = 'postgresql://user:password@dev-server:5432/dbname',
      }
      
      -- Icons for different database types
      vim.g.db_ui_icons = {
        expanded = {
          db = '▾ 󰆼',
          buffers = '▾ 󰈙',
          saved_queries = '▾ 󰆓',
          schemas = '▾ 󰦺',
          schema = '▾ 󰦺',
          tables = '▾ 󰓫',
          table = '▾ 󰓫',
        },
        collapsed = {
          db = '▸ 󰆼',
          buffers = '▸ 󰈙',
          saved_queries = '▸ 󰆓',
          schemas = '▸ 󰦺',
          schema = '▸ 󰦺',
          tables = '▸ 󰓫',
          table = '▸ 󰓫',
        },
      }
      
      -- Enhanced table helpers with PostgreSQL focus
      vim.g.db_ui_table_helpers = {
        postgresql = {
          Count = 'SELECT COUNT(*) FROM "{table}";',
          Columns = [[
            SELECT 
              column_name,
              data_type,
              is_nullable,
              column_default,
              character_maximum_length
            FROM information_schema.columns 
            WHERE table_name = '{table}'
            ORDER BY ordinal_position;
          ]],
          Schema = '\\d+ {table}',
          Sample = 'SELECT * FROM "{table}" LIMIT 10;',
          Explain = 'EXPLAIN (ANALYZE, BUFFERS) {last_query}',
          Indexes = [[
            SELECT 
              schemaname,
              tablename,
              indexname,
              indexdef
            FROM pg_indexes 
            WHERE tablename = '{table}';
          ]],
          Size = [[
            SELECT 
              pg_size_pretty(pg_total_relation_size('{table}'::regclass)) as total_size,
              pg_size_pretty(pg_relation_size('{table}'::regclass)) as table_size,
              pg_size_pretty(pg_total_relation_size('{table}'::regclass) - pg_relation_size('{table}'::regclass)) as indexes_size;
          ]],
          FK = [[
            SELECT
              tc.table_schema, 
              tc.constraint_name, 
              tc.table_name, 
              kcu.column_name,
              ccu.table_schema AS foreign_table_schema,
              ccu.table_name AS foreign_table_name,
              ccu.column_name AS foreign_column_name 
            FROM information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
              ON tc.constraint_name = kcu.constraint_name
              AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
              ON ccu.constraint_name = tc.constraint_name
              AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' 
              AND tc.table_name = '{table}';
          ]],
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
        mysql = {
          Count = 'SELECT COUNT(*) FROM `{table}`;',
          Columns = 'DESCRIBE `{table}`;',
          Sample = 'SELECT * FROM `{table}` LIMIT 10;',
          Explain = 'EXPLAIN {last_query}',
          Schema = 'SHOW CREATE TABLE `{table}`;',
          Indexes = 'SHOW INDEX FROM `{table}`;',
        },
      }

      -- Key mappings
      vim.keymap.set('n', '<leader>db', '<cmd>DBUIToggle<cr>', { desc = 'Toggle DBUI' })
      vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Find DB buffer' })
      vim.keymap.set('n', '<leader>dr', '<cmd>DBUIRenameBuffer<cr>', { desc = 'Rename DB buffer' })
      vim.keymap.set('n', '<leader>dq', '<cmd>DBUILastQueryInfo<cr>', { desc = 'Last query info' })
      
      -- Enhanced table exploration
      vim.keymap.set('n', '<leader>dt', function()
        local word = vim.fn.expand('<cword>')
        if word and word ~= '' then
          -- Check if we're in a PostgreSQL buffer
          local db_type = vim.b.db_ui_database_type or 'postgresql'
          if db_type == 'postgresql' then
            vim.cmd('DB \\d+ ' .. word)
          else
            vim.cmd('DB PRAGMA table_info(' .. word .. ')')
          end
        else
          vim.notify('No table name under cursor', vim.log.levels.WARN)
        end
      end, { desc = 'Show table schema' })
      
      -- Quick data sample
      vim.keymap.set('n', '<leader>ds', function()
        local word = vim.fn.expand('<cword>')
        if word and word ~= '' then
          vim.cmd('DB SELECT * FROM ' .. word .. ' LIMIT 10;')
        else
          vim.notify('No table name under cursor', vim.log.levels.WARN)
        end
      end, { desc = 'Sample table data' })
      
      -- Show table size (PostgreSQL)
      vim.keymap.set('n', '<leader>dz', function()
        local word = vim.fn.expand('<cword>')
        if word and word ~= '' then
          vim.cmd([[DB SELECT 
            pg_size_pretty(pg_total_relation_size(]] .. "'" .. word .. "'" .. [[::regclass)) as total_size,
            pg_size_pretty(pg_relation_size(]] .. "'" .. word .. "'" .. [[::regclass)) as table_size;]])
        else
          vim.notify('No table name under cursor', vim.log.levels.WARN)
        end
      end, { desc = 'Show table size (PostgreSQL)' })
      
      -- Show foreign keys
      vim.keymap.set('n', '<leader>dk', function()
        local word = vim.fn.expand('<cword>')
        if word and word ~= '' then
          vim.cmd([[DB SELECT
            tc.constraint_name, 
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name 
          FROM information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND tc.table_name = ']] .. word .. [[';]])
        else
          vim.notify('No table name under cursor', vim.log.levels.WARN)
        end
      end, { desc = 'Show foreign keys (PostgreSQL)' })
      
      -- Show indexes
      vim.keymap.set('n', '<leader>di', function()
        local word = vim.fn.expand('<cword>')
        if word and word ~= '' then
          vim.cmd([[DB SELECT 
            indexname,
            indexdef
          FROM pg_indexes 
          WHERE tablename = ']] .. word .. [[';]])
        else
          vim.notify('No table name under cursor', vim.log.levels.WARN)
        end
      end, { desc = 'Show table indexes (PostgreSQL)' })
    end,
    
    config = function()
      vim.cmd('runtime! plugin/dadbod.vim')
      
      -- Enhanced PostgreSQL documentation
      local postgres_docs = {
        -- Data Types
        ['INTEGER'] = 'INTEGER - 4-byte signed integer (-2,147,483,648 to 2,147,483,647)',
        ['BIGINT'] = 'BIGINT - 8-byte signed integer',
        ['SERIAL'] = 'SERIAL - Auto-incrementing 4-byte integer',
        ['BIGSERIAL'] = 'BIGSERIAL - Auto-incrementing 8-byte integer',
        ['VARCHAR'] = 'VARCHAR(n) - Variable-length character string with limit',
        ['TEXT'] = 'TEXT - Variable-length character string without limit',
        ['BOOLEAN'] = 'BOOLEAN - True/false value (TRUE, FALSE, NULL)',
        ['DATE'] = 'DATE - Calendar date (year, month, day)',
        ['TIMESTAMP'] = 'TIMESTAMP - Date and time (without timezone)',
        ['TIMESTAMPTZ'] = 'TIMESTAMPTZ - Date and time with timezone',
        ['JSON'] = 'JSON - Textual JSON data with validation',
        ['JSONB'] = 'JSONB - Binary JSON data with indexing support',
        ['UUID'] = 'UUID - Universally unique identifier',
        ['ARRAY'] = 'ARRAY - Variable-length multidimensional arrays',
        
        -- Functions
        ['COUNT'] = 'COUNT(*) - Returns number of rows\nCOUNT(column) - Returns number of non-null values',
        ['SUM'] = 'SUM(column) - Returns sum of numeric values',
        ['AVG'] = 'AVG(column) - Returns average of numeric values',
        ['MAX'] = 'MAX(column) - Returns maximum value',
        ['MIN'] = 'MIN(column) - Returns minimum value',
        ['STRING_AGG'] = 'STRING_AGG(expression, delimiter) - Concatenates values with delimiter',
        ['ARRAY_AGG'] = 'ARRAY_AGG(expression) - Aggregates values into an array',
        ['COALESCE'] = 'COALESCE(val1, val2, ...) - Returns first non-null value',
        ['NULLIF'] = 'NULLIF(val1, val2) - Returns null if values are equal',
        ['CASE'] = 'CASE WHEN condition THEN result ELSE default END',
        ['EXTRACT'] = 'EXTRACT(field FROM timestamp) - Extract date/time field',
        ['DATE_TRUNC'] = 'DATE_TRUNC(precision, timestamp) - Truncate to specified precision',
        ['NOW'] = 'NOW() - Current date and time with timezone',
        ['CURRENT_DATE'] = 'CURRENT_DATE - Current date',
        ['CURRENT_TIME'] = 'CURRENT_TIME - Current time with timezone',
        ['LENGTH'] = 'LENGTH(string) - Returns character length of string',
        ['UPPER'] = 'UPPER(string) - Converts string to uppercase',
        ['LOWER'] = 'LOWER(string) - Converts string to lowercase',
        ['TRIM'] = 'TRIM(string) - Removes whitespace from both ends',
        ['SUBSTRING'] = 'SUBSTRING(string FROM start FOR length) - Extract substring',
        ['CONCAT'] = 'CONCAT(str1, str2, ...) - Concatenate strings',
        ['REPLACE'] = 'REPLACE(string, from, to) - Replace occurrences in string',
        ['SPLIT_PART'] = 'SPLIT_PART(string, delimiter, field) - Split string and return field',
        ['REGEXP_REPLACE'] = 'REGEXP_REPLACE(source, pattern, replacement) - Replace using regex',
        ['TO_CHAR'] = 'TO_CHAR(value, format) - Convert to string with format',
        ['TO_DATE'] = 'TO_DATE(string, format) - Convert string to date',
        ['TO_TIMESTAMP'] = 'TO_TIMESTAMP(string, format) - Convert string to timestamp',
        ['GENERATE_SERIES'] = 'GENERATE_SERIES(start, stop, step) - Generate sequence of values',
        ['ROW_NUMBER'] = 'ROW_NUMBER() OVER (ORDER BY ...) - Assign unique row numbers',
        ['RANK'] = 'RANK() OVER (ORDER BY ...) - Assign ranks with gaps for ties',
        ['DENSE_RANK'] = 'DENSE_RANK() OVER (ORDER BY ...) - Assign ranks without gaps',
        ['LAG'] = 'LAG(column, offset) OVER (ORDER BY ...) - Access previous row value',
        ['LEAD'] = 'LEAD(column, offset) OVER (ORDER BY ...) - Access next row value',
        
        -- Keywords and Clauses
        ['SELECT'] = 'SELECT - Retrieve data from tables\nSyntax: SELECT columns FROM table WHERE condition',
        ['FROM'] = 'FROM - Specify source table(s)\nCan include JOINs, subqueries, CTEs',
        ['WHERE'] = 'WHERE - Filter rows based on conditions\nSupports AND, OR, NOT, comparison operators',
        ['GROUP BY'] = 'GROUP BY - Group rows for aggregate functions\nColumns in SELECT must be in GROUP BY or aggregated',
        ['HAVING'] = 'HAVING - Filter groups (use after GROUP BY)\nLike WHERE but for aggregated data',
        ['ORDER BY'] = 'ORDER BY - Sort result set\nUse ASC (ascending) or DESC (descending)',
        ['LIMIT'] = 'LIMIT n - Restrict number of returned rows\nOften used with OFFSET for pagination',
        ['OFFSET'] = 'OFFSET n - Skip n rows before returning results\nUsed with LIMIT for pagination',
        ['DISTINCT'] = 'DISTINCT - Remove duplicate rows from result set',
        ['JOIN'] = 'JOIN - Combine rows from multiple tables\nTypes: INNER, LEFT, RIGHT, FULL OUTER',
        ['INNER JOIN'] = 'INNER JOIN - Return only matching rows from both tables',
        ['LEFT JOIN'] = 'LEFT JOIN - Return all rows from left table, matching from right',
        ['RIGHT JOIN'] = 'RIGHT JOIN - Return all rows from right table, matching from left',
        ['FULL JOIN'] = 'FULL OUTER JOIN - Return all rows from both tables',
        ['UNION'] = 'UNION - Combine result sets (removes duplicates)\nUse UNION ALL to keep duplicates',
        ['WITH'] = 'WITH (CTE) - Common Table Expression\nDefine temporary result set for complex queries',
        ['INSERT'] = 'INSERT INTO table (columns) VALUES (values)\nOr INSERT INTO table SELECT ...',
        ['UPDATE'] = 'UPDATE table SET column = value WHERE condition',
        ['DELETE'] = 'DELETE FROM table WHERE condition',
        ['CREATE TABLE'] = 'CREATE TABLE name (column type constraints, ...)',
        ['ALTER TABLE'] = 'ALTER TABLE name ADD/DROP/MODIFY column',
        ['DROP TABLE'] = 'DROP TABLE name - Permanently delete table',
        ['INDEX'] = 'CREATE INDEX name ON table (columns) - Improve query performance',
        ['UNIQUE'] = 'UNIQUE constraint - Ensure column values are unique',
        ['PRIMARY KEY'] = 'PRIMARY KEY - Unique identifier for table rows',
        ['FOREIGN KEY'] = 'FOREIGN KEY - Reference to primary key in another table',
        ['NOT NULL'] = 'NOT NULL - Column cannot contain null values',
        ['DEFAULT'] = 'DEFAULT value - Set default value for column',
        ['CHECK'] = 'CHECK (condition) - Validate column values',
        
        -- PostgreSQL-specific
        ['SERIAL'] = 'SERIAL - Auto-incrementing integer (shorthand for integer with sequence)',
        ['RETURNING'] = 'RETURNING columns - Return values from INSERT/UPDATE/DELETE',
        ['ON CONFLICT'] = 'ON CONFLICT (columns) DO NOTHING/UPDATE - Handle constraint violations',
        ['UPSERT'] = 'INSERT ... ON CONFLICT DO UPDATE - Insert or update if exists',
        ['LATERAL'] = 'LATERAL - Allow subquery to reference columns from preceding table',
        ['WINDOW'] = 'WINDOW name AS (OVER clause) - Define reusable window specification',
        ['TABLESAMPLE'] = 'TABLESAMPLE method (percentage) - Sample rows from large tables',
        ['EXPLAIN'] = 'EXPLAIN (ANALYZE, BUFFERS) query - Show execution plan and statistics',
        ['ANALYZE'] = 'ANALYZE table - Update table statistics for query planner',
        ['VACUUM'] = 'VACUUM table - Reclaim storage and update statistics',
        ['REINDEX'] = 'REINDEX INDEX/TABLE name - Rebuild indexes',
      }
      
      -- SQL filetype configuration
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sql', 'sqlite', 'psql', 'mysql', 'plsql' },
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          
          if not vim.g.loaded_dadbod then
            vim.cmd('runtime! plugin/dadbod.vim')
          end
          
          local opts = { buffer = bufnr, silent = true }
          
          -- DBUI mappings
          vim.keymap.set('n', '<leader>S', '<Plug>(DBUI_SaveQuery)', opts)
          vim.keymap.set('n', '<leader>E', '<Plug>(DBUI_EditBindParameters)', opts)
          vim.keymap.set('n', '<leader>W', '<Plug>(DBUI_ToggleResultLayout)', opts)
          vim.keymap.set('n', '<leader><leader>', '<Plug>(DBUI_ExecuteQuery)', opts)
          vim.keymap.set('v', '<leader><leader>', '<Plug>(DBUI_ExecuteQuery)', opts)
          
          -- Enhanced hover with PostgreSQL documentation
          vim.keymap.set('n', 'K', function()
            local word = vim.fn.expand('<cword>')
            local line = vim.api.nvim_get_current_line()
            
            if word and word ~= '' then
              local upper_word = string.upper(word)
              
              -- Check for PostgreSQL documentation
              if postgres_docs[upper_word] then
                -- Create floating window with documentation
                local lines = vim.split(postgres_docs[upper_word], '\n')
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                vim.api.nvim_buf_set_option(buf, 'modifiable', false)
                vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
                
                local width = math.min(80, vim.o.columns - 4)
                local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.4))
                
                local win = vim.api.nvim_open_win(buf, false, {
                  relative = 'cursor',
                  width = width,
                  height = height,
                  row = 1,
                  col = 0,
                  style = 'minimal',
                  border = 'rounded',
                  title = ' PostgreSQL: ' .. upper_word .. ' ',
                  title_pos = 'center',
                })
                
                -- Auto-close after 10 seconds or on cursor move
                vim.defer_fn(function()
                  if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                  end
                end, 10000)
                
                -- Close on cursor move
                local close_autocmd
                close_autocmd = vim.api.nvim_create_autocmd('CursorMoved', {
                  buffer = bufnr,
                  callback = function()
                    if vim.api.nvim_win_is_valid(win) then
                      vim.api.nvim_win_close(win, true)
                    end
                    vim.api.nvim_del_autocmd(close_autocmd)
                  end,
                })
                
                return
              end
              
              -- Table inspection for PostgreSQL
              if word:match('^[a-zA-Z_][a-zA-Z0-9_]*$') and 
                 (line:match('FROM%s+' .. word) or line:match('JOIN%s+' .. word) or
                  line:match('UPDATE%s+' .. word) or line:match('INSERT%s+INTO%s+' .. word)) then
                
                vim.ui.select({
                  '📋 Show table structure', 
                  '📊 Sample data (10 rows)', 
                  '🔢 Row count',
                  '🔗 Foreign keys',
                  '📈 Indexes',
                  '📏 Table size',
                  '❌ Cancel'
                }, {
                  prompt = '🐘 PostgreSQL Table: ' .. word,
                }, function(choice)
                  if choice == '📋 Show table structure' then
                    vim.cmd('DB \\d+ ' .. word)
                  elseif choice == '📊 Sample data (10 rows)' then
                    vim.cmd('DB SELECT * FROM "' .. word .. '" LIMIT 10;')
                  elseif choice == '🔢 Row count' then
                    vim.cmd('DB SELECT COUNT(*) as row_count FROM "' .. word .. '";')
                  elseif choice == '🔗 Foreign keys' then
                    vim.cmd([[DB SELECT
                      tc.constraint_name, 
                      kcu.column_name,
                      ccu.table_name AS foreign_table,
                      ccu.column_name AS foreign_column 
                    FROM information_schema.table_constraints AS tc 
                    JOIN information_schema.key_column_usage AS kcu
                      ON tc.constraint_name = kcu.constraint_name
                    JOIN information_schema.constraint_column_usage AS ccu
                      ON ccu.constraint_name = tc.constraint_name
                    WHERE tc.constraint_type = 'FOREIGN KEY' 
                      AND tc.table_name = ']] .. word .. [[';]])
                  elseif choice == '📈 Indexes' then
                    vim.cmd([[DB SELECT 
                      indexname,
                      indexdef
                    FROM pg_indexes 
                    WHERE tablename = ']] .. word .. [[';]])
                  elseif choice == '📏 Table size' then
                    vim.cmd([[DB SELECT 
                      pg_size_pretty(pg_total_relation_size(']] .. word .. [['::regclass)) as total_size,
                      pg_size_pretty(pg_relation_size(']] .. word .. [['::regclass)) as table_size,
                      pg_size_pretty(pg_total_relation_size(']] .. word .. [['::regclass) - pg_relation_size(']] .. word .. [['::regclass)) as indexes_size;]])
                  end
                end)
                return
              end
              
              -- Fallback: show generic help
              vim.notify('💡 Hover on SQL keywords, functions, or table names for help', vim.log.levels.INFO)
            end
          end, vim.tbl_extend('force', opts, { desc = 'PostgreSQL Documentation' }))
          
          -- Quick explain plan
          vim.keymap.set('n', '<leader>dx', function()
            local current_line = vim.api.nvim_get_current_line()
            if current_line:match('^%s*SELECT') or current_line:match('^%s*WITH') then
              -- Get the full query (current line + following lines that don't start with whitespace)
              local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('.') - 1, -1, false)
              local query_lines = {}
              for _, line in ipairs(lines) do
                table.insert(query_lines, line)
                if line:match(';%s*$') then break end
              end
              local query = table.concat(query_lines, '\n')
              vim.cmd('DB EXPLAIN (ANALYZE, BUFFERS) ' .. query)
            else
              vim.notify('Position cursor on a SELECT statement to explain', vim.log.levels.WARN)
            end
          end, vim.tbl_extend('force', opts, { desc = 'Explain query plan' }))
          
          -- Format SQL (basic)
          vim.keymap.set('v', '<leader>df', function()
            -- Get selected text
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
            local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
            
            if #lines > 0 then
              -- Basic SQL formatting
              local sql = table.concat(lines, ' ')
              sql = sql:gsub('%s+', ' ') -- Normalize whitespace
              sql = sql:gsub('SELECT', '\nSELECT')
              sql = sql:gsub('FROM', '\nFROM')
              sql = sql:gsub('WHERE', '\nWHERE')
              sql = sql:gsub('GROUP BY', '\nGROUP BY')
              sql = sql:gsub('ORDER BY', '\nORDER BY')
              sql = sql:gsub('HAVING', '\nHAVING')
              sql = sql:gsub('UNION', '\nUNION')
              sql = sql:gsub('JOIN', '\n  JOIN')
              sql = sql:gsub('LEFT JOIN', '\n  LEFT JOIN')
              sql = sql:gsub('RIGHT JOIN', '\n  RIGHT JOIN')
              sql = sql:gsub('INNER JOIN', '\n  INNER JOIN')
              
              local formatted_lines = vim.split(sql, '\n')
              vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, formatted_lines)
            end
          end, vim.tbl_extend('force', opts, { desc = 'Format SQL (basic)' }))
          
          -- Set up completion
          vim.bo[bufnr].omnifunc = 'vim_dadbod_completion#omni'
          
          -- SQL settings
          vim.bo[bufnr].tabstop = 2
          vim.bo[bufnr].shiftwidth = 2 
          vim.bo[bufnr].expandtab = true
          vim.bo[bufnr].commentstring = '-- %s'
          
          -- Enable word-based completion
          vim.opt_local.iskeyword:append('_')
        end,
      })
      
      -- Create user commands for common PostgreSQL operations
      vim.api.nvim_create_user_command('PgTableInfo', function(opts)
        local table_name = opts.args ~= '' and opts.args or vim.fn.expand('<cword>')
        if table_name and table_name ~= '' then
          vim.cmd('DB \\d+ ' .. table_name)
        else
          vim.notify('No table name provided', vim.log.levels.WARN)
        end
      end, { nargs = '?', desc = 'Show PostgreSQL table info' })
      
      vim.api.nvim_create_user_command('PgProcesses', function()
        vim.cmd([[DB SELECT 
          pid,
          usename,
          application_name,
          client_addr,
          state,
          query_start,
          LEFT(query, 100) as query_preview
        FROM pg_stat_activity 
        WHERE state != 'idle'
        ORDER BY query_start DESC;]])
      end, { desc = 'Show active PostgreSQL processes' })
      
      vim.api.nvim_create_user_command('PgLocks', function()
        vim.cmd([[DB SELECT 
          l.locktype,
          l.database,
          l.relation::regclass,
          l.page,
          l.tuple,
          l.mode,
          l.granted,
          a.usename,
          a.query,
          a.query_start,
          age(now(), query_start) AS duration
        FROM pg_locks l
        LEFT JOIN pg_stat_activity a ON l.pid = a.pid
        WHERE NOT l.granted
        ORDER BY l.relation;]])
      end, { desc = 'Show PostgreSQL locks' })
    end,
  },
}
