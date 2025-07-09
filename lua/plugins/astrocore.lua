-- lua/plugins/astrocore.lua
-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!

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

    -- Mappings configuration
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

        -- Telescope mappings
        ["<leader>ff"] = {
          function() require("telescope.builtin").find_files() end,
          desc = "Find files",
        },
        ["<leader>fg"] = {
          function() require("telescope.builtin").live_grep() end,
          desc = "Live grep",
        },
        ["<leader>fb"] = {
          function() require("telescope.builtin").buffers() end,
          desc = "Find buffers",
        },
        ["<leader>fh"] = {
          function() require("telescope.builtin").help_tags() end,
          desc = "Find help",
        },
        ["<leader>fo"] = {
          function() require("telescope.builtin").oldfiles() end,
          desc = "Find old files",
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
          function() require("telescope.builtin").lsp_document_symbols() end,
          desc = "Find document symbols",
        },
        ["<leader>fS"] = {
          function() require("telescope.builtin").lsp_workspace_symbols() end,
          desc = "Find workspace symbols",
        },

        -- LSP mappings
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
        ["<leader>ca"] = {
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

        -- DAP mappings (general, not Scala-specific)
        ["<leader>db"] = {
          function() require("dap").toggle_breakpoint() end,
          desc = "Toggle breakpoint",
        },
        ["<leader>dB"] = {
          function() require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ") end,
          desc = "Set conditional breakpoint",
        },
        ["<leader>dc"] = {
          function() require("dap").continue() end,
          desc = "Continue",
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
      },

      -- Visual mode mappings
      v = {
        ["<leader>ca"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "Code action",
        },
      },

      -- Insert mode mappings
      i = {
        -- Better escape
        ["jk"] = { "<ESC>", desc = "Escape insert mode" },
        ["kj"] = { "<ESC>", desc = "Escape insert mode" },
      },

      -- Terminal mode mappings
      t = {
        -- Better terminal navigation
        ["<C-h>"] = { "<C-\\><C-N><C-w>h", desc = "Terminal left window navigation" },
        ["<C-j>"] = { "<C-\\><C-N><C-w>j", desc = "Terminal down window navigation" },
        ["<C-k>"] = { "<C-\\><C-N><C-w>k", desc = "Terminal up window navigation" },
        ["<C-l>"] = { "<C-\\><C-N><C-w>l", desc = "Terminal right window navigation" },
        ["<esc>"] = { "<C-\\><C-n>", desc = "Terminal normal mode" },
      },
    },
  },
}
