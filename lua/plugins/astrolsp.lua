-- lua/plugins/astrolsp.lua
-- Main AstroLSP configuration that loads language-specific configs

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = function()
    -- Load language-specific configurations
    local lang_configs = {}

    -- Helper function to safely load language configs
    local function load_lang_config(name)
      local ok, config = pcall(require, "plugins.languages." .. name)
      if ok and config then
        return config
      else
        vim.notify("Failed to load language config: " .. name, vim.log.levels.WARN)
        return {}
      end
    end

    -- Load all language configurations
    local languages = {
      "lua",
      "rust",
      "typescript",
      "python",
      "web",
      "system",
    }

    for _, lang in ipairs(languages) do
      local config = load_lang_config(lang)
      if config.servers then
        for server, opts in pairs(config.servers) do
          -- EXCLUDE rust_analyzer since rustaceanvim handles it
          if server ~= "rust_analyzer" then
            lang_configs[server] = opts
          end
        end
      end
    end

    return {
      -- Configuration table of features provided by AstroLSP
      features = {
        autoformat = true, -- enable or disable auto formatting on start
        codelens = true, -- enable/disable codelens refresh on start
        inlay_hints = false, -- enable/disable inlay hints on start
        semantic_tokens = true, -- enable/disable semantic token highlighting
      },

      -- customize lsp formatting options
      formatting = {
        -- control auto formatting on save
        format_on_save = {
          enabled = true, -- enable or disable format on save globally
          allow_filetypes = { -- enable format on save for specified filetypes only
            "lua",
            "javascript",
            "typescript",
            "json",
            "yaml",
            "rust",
            "python",
            "move",
            "html",
            "css",
            "svelte",
          },
          ignore_filetypes = {
            -- Add filetypes you don't want auto-formatted
          },
        },
        disabled = {
          -- disable formatting capabilities for the listed language servers
          -- "lua_ls", -- uncomment if you want to use StyLua instead
        },
        timeout_ms = 3000, -- timeout for formatting
      },

      -- enable servers that you already have installed without mason
      --       -- enable servers that you already have installed without mason
      servers = {
        -- Explicitly disable rust_analyzer (extra safety)
        rust_analyzer = false,
      },

      -- Use the loaded language configurations (excluding rust_analyzer)
      config = lang_configs,

      -- Setup handlers to explicitly prevent rust_analyzer from starting
      setup_handlers = {
        -- Prevent rust_analyzer from being set up by astrolsp
        rust_analyzer = function(server_name, opts)
          -- Do nothing - let rustaceanvim handle it
          vim.notify("Skipping rust_analyzer setup (handled by rustaceanvim)", vim.log.levels.INFO)
        end,
      },

      -- Configure buffer local auto commands to add when attaching a language server
      autocmds = {
        -- Code lens refresh
        lsp_codelens_refresh = {
          {
            event = { "InsertLeave", "BufEnter" },
            desc = "Refresh codelens (buffer)",
            callback = function(args)
              if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
            end,
          },
        },
      },

      -- mappings to be set up on attaching of a language server
      mappings = {
        n = {
          -- Standard LSP mappings
          gD = {
            function() vim.lsp.buf.declaration() end,
            desc = "Declaration of current symbol",
            cond = "textDocument/declaration",
          },

          ["<Leader>uY"] = {
            function() require("astrolsp.toggles").buffer_semantic_tokens() end,
            desc = "Toggle LSP semantic highlight (buffer)",
            cond = function(client)
              return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens
            end,
          },

          -- Telescope diagnostics mapping
          ["<leader>fd"] = {
            function() require("telescope.builtin").diagnostics() end,
            desc = "Find diagnostics (global)",
          },
        },
      },

      -- General on_attach for all servers
      on_attach = function(client, bufnr)
        -- Skip rust_analyzer if it somehow gets through (extra safety)
        if client.name == "rust_analyzer" then
          vim.notify("Stopping duplicate rust_analyzer instance", vim.log.levels.WARN)
          client.stop()
          return
        end

        -- General LSP on_attach logic
        if client.supports_method "textDocument/codeLens" then vim.lsp.codelens.refresh { bufnr = bufnr } end

        -- Load language-specific on_attach if available (excluding rust)
        for _, lang in ipairs(languages) do
          if lang ~= "rust" then -- Skip rust on_attach since rustaceanvim handles it
            local config = load_lang_config(lang)
            if config.on_attach and type(config.on_attach) == "function" then 
              config.on_attach(client, bufnr) 
            end
          end
        end
      end,
    }
  end,
}
