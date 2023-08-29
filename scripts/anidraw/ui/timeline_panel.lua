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
local textfield_component           = require "love-ui.components.generic.textfield_component"

local anidraw                       = require "anidraw"

local timeline_panel                = {}

function timeline_panel:initialize(bottom_bar)
    local command_bar = ui_rect:new(0, 0, 30, 30, bottom_bar)

    command_bar:add_component(parent_size_matcher_component:new(0, 0, true, 0))
    command_bar:add_component(rectfill_component:new(pico8_colors.dark_gray))
    command_bar:add_component(linear_layouter_component:new(1, false, 0, 0, 0, 0, 2):set_minor_axis_fit_enabled(false))
    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 22, 22, command_bar), nil, ui_theme.icon.open_folder_add, function()
        -- create a new group
        anidraw:create_new_group()
    end)

    local timeline = ui_rect:new(0, 0, 0, 0, bottom_bar, parent_size_matcher_component:new(30, 0, 0, 0))
    local timeline_scroll_area = scroll_area_widget:new(ui_theme, 280, 200)
    timeline:add_component(timeline_scroll_area)
    timeline_scroll_area.scroll_content:add_component(
        linear_layouter_component:new(2, false, 0, 0, 0, 0, -1):set_minor_axis_expand_children_enabled(true))
    timeline_scroll_area.scroll_content:add_component {
        timeline_map = {},
        map_timeline = function(cmp, rect, instruction)
            if cmp.timeline_map[instruction] then
                local instruction_rect = cmp.timeline_map[instruction]
                if instruction_rect.parent ~= rect then
                    instruction_rect:set_parent(rect)
                end
                return
            end
            local instruction_rect = ui_rect:new(0, 0, rect.w, 20, rect)
            local fill = instruction_rect:add_component(rectfill_component:new(7))
            instruction_rect.mapped_instruction = instruction
            instruction_rect.mapped_instruction_mod_count = instruction.mod_count
            if instruction.icon then
                instruction_rect:add_component(sprite_component:new(instruction.icon, 4, 2))
            end

            local title_rect = ui_rect:new(0, 0, instruction_rect.w - 65, 22, instruction_rect)
            --title_rect:add_component(rectfill_component:new(4))
            title_rect.ignore_layouting = true
            title_rect:add_component {
                mouse_exit = function()
                    anidraw:highlight_instruction_remove(instruction)
                end,
                mouse_enter = function()
                    anidraw:highlight_instruction_add(instruction)
                end,
            }
            local title = title_rect:add_component(
                textfield_component:new(instruction.name or instruction:tostr(), pico8_colors.black, 4, 0,
                0, 25, 0, 0))
            function title:on_text_updated()
                instruction.name = self.text
                anidraw:notify_modified(instruction)
            end
            local function update()
                fill.is_selected = anidraw:is_selected(instruction)
                fill:set_fill(fill.is_selected and pico8_colors.blue or pico8_colors.white)
                title:set_text(instruction.name or instruction:tostr())
                if not instruction.is_group then return end
            end
            anidraw:subscribe_to(instruction, update)
            anidraw:add_object_selection_changed_listener(update)
            instruction_rect:add_component {
                on_set_parent = function()
                    anidraw:subscribe_to(instruction, update)
                    anidraw:add_object_selection_changed_listener(update)
                end,
                on_removed = function()
                    anidraw:unsubscribe_from(instruction)
                    anidraw:remove_object_selection_changed_listener(update)
                end,
                is_mouse_over = function(cmp, rect, mx, my)
                    if rect:is_top_hit() then
                        fill:set_fill(fill.is_selected and pico8_colors.blue or 15)
                        return
                    end
                    local hits = {}
                    local x,y = rect.parent:to_local(rect:to_world(mx, my))
                    rect:collect_hits(x, y, hits)
                    for i=1,#hits do
                        if hits[i].mapped_instruction and hits[i]~=rect then
                            fill:set_fill(fill.is_selected and pico8_colors.blue or 7)
                            return
                        end
                    end
                    fill:set_fill(fill.is_selected and pico8_colors.blue or 15)
                end,
                mouse_exit = function()
                    fill:set_fill(fill.is_selected and pico8_colors.blue or 7)
                end
            }
            if instruction.is_group then
                instruction_rect:add_component(linear_layouter_component:new(2, false, 20, 0, 2, 20, -1)
                :set_minor_axis_expand_children_enabled(true))
            end
            ui_theme:decorate_on_click(title_rect, function()
                anidraw:select_object(instruction)
            end)
            local delete_button = ui_rect:new(0, 0, 20, 20, instruction_rect, weighted_position_component:new(1, 0))
            delete_button.ignore_layouting = true
            ui_theme:decorate_button_skin(delete_button, nil, ui_theme.icon.close_x, function()
                anidraw:delete_instruction(instruction)
                anidraw:clear_canvas()
            end)
            local visibility_button = ui_rect:new(0, 0, 20, 20, instruction_rect, weighted_position_component:new(1, 0, 0, 20))
            visibility_button.ignore_layouting = true
            ui_theme:decorate_button_skin(visibility_button, nil, instruction.hidden and ui_theme.icon.eye_closed or ui_theme.icon.eye_open, function()
                instruction.hidden = not instruction.hidden
                visibility_button:trigger_on_components("set_sprite", instruction.hidden and ui_theme.icon.eye_closed or ui_theme.icon.eye_open)
                anidraw:clear_canvas()
            end)
            if instruction.is_group then
                -- foldable groups
                local fold_button = ui_rect:new(0, 0, 20, 20, instruction_rect, weighted_position_component:new(1, 0, 0, 40))
                fold_button.ignore_layouting = true
                ui_theme:decorate_button_skin(fold_button, nil, instruction.folded and ui_theme.icon.play or ui_theme.icon.triangle_down, function()
                    instruction.folded = not instruction.folded
                    fold_button:trigger_on_components("set_sprite", instruction.folded and ui_theme.icon.play or ui_theme.icon.triangle_down)
                end)
            end
            instruction_rect:add_component({
                was_pressed_down = function(cmp, rect, mx, my)
                    if not rect:is_top_hit() then
                        return
                    end
                    cmp.px, cmp.py = mx, my
                    cmp.active_drag = false
                end,
                was_released = function(cmp, rect, mx, my)
                    if not cmp.px or not cmp.active_drag then
                        return
                    end
                    cmp.px, cmp.py = nil, nil
                    local element = cmp.selected_element and cmp.selected_element.mapped_instruction
                    if element then
                        local group = element.group or anidraw
                        if cmp.insertion == "into" then
                            if element.add_instruction then
                                element:add_instruction(instruction)
                            end
                        elseif cmp.insertion == "before" then
                            group:insert_before(instruction, element)
                        elseif cmp.insertion == "after" then
                            group:insert_after(instruction, element)
                        end
                    end
                    cmp.mx, cmp.my = nil, nil
                end,
                is_pressed_down = function(cmp, rect, mx, my)
                    if not cmp.px then return end
                    if not cmp.active_drag then
                        local dx,dy = mx - cmp.px, my - cmp.py
                        if dx * dx + dy * dy > 10 * 10 then
                            cmp.active_drag = true
                        else 
                            return
                        end
                    end

                    cmp.mx, cmp.my = mx, my

                    local x, y = timeline_scroll_area.scroll_content.parent:to_local(rect:to_world(mx, my))
                    local hits = {}
                    timeline_scroll_area.scroll_content:collect_hits(x, y, hits)
                    cmp.selected_element = nil
                    for i = 1, #hits do
                        local hit = hits[i]
                        if hit.mapped_instruction and hit ~= instruction_rect then
                            cmp.selected_element = hit
                            local cx, cy = hit:to_local(rect:to_world(mx, my))
                            cmp.insertion = cy < 5 and "before" or cy > hit.h - 5 and "after" or "into"
                            break
                        end
                        if hit == instruction_rect then break end
                    end
                end,
                draw = function(cmp, rect)
                    if not cmp.px or not cmp.active_drag then return end
                    local x0, y0 = rect:to_world(0, 0)

                    local ax, ay = rect:to_world(cmp.px, cmp.py)
                    local bx, by = rect:to_world(cmp.mx, cmp.my)
                    local late_command = require "love-util.late_command"
                    late_command(function()
                        local sx, sy, sw, sh = love.graphics.getScissor()
                        love.graphics.setScissor()
                        love.graphics.setLineWidth(5)
                        love.graphics.setColor(0, 0, 0)
                        love.graphics.rectangle("line", x0, y0, rect.w, rect.h)
                        love.graphics.setColor(0,
                            cmp.selected_element and cmp.selected_element.mapped_instruction.is_group and .5 or 0, 0)
                        if cmp.selected_element then
                            local x, y = cmp.selected_element:to_world(0, 0)
                            if cmp.insertion == "before" then
                                love.graphics.rectangle("line", x, y, cmp.selected_element.w, 1)
                            elseif cmp.insertion == "after" then
                                love.graphics.rectangle("line", x, y + cmp.selected_element.h, cmp.selected_element.w, 1)
                            elseif cmp.selected_element.mapped_instruction.is_group then
                                love.graphics.rectangle("line", x, y, cmp.selected_element.w, cmp.selected_element.h)
                            end
                        end
                        love.graphics.line(ax, ay, bx, by)
                        love.graphics.setColor(1, 1, 1)
                        love.graphics.setLineWidth(1)
                        love.graphics.setScissor(sx, sy, sw, sh)
                    end)
                end
            })
            cmp.timeline_map[instruction] = instruction_rect
        end,
        update = function(cmp, rect)
            local map = {}
            local function update(map, owner, owner_rect)
                for i = 1, #owner.instructions do
                    local instruction = owner.instructions[i]
                    cmp:map_timeline(owner_rect, instruction)
                    if instruction.is_group and not instruction.folded then
                        update(map, instruction, cmp.timeline_map[instruction])
                    end
                    map[instruction] = true
                end
            end
            local function sort_lists(owner,owner_rect)
                local index_map = {}
                for i = 1, #owner.instructions do
                    local instruction = owner.instructions[i]
                    if instruction.is_group and not instruction.folded then
                        sort_lists(instruction, cmp.timeline_map[instruction])
                    end
                    
                    index_map[instruction] = i
                    --print(i, owner.instructions[i])
                end

                local prev_order = {}
                for i=1,#owner_rect.children do
                    local child = owner_rect.children[i]
                    prev_order[child] = i
                end
                local function sort(a, b)
                    local am,bm = a.mapped_instruction, b.mapped_instruction
                    if not am and not bm then return prev_order[a] < prev_order[b] end
                    if not am and bm then return true end
                    if am and not bm then return false end
                    --print(am,bm)
                    local ai, bi = index_map[am], index_map[bm]
                    return ai < bi
                end
                table.sort(owner_rect.children, sort)
            end
            update(map, anidraw, rect)
            for k, v in pairs(cmp.timeline_map) do
                if not map[k] then
                    cmp.timeline_map[k] = nil
                    v:remove()
                end
            end
            sort_lists(anidraw, rect)
        end
    }
end

return timeline_panel
