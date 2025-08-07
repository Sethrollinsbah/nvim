local ffi = require("ffi")

-- Declare the Rust FFI function signatures (match your Rust functions)
ffi.cdef[[
    void add_line(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);
    void undo();
    void redo();
    void save_to_file(const char *path);
    void load_from_file(const char *path);
]]

-- Load your Rust shared library (adjust path)
local lib = ffi.load("/Users/sethr/dev/drawing_core/target/debug/libxdraw_rs.dylib")

local M = {}

function M.add_line(x1, y1, x2, y2)
    lib.add_line(x1, y1, x2, y2)
end

function M.undo()
    lib.undo()
end

function M.redo()
    lib.redo()
end

function M.save(path)
    lib.save_to_file(path)
end

function M.load(path)
    lib.load_from_file(path)
end

return M
