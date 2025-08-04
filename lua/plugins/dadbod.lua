return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'sqlite', 'psql', 'mysql', 'plsql' }, lazy = true },
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
    
    -- Save connections (optional - stores in ~/.local/share/db_ui/connections.json)
    vim.g.db_ui_save_location = vim.fn.stdpath('data') .. '/db_ui'
    
    -- Default connection configurations
    vim.g.dbs = {
      test_sqlite = 'sqlite:/Users/sethr/dev/outdoor-tranformations/local.db',
    }
    
    -- Completion settings
    vim.g.db_ui_disable_mappings = 0
    
    -- Icons for different database types (requires nerd fonts)
    vim.g.db_ui_icons = {
      expanded = {
        db = '▾ ',
        buffers = '▾ ',
        saved_queries = '▾ ',
        schemas = '▾ ',
        schema = '▾ פּ',
        tables = '▾ 藺',
        table = '▾ ',
      },
      collapsed = {
        db = '▸ ',
        buffers = '▸ ',
        saved_queries = '▸ ',
        schemas = '▸ ',
        schema = '▸ פּ',
        tables = '▸ 藺',
        table = '▸ ',
      },
    }
    
    -- Table helpers for different database types
    vim.g.db_ui_table_helpers = {
      postgresql = {
        Count = 'SELECT COUNT(*) FROM "{table}"',
        Explain = 'EXPLAIN ANALYZE {last_query}',
        Describe = '\\d+ {table}',
      },
      sqlite = {
        Count = 'SELECT COUNT(*) FROM `{table}`',
        Explain = 'EXPLAIN QUERY PLAN {last_query}',
        Describe = '.schema {table}',
      }
    }

    -- Key mappings for DBUI
    vim.keymap.set('n', '<leader>db', '<cmd>DBUIToggle<cr>', { desc = 'Toggle DBUI' })
    vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<cr>', { desc = 'Find DB buffer' })
    vim.keymap.set('n', '<leader>dr', '<cmd>DBUIRenameBuffer<cr>', { desc = 'Rename DB buffer' })
    vim.keymap.set('n', '<leader>dq', '<cmd>DBUILastQueryInfo<cr>', { desc = 'Last query info' })
  end,
  
  config = function()
    -- ONLY SQL-specific keymaps - NO completion setup here
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'sql', 'sqlite', 'psql', 'mysql', 'plsql' },
      callback = function()
        -- SQL-specific key mappings only
        local opts = { buffer = true, silent = true }
        vim.keymap.set('n', '<leader>S', '<Plug>(DBUI_SaveQuery)', opts)
        vim.keymap.set('n', '<leader>E', '<Plug>(DBUI_EditBindParameters)', opts)
        vim.keymap.set('n', '<leader>W', '<Plug>(DBUI_ToggleResultLayout)', opts)
        
        -- Execute query mappings
        vim.keymap.set('n', '<leader><leader>', '<Plug>(DBUI_ExecuteQuery)', opts)
        vim.keymap.set('v', '<leader><leader>', '<Plug>(DBUI_ExecuteQuery)', opts)
      end,
    })
  end,
}
