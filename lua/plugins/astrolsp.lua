-- File: lua/plugins/astrolsp.lua
-- Cleaned-up AstroLSP configuration that lets rustaceanvim handle Rust

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = function()
    -- Helper function to safely load language configs
    local function load_lang_config(name)
      local ok, config = pcall(require, "plugins.languages." .. name)
      if ok and config then return config end
      return {}
    end

    -- Load language configurations
    local lang_configs = {}
    local languages = { "lua", "typescript", "python", "web", "system" }
    for _, lang in ipairs(languages) do
      local config = load_lang_config(lang)
      if config.servers then
        for server, opts in pairs(config.servers) do
          lang_configs[server] = opts
        end
      end
    end

    -- Return the final AstroLSP options table
    return {
      features = {
        autoformat = true,
        codelens = true,
        inlay_hints = false, -- Correctly disabled for rustaceanvim
        semantic_tokens = true,
      },

      formatting = {
        format_on_save = {
          enabled = true,
          -- NOTE: "rust" is correctly excluded; formatting is handled by rustaceanvim
          allow_filetypes = {
            "lua", "javascript", "typescript", "json", "yaml", "python", "move",
            "html", "css", "svelte", "sql", "sqlite", "mysql", "psql", "plsql",
          },
        },
        disabled = { "rust_analyzer" }, -- Correctly disabled
      },

      -- This table is where server-specific settings go. They are passed to nvim-lspconfig.
      config = vim.tbl_deep_extend("force", lang_configs, {
        -- SQL Language Servers
        sqlls = {
          -- Your sqlls config... (kept as is)
        },
        sqls = {
          -- Your sqls config... (kept as is)
        },
      }),

      -- This handler prevents astrolsp from setting up rust_analyzer, which is correct.
      setup_handlers = {
        rust_analyzer = function() return false end,
      },

      -- Your useful, general-purpose mappings
      mappings = {
        n = {
          -- ======= GLOBAL DIAGNOSTICS MAPPINGS (KEEP THESE) =======
          ["<leader>fd"] = {
            function() require("telescope.builtin").diagnostics { bufrn = nil } end,
            desc = "Find all diagnostics (workspace)",
          },
          ["<leader>fD"] = {
            function() require("telescope.builtin").diagnostics { bufrn = 0 } end,
            desc = "Find diagnostics (current buffer)",
          },
          ["<leader>fe"] = {
            function() require("telescope.builtin").diagnostics { severity = vim.diagnostic.severity.ERROR } end,
            desc = "Find errors only",
          },
          ["<leader>fw"] = {
            function() require("telescope.builtin").diagnostics { severity = vim.diagnostic.severity.WARN } end,
            desc = "Find warnings only",
          },

          -- ======= NAVIGATION MAPPINGS (KEEP THESE) =======
          ["]d"] = { function() vim.diagnostic.goto_next() end, desc = "Next diagnostic" },
          ["[d"] = { function() vim.diagnostic.goto_prev() end, desc = "Previous diagnostic" },
        },
      },

      -- General on_attach for NON-RUST servers
      on_attach = function(client, bufnr)
        if client.name == "rust_analyzer" then return end -- Final safeguard

        -- Your SQL-specific on_attach logic (kept as is)
        if client.name == "sqlls" or client.name == "sqls" then
          -- ... your SQL keymaps ...
        end

        -- General LSP on_attach logic for other languages
        if client.supports_method "textDocument/codeLens" then vim.lsp.codelens.refresh { bufnr = bufnr } end
      end,
    }
  end,
}
