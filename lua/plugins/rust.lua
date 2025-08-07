return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  ft = { "rust" },
  opts = {
    tools = {
      runnables = {
        use_telescope = true,
      },
    },
    hover_actions = {
      auto_focus = true,
    },
    server = {
      on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, vim.tbl_extend("force", opts, { desc = "Hover" }))
        vim.keymap.set("n", "gD", function() vim.lsp.buf.definition() end, vim.tbl_extend("force", opts, { desc = "Go To Definition" }))
        vim.keymap.set("n", "<leader>ca", function() vim.cmd.RustLsp "codeAction" end, vim.tbl_extend("force", opts, { desc = "Code Action" }))
        vim.keymap.set("n", "<leader>dr", function() vim.cmd.RustLsp "debuggables" end, vim.tbl_extend("force", opts, { desc = "Rust Debuggables" }))
        vim.keymap.set("n", "<leader>rr", function() vim.cmd.RustLsp "runnables" end, vim.tbl_extend("force", opts, { desc = "Runnables" }))
        vim.keymap.set("n", "<leader>rt", function()
          -- Enhanced unit test runner with better cursor detection
          local function run_test()
            local bufnr = vim.api.nvim_get_current_buf()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local line = cursor[1] - 1 -- Convert to 0-based indexing
            -- First, check if we're currently on a function line
            local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
            local current_func = current_line:match("fn%s+([%w_]+)%s*%(")
            if current_func then
              -- Check if this function has #[unit_test] above it
              local check_lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, line - 5), line, false)
              for _, check_line in ipairs(check_lines) do
                if check_line:match("#%[unit_test%]") then
                  -- Found it!
                  local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
                  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                  if cargo_toml ~= "" then
                    local content = vim.fn.readfile(cargo_toml)
                    for _, toml_line in ipairs(content) do
                      local name = toml_line:match('^name%s*=%s*"([^"]+)"')
                      if name then
                        project_name = name
                        break
                      end
                    end
                  end
                  local cmd = "cargo test -p " .. project_name .. " --features test-utils -- " .. current_func
                  vim.notify("Running: " .. cmd, vim.log.levels.INFO)
                  vim.cmd("split")
                  vim.cmd("terminal " .. cmd)
                  return
                end
              end
            end
            -- If we're not on a function line, search for the nearest function with #[unit_test]
            -- Look backwards first, then forwards
            local found_function = nil
            local found_line = nil
            -- Search backwards
            for search_line = line, math.max(0, line - 50), -1 do
              local lines = vim.api.nvim_buf_get_lines(bufnr, search_line, search_line + 1, false)
              if #lines > 0 then
                local text = lines[1]
                local func_match = text:match("fn%s+([%w_]+)%s*%(")
                if func_match then
                  -- Check if this function has #[unit_test] above it
                  local check_lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, search_line - 5), search_line, false)
                  for _, check_line in ipairs(check_lines) do
                    if check_line:match("#%[%w+_test%]") then
                      found_function = func_match
                      found_line = search_line
                      break
                    end
                  end
                  if found_function then break end
                end
              end
            end
            -- If not found backwards, search forwards
            if not found_function then
              for search_line = line + 1, math.min(vim.api.nvim_buf_line_count(bufnr) - 1, line + 50) do
                local lines = vim.api.nvim_buf_get_lines(bufnr, search_line, search_line + 1, false)
                if #lines > 0 then
                  local text = lines[1]
                  local func_match = text:match("fn%s+([%w_]+)%s*%(")
                  if func_match then
                    -- Check if this function has #[unit_test] above it
                    local check_lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, search_line - 5), search_line, false)
                    for _, check_line in ipairs(check_lines) do
                      if check_line:match("#%[%w+_test%]") then
                        found_function = func_match
                        found_line = search_line
                        break
                      end
                    end
                    if found_function then break end
                  end
                end
              end
            end
            if found_function then
              local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
              local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
              if cargo_toml ~= "" then
                local content = vim.fn.readfile(cargo_toml)
                for _, toml_line in ipairs(content) do
                  local name = toml_line:match('^name%s*=%s*"([^"]+)"')
                  if name then
                    project_name = name
                    break
                  end
                end
              end
              local cmd = "cargo test -p " .. project_name .. " --features test-utils -- " .. found_function
              vim.notify("Running nearest unit test: " .. found_function .. " (line " .. (found_line + 1) .. ")", vim.log.levels.INFO)
              vim.cmd("split")
              vim.cmd("terminal " .. cmd)
            else
              vim.notify("No #[unit_test] function found near cursor", vim.log.levels.WARN)
            end
          end
          run_test()
        end, vim.tbl_extend("force", opts, { desc = "Run Unit Test" }))
        -- Add a command to run all unit tests
        vim.keymap.set("n", "<leader>rT", function()
          local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
          local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
          if cargo_toml ~= "" then
            local content = vim.fn.readfile(cargo_toml)
            for _, line in ipairs(content) do
              local name = line:match('^name%s*=%s*"([^"]+)"')
              if name then
                project_name = name
                break
              end
            end
          end
          local cmd = "cargo test -p " .. project_name .. " --features test-utils"
          vim.notify("Running all unit tests: " .. cmd, vim.log.levels.INFO)
          vim.cmd("split")
          vim.cmd("terminal " .. cmd)
        end, vim.tbl_extend("force", opts, { desc = "Run All Unit Tests" }))
        vim.keymap.set("n", "<leader>rc", function() vim.cmd("!cargo check --all-features") end, vim.tbl_extend("force", opts, { desc = "Check (all features)" }))
        vim.keymap.set("n", "<leader>rl", function() vim.cmd("!cargo clippy --all-features -- -D warnings") end, vim.tbl_extend("force", opts, { desc = "Clippy (all features)" }))
        vim.keymap.set("n", "<leader>rR", function() vim.cmd("!cargo run --release") end, vim.tbl_extend("force", opts, { desc = "Run release build" }))
        vim.keymap.set("n", "<leader>re", function() vim.cmd.RustLsp "expandMacro" end, vim.tbl_extend("force", opts, { desc = "Expand Macro" }))
        vim.keymap.set("n", "<leader>rV", function() vim.cmd.RustLsp "viewCrateGraph" end, vim.tbl_extend("force", opts, { desc = "View Crate Graph" }))
        vim.keymap.set("n", "<leader>rT", function() vim.cmd.RustLsp "explainError" end, vim.tbl_extend("force", opts, { desc = "Explain Error" }))
      end,
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true, loadOutDirsFromCheck = true, buildScripts = { enable = true } },
              -- Check settings
            checkOnSave = {
              enable = true,
              command = "clippy",
              extraArgs = { "--no-deps", "--", "-D", "warnings" },
            },
          completion = {
              addCallParentheses = true,
              addCallArgumentSnippets = true,
            },
            procMacro = {
              enable = true,
              attributes = {
                enable = true,
              },
            },
            diagnostics = {
              enable = true,
              enableExperimental = true,
            },
          lens = {
            enable = true,
            run = true,
            debug = true,
            implementations = true,
            references = true,
            methodReferences = true,
            enumVariantReferences = true,
          },

          inlayHints = {
            auto = true,
            onlyCurrentScope = false,
            typeHints = { enable = true, hideNamedConstructor = true },
            parameterHints = { enable = true },
            chainingHints = { enable = true },
          },
        },
      },
    },
    dap = {
      adapter = nil,
    },
  },
  config = function(_, opts)
    -- Use the standard Mason path directly to avoid API issues
    local mason_path = vim.fn.stdpath("data") .. "/mason"
    local codelldb_path = mason_path .. "/packages/codelldb"
    local adapter_path = codelldb_path .. "/extension/adapter/codelldb"
    -- Check if codelldb is installed by checking if the adapter executable exists
    if vim.fn.executable(adapter_path) == 1 then
      local lib_path = codelldb_path .. "/extension/lldb/lib/"
      local lib_ext = vim.fn.has("mac") == 1 and "liblldb.dylib" or "liblldb.so"
      opts.dap.adapter = require("rustaceanvim.config").get_codelldb_adapter(adapter_path, lib_path .. lib_ext)
    end
    -- Initialize rustaceanvim with the opts
    vim.g.rustaceanvim = opts
  end,
}
