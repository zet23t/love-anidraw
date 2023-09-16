local config_settings = require "config_settings"

local draw_settings = {}

function draw_settings:get_pressure_size()
    local value = config_settings:get("pressure_size", 0.1)
    return value
end

function draw_settings:set_pressure_size(size)
    config_settings:set("pressure_size", size)
end

function draw_settings:get_min_size()
    return config_settings:get("min_size", 0)
end

function draw_settings:set_min_size(size)
    config_settings:set("min_size", size)
end

return draw_settings