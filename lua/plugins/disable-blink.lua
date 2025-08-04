-- Add this to lua/plugins/disable-blink.lua
-- This will disable blink.cmp which might be conflicting with nvim-cmp

return {
  -- Disable blink.cmp completely
  {
    "saghen/blink.cmp",
    enabled = false,
  },
  {
    "saghen/blink.compat", 
    enabled = false,
  },
}
