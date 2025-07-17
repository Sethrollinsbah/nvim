-- lua/plugins/rustaceanvim.lua
-- Advanced Rust plugin that replaces rust_analyzer LSP setup

return {
  "mrcjkb/rustaceanvim",
  version = "^5", -- Recommended
  lazy = false, -- This plugin is already lazy
  ft = { "rust" },
  
  config = function()
    vim.g.rustaceanvim = {
      -- Plugin configuration
      tools = {
        -- These apply to the default RustAnalyzer instance, even when multiple
        -- different analyzer instances are running (e.g. if you have a separate
        -- analyzer for a workspace that contains C code)
        executor = "toggleterm",
        on_initialized = nil,
        reload_workspace_from_cargo_toml = true,
        inlay_hints = {
          auto = true,
          only_current_line = false,
          show_parameter_hints = true,
          parameter_hints_prefix = "<- ",
          other_hints_prefix = "=> ",
          max_len_align = false,
          max_len_align_padding = 1,
          right_align = false,
          right_align_padding = 7,
          highlight = "Comment",
        },
        hover_actions = {
          auto_focus = false,
        },
        runnables = {
          use_telescope = true,
        },
        debuggables = {
          use_telescope = true,
        },
        crate_graph = {
          backend = "x11",
          output = nil,
          full = true,
          enabled_graphviz_backends = {
            "bmp",
            "cgimage",
            "canon",
            "dot",
            "gv",
            "xdot",
            "xdot1.2",
            "xdot1.4",
            "eps",
            "exr",
            "fig",
            "gd",
            "gd2",
            "gif",
            "gtk",
            "ico",
            "cmap",
            "ismap",
            "imap",
            "cmapx",
            "imap_np",
            "cmapx_np",
            "jpg",
            "jpeg",
            "jpe",
            "jp2",
            "json",
            "json0",
            "dot_json",
            "xdot_json",
            "pdf",
            "pic",
            "pct",
            "pict",
            "plain",
            "plain-ext",
            "png",
            "pov",
            "ps",
            "ps2",
            "psd",
            "sgi",
            "svg",
            "svgz",
            "tga",
            "tiff",
            "tif",
            "tk",
            "vml",
            "vmlz",
            "wbmp",
            "webp",
            "xlib",
            "x11",
          },
        },
      },
      
      -- LSP configuration
      server = {
        on_attach = function(client, bufnr)
          -- Enable inlay hints
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(bufnr, true)
          end
          
          -- Rust-specific keymaps
          local opts = { buffer = bufnr, silent = true }
          
          -- Code actions
          vim.keymap.set("n", "<leader>ca", function()
            vim.cmd.RustLsp('codeAction')
          end, vim.tbl_extend("force", opts, { desc = "Code Action" }))
          
          -- Runnables
          vim.keymap.set("n", "<leader>rr", function()
            vim.cmd.RustLsp('runnables')
          end, vim.tbl_extend("force", opts, { desc = "Runnables" }))
          
          -- Debuggables  
          vim.keymap.set("n", "<leader>rd", function()
            vim.cmd.RustLsp('debuggables')
          end, vim.tbl_extend("force", opts, { desc = "Debuggables" }))
          
          -- Test related
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd.RustLsp('testables')
          end, vim.tbl_extend("force", opts, { desc = "Testables" }))
          
          -- Expand macros
          vim.keymap.set("n", "<leader>rem", function()
            vim.cmd.RustLsp('expandMacro')
          end, vim.tbl_extend("force", opts, { desc = "Expand macro" }))
          
          -- Move item up/down
          vim.keymap.set("n", "<leader>rmU", function()
            vim.cmd.RustLsp('moveItem', 'up')
          end, vim.tbl_extend("force", opts, { desc = "Move item up" }))
          
          vim.keymap.set("n", "<leader>rmD", function()
            vim.cmd.RustLsp('moveItem', 'down')  
          end, vim.tbl_extend("force", opts, { desc = "Move item down" }))
          
          -- Hover actions
          vim.keymap.set("n", "<leader>rh", function()
            vim.cmd.RustLsp('hover', 'actions')
          end, vim.tbl_extend("force", opts, { desc = "Hover actions" }))
          
          -- Explain error
          vim.keymap.set("n", "<leader>re", function()
            vim.cmd.RustLsp('explainError')
          end, vim.tbl_extend("force", opts, { desc = "Explain error" }))
          
          -- Open cargo.toml
          vim.keymap.set("n", "<leader>rc", function()
            vim.cmd.RustLsp('openCargo')
          end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
          
          -- Parent module
          vim.keymap.set("n", "<leader>rp", function()
            vim.cmd.RustLsp('parentModule')
          end, vim.tbl_extend("force", opts, { desc = "Parent module" }))
          
          -- Join lines
          vim.keymap.set("n", "<leader>rj", function()
            vim.cmd.RustLsp('joinLines')
          end, vim.tbl_extend("force", opts, { desc = "Join lines" }))
          
          -- Structural search replace
          vim.keymap.set("n", "<leader>rsr", function()
            vim.cmd.RustLsp('ssr')
          end, vim.tbl_extend("force", opts, { desc = "Structural search replace" }))
          
          -- Crate graph
          vim.keymap.set("n", "<leader>rcg", function()
            vim.cmd.RustLsp('crateGraph')
          end, vim.tbl_extend("force", opts, { desc = "Crate graph" }))
          
          -- View HIR/MIR
          vim.keymap.set("n", "<leader>rvh", function()
            vim.cmd.RustLsp('view', 'hir')
          end, vim.tbl_extend("force", opts, { desc = "View HIR" }))
          
          vim.keymap.set("n", "<leader>rvm", function()
            vim.cmd.RustLsp('view', 'mir')
          end, vim.tbl_extend("force", opts, { desc = "View MIR" }))
        end,
        
        default_settings = {
          -- rust-analyzer language server configuration
          ['rust-analyzer'] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Add clippy lints for Rust.
            checkOnSave = {
              allFeatures = true,
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            inlayHints = {
              bindingModeHints = {
                enable = false,
              },
              chainingHints = {
                enable = true,
              },
              closingBraceHints = {
                enable = true,
                minLines = 25,
              },
              closureReturnTypeHints = {
                enable = "never",
              },
              lifetimeElisionHints = {
                enable = "never",
                useParameterNames = false,
              },
              maxLength = 25,
              parameterHints = {
                enable = true,
              },
              reborrowHints = {
                enable = "never",
              },
              renderColons = true,
              typeHints = {
                enable = true,
                hideClosureInitialization = false,
                hideNamedConstructor = false,
              },
            },
          },
        },
      },
      
      -- DAP configuration
      dap = {
        adapter = {
          type = "executable",
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          name = "rt_lldb",
        },
      },
    }
  end,
}
