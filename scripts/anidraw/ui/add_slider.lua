local ui_rect            = require "love-ui.ui_rect"
local text_component     = require "love-ui.components.generic.text_component"
local rectfill_component = require "love-ui.components.generic.rectfill_component"

local invlerp            = require "love-math.invlerp"

local function add_slider(title, width, height, parent, min, max, value, on_change, x, y, on_was_released)
    local current_value = value
    value = invlerp(min, max, value)
    local slider_rect = ui_rect:new(x or 0, y or 0, width, height, parent, rectfill_component:new(1))
    local slider_bar_rect = ui_rect:new(2, 2, slider_rect.w - 4, slider_rect.h - 4, slider_rect,
        rectfill_component:new(2, 6))
    local slider_text_rect = ui_rect:new(0, 0, slider_rect.w, slider_rect.h, slider_rect,
        text_component:new(""))

    local function set_slider_value(value, was_released)
        if not value then 
            return current_value
        end
        if value == current_value then
            return
        end
        current_value = value
        local maxw = slider_rect.w - 4
        slider_bar_rect.w = math.max(1, math.min(maxw, value * maxw))
        value = min + (max - min) * value
        slider_text_rect:trigger_on_components("set_text", string.format("%s%.2f", title or " ", value))
        if on_change then on_change(value) end
        if was_released and on_was_released then
            on_was_released(value)
        end
    end
    slider_rect:add_component {
        is_pressed_down = function(cmp, rect, mx, my)
            set_slider_value(math.max(0, math.min(1, mx / rect.w)))
        end,
        was_released = function(cmp, rect, mx, my)
            set_slider_value(math.max(0, math.min(1, mx / rect.w)), true)
        end,
    }
    set_slider_value(value)
    return set_slider_value
end

return add_slider
