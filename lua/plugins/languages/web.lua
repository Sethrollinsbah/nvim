-- lua/plugins/languages/web.lua
-- Web development language servers (HTML, CSS, Svelte, etc.)

return {
  servers = {
    html = {
      filetypes = { "html", "templ" },
      settings = {
        html = {
          format = {
            templating = true,
            wrapLineLength = 120,
            wrapAttributes = "auto",
          },
          hover = {
            documentation = true,
            references = true,
          },
        },
      },
    },

    cssls = {
      settings = {
        css = {
          validate = true,
          lint = {
            unknownAtRules = "ignore",
          },
        },
        scss = {
          validate = true,
          lint = {
            unknownAtRules = "ignore",
          },
        },
        less = {
          validate = true,
          lint = {
            unknownAtRules = "ignore",
          },
        },
      },
    },

    svelte = {
      settings = {
        svelte = {
          plugin = {
            html = {
              completions = {
                enable = true,
                emmet = false,
              },
            },
            svelte = {
              completions = {
                enable = true,
              },
            },
            css = {
              completions = {
                enable = true,
                emmet = true,
              },
            },
          },
        },
      },
    },

    tailwindcss = {
      filetypes = { "html", "css", "javascript", "typescript", "svelte", "vue", "jsx", "tsx" },
      settings = {
        tailwindCSS = {
          experimental = {
            classRegex = {
              "tw`([^`]*)",
              'tw="([^"]*)',
              'tw={"([^"}]*)',
              "tw\\.\\w+`([^`]*)",
              "tw\\(.*?\\)`([^`]*)",
            },
          },
        },
      },
    },
  },

  -- Web-specific on_attach
  on_attach = function(client, bufnr)
    -- Common web development keymaps
    local opts = { buffer = bufnr, silent = true }

    if client.name == "html" then
      vim.keymap.set(
        "n",
        "<leader>wp",
        function() vim.cmd "!live-server --port=3000" end,
        vim.tbl_extend("force", opts, { desc = "Start live server" })
      )
    end

    if client.name == "tailwindcss" then
      vim.keymap.set(
        "n",
        "<leader>wt",
        function() vim.cmd "!npx tailwindcss -i ./src/input.css -o ./dist/output.css --watch" end,
        vim.tbl_extend("force", opts, { desc = "Watch Tailwind CSS" })
      )
    end
  end,
}
