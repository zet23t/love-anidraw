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
local sprite_component              = require "love-ui.components.generic.sprite_component"

local anidraw                       = require "anidraw"

local timeline_panel = {}

function timeline_panel:initialize(bottom_bar)
    local command_bar = ui_rect:new(0, 0, 30, 30, bottom_bar)
    
    command_bar:add_component(parent_size_matcher_component:new(0, 0, true, 0))
    command_bar:add_component(rectfill_component:new(pico8_colors.dark_gray))
    command_bar:add_component(linear_layouter_component:new(1, false, 0, 0, 0, 0, 2):set_minor_axis_fit_enabled(false))
    ui_theme:decorate_button_skin(ui_rect:new(0,0,22,22,command_bar), nil, ui_theme.icon.open_folder_add, function()
        -- create a new group
        anidraw:create_new_group()
    end)
    
    local timeline = ui_rect:new(0, 0, 0, 0, bottom_bar, parent_size_matcher_component:new(30, 0, 0, 0))
    local timeline_scroll_area = scroll_area_widget:new(ui_theme, 180, 200)
    timeline:add_component(timeline_scroll_area)
    timeline_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    timeline_scroll_area.scroll_content:add_component {
        timeline_map = {},
        map_timeline = function(cmp, rect, instruction)
            if cmp.timeline_map[instruction] then return end
            local instruction_rect = ui_rect:new(0, 0, rect.w, 20, rect, rectfill_component:new(nil, 0))
            instruction_rect.mapped_instruction = instruction
            instruction_rect.mapped_instruction_mod_count = instruction.mod_count
            if instruction.icon then
                instruction_rect:add_component(sprite_component:new(instruction.icon, 4,2))
            end
            local title = instruction_rect:add_component(text_component:new(instruction:tostr(), pico8_colors.black))
            anidraw:subscribe_to(instruction, function()
                title:set_text(instruction:tostr())
            end)
            instruction_rect:add_component {
                on_removed = function()
                    anidraw:unsubscribe_from(instruction)
                end
            }
            if instruction.is_group then
                instruction_rect:add_component(linear_layouter_component:new(2, false, 20, 0, 0, 0, 0))
            end
            ui_theme:decorate_on_click(instruction_rect, function()
                anidraw:select_object(instruction)
            end)
            local delete_button = ui_rect:new(0, 0, 20, 20, instruction_rect, weighted_position_component:new(1, 0.5))
            delete_button.ignore_layouting = true
            ui_theme:decorate_button_skin(delete_button, nil, ui_theme.icon.close_x, function()
                anidraw:delete_instruction(instruction)
                anidraw:clear_canvas()
            end)
            instruction_rect:add_component({
                was_pressed_down = function(cmp, rect, mx, my)
                    cmp.px, cmp.py = mx, my
                end,
                was_released = function(cmp, rect, mx, my)
                    cmp.px, cmp.py = nil, nil
                    if cmp.selected_element and cmp.selected_element.mapped_instruction.add_instruction then
                        cmp.selected_element.mapped_instruction:add_instruction(instruction)
                    end
                end,
                is_pressed_down = function(cmp, rect, mx, my)
                    cmp.mx, cmp.my = mx, my
                    local x,y = timeline_scroll_area.scroll_content.parent:to_local(rect:to_world(mx, my))
                    local hits = {}
                    timeline_scroll_area.scroll_content:collect_hits(x,y,hits)
                    cmp.selected_element = nil
                    for i=1,#hits do
                        local hit = hits[i]
                        if hit.mapped_instruction and hit ~= instruction_rect then
                            cmp.selected_element = hit
                            break
                        end
                    end
                end,
                draw = function(cmp, rect)
                    if not cmp.px then return end
                    local ax,ay = rect:to_world(cmp.px, cmp.py)
                    local bx, by = rect:to_world(cmp.mx, cmp.my)
                    local late_command = require "love-util.late_command"
                    late_command(function()
                        local sx,sy,sw,sh = love.graphics.getScissor()
                        love.graphics.setScissor()
                        love.graphics.setLineWidth(5)
                        love.graphics.setColor(0,cmp.selected_element and cmp.selected_element.mapped_instruction.is_group and .5 or 0,0)
                        if cmp.selected_element and cmp.selected_element.mapped_instruction.is_group then
                            local x,y = cmp.selected_element:to_world(0,0)
                            love.graphics.rectangle("line", x, y, cmp.selected_element.w, cmp.selected_element.h)
                        end
                        love.graphics.line(ax, ay, bx, by)
                        love.graphics.setColor(1,1,1)
                        love.graphics.setLineWidth(1)
                        love.graphics.setScissor(sx,sy,sw,sh)
                    end)

                end
            })
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