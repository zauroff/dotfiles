-- Shim: nvim-ufo (via promise-async) and refactoring.nvim (via lewis6991/async.nvim)
-- both publish a module named `async`, so whichever loads first wins the rtp race
-- and breaks the other. They use disjoint surfaces -- ufo only calls async(fn),
-- refactoring only reads async.run/await/wrap -- so route __call and __index apart.
local function load_from(plugin, mod)
    local chunk = loadfile(("%s/lazy/%s/lua/%s.lua"):format(vim.fn.stdpath("data"), plugin, mod))
    return chunk and chunk()
end

local cache = {}

local function backend(key, plugin)
    if cache[key] == nil then
        cache[key] = load_from(plugin, "async")
    end
    return cache[key]
end

return setmetatable({}, {
    __call = function(_, ...)
        return backend("promise", "promise-async")(...)
    end,
    __index = function(_, k)
        local lewis = backend("lewis", "async.nvim")
        return lewis and lewis[k]
    end,
})
