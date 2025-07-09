-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing
---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      autoformat = true, -- enable or disable auto formatting on start
      codelens = true, -- enable/disable codelens refresh on start (IMPORTANT for Scala run/debug buttons)
      inlay_hints = false, -- enable/disable inlay hints on start
      semantic_tokens = true, -- enable/disable semantic token highlighting
    },
    -- customize lsp formatting options
    formatting = {
      -- control auto formatting on save
      format_on_save = {
        enabled = true, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          "scala", -- Add Scala formatting
          "sbt",
        },
        ignore_filetypes = { -- disable format on save for specified filetypes
          -- "python",
        },
      },
      disabled = { -- disable formatting capabilities for the listed language servers
        -- disable lua_ls formatting capability if you want to use StyLua to format your lua code
        -- "lua_ls",
      },
      timeout_ms = 1000, -- default format timeout
    },
    -- enable servers that you already have installed without mason
    servers = {
      -- Disable automatic metals setup since nvim-metals handles it
      metals = false,
    },
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      -- clangd = { capabilities = { offsetEncoding = "utf-8" } },
    },
    -- customize how language servers are attached
    handlers = {
      -- a function without a key is simply the default handler, functions take two parameters, the server name and the configured options table for that server
      -- function(server, opts) require("lspconfig")[server].setup(opts) end
      -- the key is the server that is being setup with `lspconfig`
      -- rust_analyzer = false, -- setting a handler to false will disable the set up of that language server
      -- pyright = function(_, opts) require("lspconfig").pyright.setup(opts) end -- or a custom handler function can be passed
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- first key is the `augroup` to add the auto commands to (:h augroup)
      lsp_codelens_refresh = {
        -- Optional condition to create/delete auto command group
        -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
        -- condition will be resolved for each client on each execution and if it ever fails for all clients,
        -- the auto commands will be deleted for that buffer
        cond = "textDocument/codeLens",
        -- cond = function(client, bufnr) return client.name == "lua_ls" end,
        -- list of auto commands to set
        {
          -- events to trigger
          event = { "InsertLeave", "BufEnter" },
          -- the rest of the autocmd options (:h nvim_create_autocmd)
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
        -- a `cond` key can provided as the string of a server capability to be required to attach, or a function with `client` and `bufnr` parameters from the `on_attach` that returns a boolean
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

        -- Metals Code Lens and Debug mappings (FIXED)
        ["<Leader>ml"] = {
          function() vim.lsp.codelens.run() end,
          desc = "Run Code Lens",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>mr"] = {
          function() require("metals").run_scoped() end,
          desc = "Run Scoped",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>md"] = {
          function() require("metals").debug_scoped() end,
          desc = "Debug Scoped",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },

        -- Quick test actions (FIXED)
        ["<Leader>tr"] = {
          function() require("metals").test_run() end,
          desc = "Run Test",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>td"] = {
          function() require("metals").test_debug() end,
          desc = "Debug Test",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },

        -- Additional Metals mappings (FIXED)
        ["<Leader>mc"] = {
          function() require("metals").compile_cascade() end,
          desc = "Compile Cascade",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>mh"] = {
          function() require("metals").hover_worksheet() end,
          desc = "Hover Worksheet",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>mt"] = {
          function() require("metals.tvp").toggle_tree_view() end,
          desc = "Toggle Tree View",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>ma"] = {
          function() require("metals").run_doctor() end,
          desc = "Run Doctor",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
        ["<Leader>mi"] = {
          function() require("metals").toggle_setting "showImplicitArguments" end,
          desc = "Toggle Implicit Args",
          cond = function(client, bufnr) return client.name == "metals" end, -- FIXED: Added bufnr parameter
        },
      },
    },
    on_attach = function(client, bufnr)
      if client.name == "metals" then
        if client.supports_method "textDocument/codeLens" then vim.lsp.codelens.refresh { bufnr = bufnr } end
      end
    end,
  },
}
