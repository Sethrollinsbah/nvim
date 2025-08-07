
local ffi = require("ffi")

-- Load your Rust dynamic lib (adjust the path if needed)
local lib = ffi.load("/Users/sethr/dev/drawing_core/target/debug/libxdraw_rs.dylib")

-- Declare C functions if your Rust exposes them
ffi.cdef[[
void add_line(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);
void undo();
void redo();
void save(const char *filename);
void load(const char *filename);
]]

local M = {}

M.add_line = function(x1, y1, x2, y2)
  lib.add_line(x1, y1, x2, y2)
end

M.undo = function()
  lib.undo()
end

M.redo = function()
  lib.redo()
end

M.save = function(filename)
  lib.save(filename)
end

M.load = function(filename)
  lib.load(filename)
end

return M

