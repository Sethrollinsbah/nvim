return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      -- 👇 Force relative and absolute line numbers on Neo-tree window
      mappings = {},
      position = "left",
      width = 40,
    },
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function(args)
          vim.wo.number = true -- absolute line numbers
          -- vim.wo.relativenumber = true -- relative line numbers
        end,
      },
    },
  },
}
