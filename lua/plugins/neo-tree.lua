-- lua/plugins/neo-tree.lua
-- Fixed Neo-tree configuration with better error handling and Rust support

return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    close_if_last_window = false,
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    
    -- Add error handling
    log_level = "info",
    log_to_file = false,
    
    default_component_configs = {
      container = {
        enable_character_fade = true,
      },
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "└",
        highlight = "NeoTreeIndentMarker",
        with_expanders = nil,
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
      icon = {
        folder_closed = "",
        folder_open = "",
        folder_empty = "󰜌",
        default = "*",
        highlight = "NeoTreeFileIcon",
      },
      modified = {
        symbol = "[+]",
        highlight = "NeoTreeModified",
      },
      name = {
        trailing_slash = false,
        use_git_status_colors = true,
        highlight = "NeoTreeFileName",
      },
      git_status = {
        symbols = {
          added     = "✚",
          modified  = "",
          deleted   = "✖",
          renamed   = "󰁕",
          untracked = "",
          ignored   = "",
          unstaged  = "󰄱",
          staged    = "",
          conflict  = "",
        },
      },
      file_size = {
        enabled = true,
        required_width = 64,
      },
      type = {
        enabled = true,
        required_width = 122,
      },
      last_modified = {
        enabled = true,
        required_width = 88,
      },
      created = {
        enabled = true,
        required_width = 110,
      },
      symlink_target = {
        enabled = false,
      },
    },
    
    -- Custom renderers for better file handling
    renderers = {
      directory = {
        { "indent" },
        { "icon" },
        { "current_filter" },
        {
          "container",
          content = {
            { "name", zindex = 10 },
            { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
            { "clipboard", zindex = 10 },
            { "diagnostics", errors_only = true, zindex = 20, align = "right", hide_when_expanded = true },
            { "git_status", zindex = 10, align = "right", hide_when_expanded = true },
          },
        },
      },
      file = {
        { "indent" },
        { "icon" },
        {
          "container",
          content = {
            {
              "name",
              zindex = 10,
              -- Add custom filtering for problematic files
              filter = function(node)
                -- Skip files that might cause rendering issues
                local name = node.name or ""
                return not (name:match("%.tmp$") or name:match("%.lock$") or name == "")
              end,
            },
            { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
            { "clipboard", zindex = 10 },
            { "bufnr", zindex = 10, align = "right" },
            { "modified", zindex = 20, align = "right" },
            { "diagnostics", zindex = 20, align = "right", hide_when_expanded = true },
            { "git_status", zindex = 10, align = "right" },
          },
        },
      },
    },

    window = {
      position = "left",
      width = 40,
      mapping_options = {
        noremap = true,
        nowait = true,
      },
      mappings = {
        ["<space>"] = {
          "toggle_node",
          nowait = false,
        },
        ["<2-LeftMouse>"] = "open",
        ["<cr>"] = "open",
        ["<esc>"] = "cancel",
        ["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
        ["l"] = "focus_preview",
        ["S"] = "open_split",
        ["s"] = "open_vsplit",
        ["t"] = "open_tabnew",
        ["w"] = "open_with_window_picker",
        ["C"] = "close_node",
        ["z"] = "close_all_nodes",
        ["a"] = {
          "add",
          config = {
            show_path = "none",
          }
        },
        ["A"] = "add_directory",
        ["d"] = "delete",
        ["r"] = "rename",
        ["y"] = "copy_to_clipboard",
        ["x"] = "cut_to_clipboard",
        ["p"] = "paste_from_clipboard",
        ["c"] = "copy",
        ["m"] = "move",
        ["q"] = "close_window",
        ["R"] = "refresh",
        ["?"] = "show_help",
        ["<"] = "prev_source",
        [">"] = "next_source",
        ["i"] = "show_file_details",
      },
    },

    nesting_rules = {},

    filesystem = {
      filtered_items = {
        visible = false,
        hide_dotfiles = true,
        hide_gitignored = true,
        hide_hidden = true,
        hide_by_name = {
          ".DS_Store",
          "thumbs.db",
          "node_modules",
          ".git",
          ".cargo", -- Hide Rust cargo cache
          "target", -- Hide Rust build artifacts by default
        },
        hide_by_pattern = {
          "*.tmp",
          "*.pyc",
          "*.o",
          "*.so",
          "*.swp",
          "*.bak",
          "*.lock", -- Hide lock files that might cause issues
        },
        always_show = {
          ".gitignored",
          "Cargo.toml", -- Always show important Rust files
          "Cargo.lock",
          ".env",
        },
        never_show = {
          ".git",
          ".DS_Store",
          "thumbs.db",
        },
        never_show_by_pattern = {
          ".null-ls_*",
        },
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      group_empty_dirs = false,
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = false,
      window = {
        mappings = {
          ["<bs>"] = "navigate_up",
          ["."] = "set_root",
          ["H"] = "toggle_hidden",
          ["/"] = "fuzzy_finder",
          ["D"] = "fuzzy_finder_directory",
          ["#"] = "fuzzy_sorter",
          ["f"] = "filter_on_submit",
          ["<c-x>"] = "clear_filter",
          ["[g"] = "prev_git_modified",
          ["]g"] = "next_git_modified",
          ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
          ["oc"] = { "order_by_created", nowait = false },
          ["od"] = { "order_by_diagnostics", nowait = false },
          ["og"] = { "order_by_git_status", nowait = false },
          ["om"] = { "order_by_modified", nowait = false },
          ["on"] = { "order_by_name", nowait = false },
          ["os"] = { "order_by_size", nowait = false },
          ["ot"] = { "order_by_type", nowait = false },
        },
        fuzzy_finder_mappings = {
          ["<down>"] = "move_cursor_down",
          ["<C-n>"] = "move_cursor_down",
          ["<up>"] = "move_cursor_up",
          ["<C-p>"] = "move_cursor_up",
        },
      },
      commands = {
        -- Add a custom command to safely show target directory
        show_rust_target = function(state)
          local node = state.tree:get_node()
          if node.name == "target" then
            vim.notify("Rust target directory - use with caution, contains many files", vim.log.levels.WARN)
          end
        end,
      },
    },

    buffers = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      group_empty_dirs = true,
      show_unloaded = true,
      window = {
        mappings = {
          ["bd"] = "buffer_delete",
          ["<bs>"] = "navigate_up",
          ["."] = "set_root",
          ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
          ["oc"] = { "order_by_created", nowait = false },
          ["od"] = { "order_by_diagnostics", nowait = false },
          ["om"] = { "order_by_modified", nowait = false },
          ["on"] = { "order_by_name", nowait = false },
          ["os"] = { "order_by_size", nowait = false },
          ["ot"] = { "order_by_type", nowait = false },
        }
      },
    },

    git_status = {
      window = {
        position = "float",
        mappings = {
          ["A"]  = "git_add_all",
          ["gu"] = "git_unstage_file",
          ["ga"] = "git_add_file",
          ["gr"] = "git_revert_file",
          ["gc"] = "git_commit",
          ["gp"] = "git_push",
          ["gg"] = "git_commit_and_push",
          ["o"] = { "show_help", nowait=false, config = { title = "Order by", prefix_key = "o" }},
          ["oc"] = { "order_by_created", nowait = false },
          ["od"] = { "order_by_diagnostics", nowait = false },
          ["om"] = { "order_by_modified", nowait = false },
          ["on"] = { "order_by_name", nowait = false },
          ["os"] = { "order_by_size", nowait = false },
          ["ot"] = { "order_by_type", nowait = false },
        }
      }
    },

    -- Event handlers with error protection
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function(args)
          -- Safely set line numbers
          pcall(function()
            vim.wo.number = true
            vim.wo.relativenumber = false
          end)
        end,
      },
      {
        event = "neo_tree_window_after_open",
        handler = function(args)
          if args.position == "left" or args.position == "right" then
            vim.cmd("wincmd =")
          end
        end,
      },
      -- Add error handling for file operations
      {
        event = "neo_tree_buffer_leave",
        handler = function(args)
          -- Clear any lingering error states
          pcall(function()
            vim.cmd("redraw!")
          end)
        end,
      },
    },

    -- Add specific handling for common problematic file types
    document_symbols = {
      kinds = {
        File = { icon = "󰈙", hl = "Tag" },
        Namespace = { icon = "󰌗", hl = "Include" },
        Package = { icon = "󰏖", hl = "Label" },
        Class = { icon = "󰌗", hl = "Include" },
        Method = { icon = "󰆧", hl = "Function" },
        Property = { icon = "󰜢", hl = "Identifier" },
        Field = { icon = "󰜢", hl = "Identifier" },
        Constructor = { icon = "󰆧", hl = "Special" },
        Enum = { icon = "󰒻", hl = "Type" },
        Interface = { icon = "󰜰", hl = "Type" },
        Function = { icon = "󰆧", hl = "Function" },
        Variable = { icon = "󰀫", hl = "Constant" },
        Constant = { icon = "󰏿", hl = "Constant" },
        String = { icon = "󰀬", hl = "String" },
        Number = { icon = "󰎠", hl = "Number" },
        Boolean = { icon = "⊨", hl = "Boolean" },
        Array = { icon = "󰅪", hl = "Constant" },
        Object = { icon = "󰅩", hl = "Type" },
        Key = { icon = "󰌋", hl = "Type" },
        Null = { icon = "󰟢", hl = "Type" },
        EnumMember = { icon = "󰒻", hl = "Identifier" },
        Struct = { icon = "󰌗", hl = "Structure" },
        Event = { icon = "󰉁", hl = "Type" },
        Operator = { icon = "󰆕", hl = "Identifier" },
        TypeParameter = { icon = "󰊄", hl = "Identifier" },
        Component = { icon = "󰅴", hl = "Function" },
        Fragment = { icon = "󰅴", hl = "Constant" },
      }
    },
  },
}
