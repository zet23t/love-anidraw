local ui_rect            = require "love-ui.ui_rect"
local rectfill_component = require "love-ui.components.generic.rectfill_component"
local pico8_colors       = require "love-ui.pico8_colors"
local anidraw            = require "anidraw"
local add_slider         = require "anidraw.ui.add_slider"

local color_picker_ui    = require "love-util.class" "color_picker_ui"

function color_picker_ui:new(rect)
    local cell_w = math.floor(rect.w / 16)

    local self = self:create {}

    self.current_color = { 0, 0, 0, 1 }

    local colorpicker_rect = ui_rect:new(540, 20, rect.w, 200, rect)

    local selected_color_rect = ui_rect:new(2, cell_w, cell_w * 2 - 4, cell_w * 4, colorpicker_rect)
    local selected_color_rectfill = rectfill_component:new(0, 7)
    selected_color_rect:add_component(selected_color_rectfill)
    self.selected_color_rectfill = selected_color_rectfill

    local sliders_rect = ui_rect:new(selected_color_rect:get_right() + 2, selected_color_rect.y,
        colorpicker_rect.w - selected_color_rect:get_right() - 4,
        selected_color_rect.h, colorpicker_rect)

    self.slider_r = add_slider("Red: ", sliders_rect.w, cell_w - 1, sliders_rect, 0, 1, 1, function(value)
        self:select_color(value)
    end, 0, 0)
    self.slider_g = add_slider("Green: ", sliders_rect.w, cell_w - 1, sliders_rect, 0, 1, 1, function(value)
        self:select_color(nil, value)
    end, 0, cell_w)
    self.slider_b = add_slider("Blue: ", sliders_rect.w, cell_w - 1, sliders_rect, 0, 1, 1, function(value)
        self:select_color(nil, nil, value)
    end, 0, cell_w * 2)

    colorpicker_rect:add_component(rectfill_component:new(5))
    for i = 0, 15 do
        local x = i
        local y = 0
        local color_rect = ui_rect:new(x * cell_w + 2, y * cell_w + 2, cell_w - 4, cell_w - 4,
            colorpicker_rect, rectfill_component:new(i, 7))
        color_rect:add_component {
            was_triggered = function(cmp, rect)
                self:select_color(pico8_colors[i])
            end
        }
    end
    self:select_color(pico8_colors[0])
    return self
end

function color_picker_ui:select_color(color, ...)
    local r, g, b, a = color, ...
    if type(color) == "table" then
        r, g, b, a = color[1], color[2], color[3], color[4]
    end
    local cc = self.current_color
    r, g, b, a = r or cc[1], g or cc[2], b or cc[3], a or cc[4]
    if r == cc[1] and g == cc[2] and b == cc[3] and a == cc[4] then
        return
    end

    cc[1], cc[2], cc[3], cc[4] = r, g, b, a
    self.selected_color_rectfill:set_fill(cc)
    self.slider_r(r)
    self.slider_g(g)
    self.slider_b(b)
    anidraw:set_color(cc)
end

return color_picker_ui
