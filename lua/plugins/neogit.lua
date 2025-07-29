return {
  "NeogitOrg/neogit",
  keys = {
    { "<leader>ng", "<cmd>Neogit<cr>", desc = "Neogit" },
    { "<leader>nc", "<cmd>Neogit commit<cr>", desc = "Neogit commit" },
    { "<leader>np", "<cmd>Neogit push<cr>", desc = "Neogit push" },
    { "<leader>nl", "<cmd>Neogit pull<cr>", desc = "Neogit pull" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",         -- required
    "sindrets/diffview.nvim",        -- optional - Diff integration
    "nvim-telescope/telescope.nvim", -- optional
  },
  config = function()
    require("neogit").setup({
      -- Neogit refreshes its internal state after specific events, which can be expensive depending on the repository size.
      -- Disabling `auto_refresh` will make it so you have to manually refresh the status after you have changed the repository
      -- outside of Neogit.
      auto_refresh = true,
      -- Disable signs define to use your own signs
      disable_signs = false,
      -- Disable hint from neogit
      disable_hint = false,
      -- Disable context highlighting
      disable_context_highlighting = false,
      -- Disable commit confirmation
      disable_commit_confirmation = false,
      -- Disable insert/edit on commit confirmation
      disable_builtin_editor = false,
      -- Set to false if you want to be responsible for creating _ALL_ keymappings
      use_default_keymaps = true,
      -- The time delay before updating the status buffer
      status = {
        recent_commit_count = 10,
      },
      commit_editor = {
        kind = "tab",
        show_staged_diff = true,
      },
      commit_select_view = {
        kind = "tab",
      },
      commit_view = {
        kind = "vsplit",
        verify_commit = os.execute("which gpg") == 0, -- Can be set to true or false, otherwise we try to find the binary
      },
      log_view = {
        kind = "tab",
      },
      rebase_editor = {
        kind = "tab",
      },
      reflog_view = {
        kind = "tab",
      },
      merge_editor = {
        kind = "tab",
      },
      tag_editor = {
        kind = "tab",
      },
      preview_buffer = {
        kind = "split",
      },
      popup = {
        kind = "split",
      },
      signs = {
        hunk = { "", "" },
        item = { "+", "-" },
        section = { "+", "-" },
      },
      -- Each Integration is auto-detected through plugin presence, however, it can be disabled by setting to `false`
      integrations = {
        telescope = true,
        diffview = true,
        fzf_lua = false,
        mini_pick = false,
      },
      -- Setting any section to `false` will make the section not render at all
      sections = {
        -- Reverting/Cherry Picking
        sequencer = {
          folded = false,
          hidden = false,
        },
        untracked = {
          folded = false,
          hidden = false,
        },
        unstaged = {
          folded = false,
          hidden = false,
        },
        staged = {
          folded = false,
          hidden = false,
        },
        stashes = {
          folded = true,
          hidden = false,
        },
        unpulled_upstream = {
          folded = true,
          hidden = false,
        },
        unmerged_upstream = {
          folded = false,
          hidden = false,
        },
        unpulled_pushRemote = {
          folded = true,
          hidden = false,
        },
        unmerged_pushRemote = {
          folded = false,
          hidden = false,
        },
        recent = {
          folded = true,
          hidden = false,
        },
        rebase = {
          folded = true,
          hidden = false,
        },
      },
      mappings = {
        finder = {
          ["<cr>"] = "Select",
          ["<c-c>"] = "Close",
          ["<esc>"] = "Close",
          ["<c-n>"] = "Next",
          ["<c-p>"] = "Previous",
          ["<down>"] = "Next",
          ["<up>"] = "Previous",
          ["<tab>"] = "MultiselectToggleNext",
          ["<s-tab>"] = "MultiselectTogglePrevious",
          ["<c-j>"] = "NOP",
        },
        popup = {
          ["?"] = "HelpPopup",
          ["A"] = "CherryPickPopup",
          ["D"] = "DiffPopup",
          ["M"] = "RemotePopup",
          ["P"] = "PushPopup",
          ["X"] = "ResetPopup",
          ["Z"] = "StashPopup",
          ["b"] = "BranchPopup",
          ["c"] = "CommitPopup",
          ["f"] = "FetchPopup",
          ["l"] = "LogPopup",
          ["m"] = "MergePopup",
          ["p"] = "PullPopup",
          ["r"] = "RebasePopup",
          ["t"] = "TagPopup",
          ["v"] = "RevertPopup",
          ["w"] = "WorktreePopup",
        },
      },
    })
  end,
}
