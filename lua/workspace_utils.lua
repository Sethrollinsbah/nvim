-- lua/plugins/workspace_utils.lua
-- Utility functions for Cargo workspace detection and navigation

local M = {}

-- Enhanced workspace member detection function
function M.parse_workspace_members(cargo_toml_path)
  if vim.fn.filereadable(cargo_toml_path) ~= 1 then
    return {}
  end

  local content = vim.fn.readfile(cargo_toml_path)
  local members = {}
  local in_workspace = false
  local in_members = false
  local members_content = ""

  for _, line in ipairs(content) do
    local trimmed = line:match("^%s*(.-)%s*$") -- Trim whitespace
    
    -- Check if we're entering workspace section
    if trimmed:match("^%[workspace%]") then
      in_workspace = true
      in_members = false
      members_content = ""
    -- Check if we're leaving workspace section
    elseif trimmed:match("^%[") and not trimmed:match("^%[workspace") then
      in_workspace = false
      in_members = false
      -- Process any accumulated members content
      if members_content ~= "" then
        -- Extract members from accumulated content
        for member in members_content:gmatch('"([^"]*)"') do
          if member ~= "" then
            table.insert(members, member)
          end
        end
      end
      break
    -- If we're in workspace section, look for members
    elseif in_workspace then
      -- Check for start of members array
      if trimmed:match("^members%s*=%s*%[") then
        in_members = true
        -- Extract any members on the same line
        local same_line = trimmed:match("^members%s*=%s*%[(.*)%]")
        if same_line then
          -- Single line members array
          members_content = same_line
          in_members = false
        else
          -- Multi-line members array
          local partial = trimmed:match("^members%s*=%s*%[(.*)") 
          if partial then
            members_content = partial
          end
        end
      -- If we're in members array, continue collecting
      elseif in_members then
        if trimmed:match("%]") then
          -- End of members array
          local final_part = trimmed:match("(.*)%]")
          if final_part then
            members_content = members_content .. " " .. final_part
          end
          in_members = false
        else
          -- Continue collecting members
          members_content = members_content .. " " .. trimmed
        end
      end
    end
  end

  -- Final processing of members_content
  if members_content ~= "" then
    for member in members_content:gmatch('"([^"]*)"') do
      if member ~= "" then
        table.insert(members, member)
      end
    end
  end

  return members
end

-- Enhanced workspace info function
function M.get_workspace_info()
  local workspace_root = vim.fn.getcwd()
  local cargo_toml = workspace_root .. "/Cargo.toml"
  
  if vim.fn.filereadable(cargo_toml) ~= 1 then
    return {
      is_workspace = false,
      members = {},
      root = workspace_root
    }
  end

  local members = M.parse_workspace_members(cargo_toml)
  local is_workspace = #members > 0
  
  -- If no members found, check if there's a workspace section without members
  if not is_workspace then
    local content = vim.fn.readfile(cargo_toml)
    for _, line in ipairs(content) do
      if line:match("^%s*%[workspace%]") then
        is_workspace = true
        break
      end
    end
  end

  return {
    is_workspace = is_workspace,
    members = members,
    root = workspace_root
  }
end

-- Enhanced workspace overview function
function M.show_workspace_overview()
  local workspace_info = M.get_workspace_info()
  local lines = {"🦀 Cargo Workspace Overview", ""}
  
  table.insert(lines, "📁 Root: " .. workspace_info.root)
  table.insert(lines, "")
  
  if workspace_info.is_workspace then
    if #workspace_info.members > 0 then
      table.insert(lines, "📦 Workspace Members:")
      for _, member in ipairs(workspace_info.members) do
        local member_path = workspace_info.root .. "/" .. member
        local member_cargo = member_path .. "/Cargo.toml"
        
        if vim.fn.filereadable(member_cargo) == 1 then
          local member_content = vim.fn.readfile(member_cargo)
          local package_name = ""
          
          for _, m_line in ipairs(member_content) do
            local name = m_line:match('^%s*name%s*=%s*"(.-)"')
            if name then
              package_name = name
              break
            end
          end
          
          if package_name ~= "" then
            table.insert(lines, string.format("  • %s (%s)", member, package_name))
          else
            table.insert(lines, "  • " .. member)
          end
        else
          table.insert(lines, "  • " .. member .. " (Cargo.toml not found)")
        end
      end
    else
      table.insert(lines, "📦 Workspace detected but no members found")
      table.insert(lines, "   (Check your Cargo.toml members array)")
    end
  else
    table.insert(lines, "📦 Single package project")
  end
  
  -- Add debugging info
  table.insert(lines, "")
  table.insert(lines, "🔧 Debug Info:")
  table.insert(lines, "  • Members found: " .. #workspace_info.members)
  table.insert(lines, "  • Is workspace: " .. tostring(workspace_info.is_workspace))
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  local width = math.max(60, vim.o.columns * 0.6)
  local height = math.min(#lines + 2, vim.o.lines * 0.8)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Workspace Overview ",
    title_pos = "center",
  })
  
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<cr>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<cr>", { silent = true })
end

-- Enhanced workspace navigation
function M.navigate_workspace_member(direction)
  local workspace_info = M.get_workspace_info()
  
  if not workspace_info.is_workspace or #workspace_info.members == 0 then
    vim.notify("No workspace members found", vim.log.levels.WARN)
    return
  end
  
  local current_dir = vim.fn.expand("%:p:h")
  local current_idx = 1
  
  -- Find current package index
  for i, member in ipairs(workspace_info.members) do
    local member_path = workspace_info.root .. "/" .. member
    if current_dir:match("^" .. vim.pesc(member_path)) then
      current_idx = i
      break
    end
  end
  
  -- Calculate next/previous index
  local target_idx
  if direction == "next" then
    target_idx = (current_idx % #workspace_info.members) + 1
  else
    target_idx = current_idx == 1 and #workspace_info.members or current_idx - 1
  end
  
  local target_member = workspace_info.members[target_idx]
  local target_path = workspace_info.root .. "/" .. target_member
  local src_path = target_path .. "/src"
  
  -- Try to find the best file to open
  local files_to_try = {
    src_path .. "/main.rs",
    src_path .. "/lib.rs",
    target_path .. "/Cargo.toml",
    src_path .. "/mod.rs",
  }
  
  for _, file in ipairs(files_to_try) do
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("edit " .. file)
      vim.notify(string.format("Navigated to %s (%s)", target_member, vim.fn.fnamemodify(file, ":t")), vim.log.levels.INFO)
      return
    end
  end
  
  -- If no specific file found, try to open the directory
  if vim.fn.isdirectory(target_path) == 1 then
    vim.cmd("edit " .. target_path)
    vim.notify("Navigated to " .. target_member, vim.log.levels.INFO)
  else
    vim.notify("Could not find files for " .. target_member, vim.log.levels.WARN)
  end
end

-- Test function to debug workspace parsing
function M.test_workspace_parsing()
  local workspace_info = M.get_workspace_info()
  
  print("=== Workspace Debug Info ===")
  print("Root:", workspace_info.root)
  print("Is workspace:", workspace_info.is_workspace)
  print("Members count:", #workspace_info.members)
  
  if #workspace_info.members > 0 then
    print("Members:")
    for i, member in ipairs(workspace_info.members) do
      print(string.format("  %d. %s", i, member))
    end
  end
  
  -- Also show raw Cargo.toml content for debugging
  local cargo_toml = workspace_info.root .. "/Cargo.toml"
  if vim.fn.filereadable(cargo_toml) == 1 then
    print("\n=== Raw Cargo.toml Content ===")
    local content = vim.fn.readfile(cargo_toml)
    for i, line in ipairs(content) do
      print(string.format("%3d: %s", i, line))
    end
  end
end

return M
