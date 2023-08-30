---@class editables : object
local editables = require "love-util.class" "editables"

---A list of editable configurations for an object
---@return editables
function editables:new()
    return self:create{}
end

---Slider for chosing a number.
---@param key string
---@param name string
---@param min number
---@param max number
---@param step number
---@param default number
---@return table
function editables:number_slider(key, name, min, max, step, default)
    return self:add {
        key = key;
        type = "number_slider";
        name = name;
        min = min;
        max = max;
        step = step;
        default = default;
    }
end

---Toggle for chosing a boolean.
---@param key string
---@param name string
---@param default boolean
function editables:toggle(key, name, default)
    return self:add {
        key = key;
        type = "toggle";
        name = name;
        default = default;
    }
end

---Options for chosing a value from a list.
---@param key string
---@param name string
---@param options table a table of options, each a pair of {name, value}
---@param default any the value of the default option
---@return editables
function editables:options(key, name, options, default)
    return self:add {
        key = key;
        type = "options";
        name = name;
        options = options;
        default = default;
    }
end

function editables:add(config)
    self[#self+1] = config
    return self
end

return editables