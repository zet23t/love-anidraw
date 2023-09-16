---@class editables : object
local editables = require "love-util.class" "editables"

---A list of editable configurations for an object
---@return editables
function editables:new()
    return self:create {}
end

---Slider for chosing a number.
---@param key string
---@param name string
---@param min number
---@param max number
---@param step number
---@param default number
---@param on_change function|nil
---@return editables
function editables:number_slider(key, name, min, max, step, default, on_change)
    return self:add {
        key = key,
        type = "number_slider",
        name = name,
        min = min,
        max = max,
        step = step,
        default = default,
        on_change = on_change,
    }
end

---Toggle for chosing a boolean.
---@param key string
---@param name string
---@param default boolean
---@param on_change function|nil
---@return editables
function editables:toggle(key, name, default, on_change)
    return self:add {
        key = key,
        type = "toggle",
        name = name,
        default = default,
        on_change = on_change,
    }
end

---Dropdown for selecting an existing layer
---@param key string
---@param name string
---@param on_change function|nil
---@return editables
function editables:layer(key, name, on_change)
    return self:add { key = key, type = "layer", name = name, default = nil, on_change = on_change }
end

---Options for chosing a value from a list.
---@param key string
---@param name string
---@param options table a table of options, each a pair of {name, value}
---@param default any the value of the default option
---@param on_change function|nil
---@return editables
function editables:options(key, name, options, default, on_change)
    return self:add {
        key = key,
        type = "options",
        name = name,
        options = options,
        default = default,
        on_change = on_change,
    }
end

---@param key string
---@param name string
---@param default any
---@param on_change function|nil
---@return editables
function editables:color(key, name, default, on_change)
    return self:add {
        key = key,
        type = "color",
        name = name,
        default = default,
        on_change = on_change,
    }
end

---@return editables
function editables:add(config)
    self[#self + 1] = config
    return self
end

return editables
