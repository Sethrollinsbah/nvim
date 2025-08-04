return {
  {
    "hrsh7th/nvim-cmp", -- Autocompletion engine
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- Completion source for LSP
      "hrsh7th/cmp-buffer", -- Buffer completions
      "hrsh7th/cmp-path", -- Path completions
      "hrsh7th/cmp-cmdline", -- Command line completions
      "L3MON4D3/LuaSnip", -- Snippets
      "saadparwaiz1/cmp_luasnip", -- Snippet completion source
      "kristijanhusak/vim-dadbod-completion", -- SQL completion source
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Helper function to check if we have words before cursor
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- MAIN CMP SETUP - for all filetypes
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          
          -- Tab completion
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        
        -- DEFAULT sources for most files
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
        
        formatting = {
          format = function(entry, vim_item)
            -- Add source name to completion items
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
              ["vim-dadbod-completion"] = "[DB]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })

      -- SQL COMPLETION - Single setup, prioritize DB completion
      cmp.setup.filetype({ "sql", "sqlite", "psql", "mysql", "plsql" }, {
        sources = {
          { name = "vim-dadbod-completion" }, -- DB completion first
          { name = "buffer" },               -- Buffer second
          { name = "luasnip" },             -- Snippets last
        },
      })

      -- Command line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" }
        }, {
          { name = "cmdline" }
        })
      })

      -- Search completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" }
        }
      })
    end,
  },

  -- customize dashboard options
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "███████ █████ █████████ ██",
            "██      ██       ██     ██",
            "███████ ████████ ██ ██  ██",
            "     ██ ██       ██ ██████",
            "███████ ████████ ██ ██  ██",
            "",
            "██     ██ ██ ███    ███ ██",
            "██     ██    ████  ████ ██",
            "██     ██ ██ ██ ████ ██ ██",
            " ██   ██  ██ ██  ██  ██   ",
            "  █████   ██ ██      ██ ██",
          }, "\n"),
        },
      },
    },
  },

  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
    end,
  },
  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },
}
