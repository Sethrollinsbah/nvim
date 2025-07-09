-- lua/plugins/astrolsp.lua
-- AstroLSP configuration - cleaned up to avoid conflicts with Metals

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
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
          "scala",
          "sbt",
          "lua",
          "javascript",
          "typescript",
          "json",
          "yaml",
        },
        ignore_filetypes = {
          -- Add filetypes you don't want auto-formatted
        },
      },
      disabled = {
        -- disable formatting capabilities for the listed language servers
        -- "lua_ls", -- uncomment if you want to use StyLua instead
      },
      timeout_ms = 3000, -- increased timeout for Scala formatting
    },
    
    -- enable servers that you already have installed without mason
    servers = {
      -- Disable automatic metals setup since nvim-metals handles it
      metals = false,
    },
    
    -- customize language server configuration options passed to `lspconfig`
    config = {
      -- clangd = { capabilities = { offsetEncoding = "utf-8" } },
    },
    
    -- customize how language servers are attached
    handlers = {
      -- Disable metals handler since we handle it in scala.lua
      metals = false,
    },
    
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      -- Code lens refresh for non-Metals servers
      lsp_codelens_refresh = {
        cond = function(client, bufnr) 
          return client.name ~= "metals" and client.supports_method("textDocument/codeLens")
        end,
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then 
              vim.lsp.codelens.refresh({ bufnr = args.buf }) 
            end
          end,
        },
      },
    },
    
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        -- Standard LSP mappings (exclude Metals-specific ones)
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method("textDocument/semanticTokens/full") and vim.lsp.semantic_tokens
          end,
        },
        
        -- Add telescope diagnostics mapping here since it's LSP-related
        ["<leader>fd"] = {
          function() require("telescope.builtin").diagnostics() end,
          desc = "Find diagnostics (global)",
          cond = function(client) return client.name ~= "metals" end,
        },
      },
    },
    
    -- General on_attach for non-Metals servers
    on_attach = function(client, bufnr)
      -- Skip Metals since it has its own on_attach
      if client.name == "metals" then
        return
      end
      
      -- General LSP on_attach logic for other servers
      if client.supports_method("textDocument/codeLens") then 
        vim.lsp.codelens.refresh({ bufnr = bufnr }) 
      end
    end,
  },
}
