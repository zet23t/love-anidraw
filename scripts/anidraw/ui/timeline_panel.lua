local ui_rect                       = require "love-ui.ui_rect"
local text_component                = require "love-ui.components.generic.text_component"
local pico8_colors                  = require "love-ui.pico8_colors"
local menubar_widget                = require "love-ui.widget.menubar_widget"
local parent_size_matcher_component = require "love-ui.components.layout.parent_size_matcher_component"
local weighted_position_component   = require "love-ui.components.layout.weighted_position_component"
local linear_layouter_component     = require "love-ui.components.layout.linear_layouter_component"
local scroll_area_widget            = require "love-ui.widget.scroll_area_widget"
local rectfill_component            = require "love-ui.components.generic.rectfill_component"
local ui_theme                      = require "love-ui.ui_theme.ui_theme"
local menu_widget                   = require "love-ui.widget.menu_widget"

local anidraw                       = require "anidraw"

local timeline_panel = {}

function timeline_panel:initialize(bottom_bar)
    local timeline = ui_rect:new(0, 0, 0, 0, bottom_bar, parent_size_matcher_component:new(0, 0, 0, 0))
    local timeline_scroll_area = scroll_area_widget:new(ui_theme, 180, 200)
    timeline:add_component(timeline_scroll_area)
    timeline_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    timeline_scroll_area.scroll_content:add_component {
        timeline_map = {},
        map_timeline = function(cmp, rect, instruction)
            if cmp.timeline_map[instruction] then return end
            local instruction_rect = ui_rect:new(0, 0, rect.w, 20, rect, rectfill_component:new(nil, 0))
            ui_theme:decorate_on_click(instruction_rect, function()
                anidraw:select_object(instruction)
            end)
            ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, instruction_rect,
                weighted_position_component:new(1, 0.5)), nil, ui_theme.icon.close_x, function()
                anidraw:delete_instruction(instruction)
                anidraw:clear_canvas()
            end)
            cmp.timeline_map[instruction] = instruction_rect
        end,
        update = function(cmp, rect)
            local map = {}
            for i = 1, #anidraw.instructions do
                local instruction = anidraw.instructions[i]
                cmp:map_timeline(rect, instruction)
                map[instruction] = true
            end
            for k, v in pairs(cmp.timeline_map) do
                if not map[k] then
                    cmp.timeline_map[k] = nil
                    v:remove()
                end
            end
        end
    }
end

return timeline_panel