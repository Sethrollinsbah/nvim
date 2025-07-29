return {
  -- amongst your other plugins
  {
    'akinsho/toggleterm.nvim', 
    version = "*", 
    keys = {
      { "<leader>tt", function()
          require("toggleterm.terminal").Terminal:new({ direction = "tab" }):toggle()
        end, desc = "Tab terminal" 
      },
    },
    opts = {
      -- Default settings
      size = 20,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = 'float', -- default direction
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      
      -- Custom keybindings for easier exit
      on_create = function(term)
        local opts = { buffer = term.bufnr }
        -- Double escape to exit insert mode
        vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)
        -- Ctrl+q to quickly close terminal
        vim.keymap.set("t", "<C-q>", "<C-\\><C-n>:q<CR>", opts)
        -- Ctrl+x to close tab
        vim.keymap.set("t", "<C-x>", "<C-\\><C-n>:tabclose<CR>", opts)
      end,
      
      -- Window options for tab terminals
      winbar = {
        enabled = false,
      },
    }
  }
}
