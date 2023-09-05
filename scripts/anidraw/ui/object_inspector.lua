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
local add_slider                    = require "anidraw.ui.add_slider"
local textfield_component           = require "love-ui.components.generic.textfield_component"
local processors                    = require "anidraw.processors"


local object_inspector              = {}

function object_inspector:initialize(right_bar_rect)
    local object_inspector_rect = ui_rect:new(0, 0, right_bar_rect.w, 400, right_bar_rect)
    local object_inspector_scroll_area = scroll_area_widget:new(ui_theme, right_bar_rect.w - 16, 200)
    object_inspector_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    object_inspector_rect:add_component(object_inspector_scroll_area)
    object_inspector_rect:add_component(rectfill_component:new(6))
    local function add_component_inspector(parent, component, owner, list, list_index)
        local title = ui_rect:new(0, 0, parent.w, 20, parent, rectfill_component:new(15),
            text_component:new(component.name or (component.tostr and component:tostr()) or "<???>", 1, 0, 0, 0, 0, 0))
        if list then
            ui_theme:decorate_button_skin(ui_rect:new(title.w - 20, 0, 20, 20, title), nil,
                ui_theme.icon.close_x, function()
                    table.remove(list, list_index)
                    owner:run_processing()
                    anidraw:trigger_selected_objects_changed()
                    anidraw:clear_canvas()
                end)
        
            if list_index < #list then
                ui_theme:decorate_button_skin(ui_rect:new(title.w - 40, 0, 20, 20, title), nil,
                    ui_theme.icon.tiny_triangle_down,
                    function()
                        list[list_index], list[list_index + 1] = list[list_index + 1], list[list_index]
                        owner:run_processing()
                        anidraw:trigger_selected_objects_changed()
                        anidraw:clear_canvas()
                    end)
            end
        end
        if not component.editables then
            return
        end
        local function clear()
            if owner.run_processing then
                owner:run_processing()
            end
            anidraw:clear_canvas()
        end
        for i = 1, #component.editables do
            local info = component.editables[i]
            local key = info.key
            local value = component[key] or info.default
            local rect = ui_rect:new(0, 0, parent.w, 20, parent)
            if info.type == "number_slider" then
                add_slider((info.name or key) .. ": ", parent.w, 20, rect, info.min, info.max, value, function(value)
                    component[key] = value
                    anidraw:notify_modified(owner)
                    clear()
                end)
            elseif info.type == "toggle" then
                ui_theme:decorate_toggle_skin(rect, (info.name or key), value, function(state)
                    component[key] = state
                    anidraw:notify_modified(owner)
                    clear()
                    anidraw:notify_modified(owner)
                end)
            elseif info.type == "color" then
                rect:add_component(text_component:new((info.name or key) .. ":", 0, 0, 0, 0, 0, 0))
                local color_preview = ui_rect:new(parent.w - 100, 0, 100, 20, rect,
                    rectfill_component:new(value, 0))
                local color_menu = {}
                for i = 0, 15 do
                    local index = i
                    color_menu["color_" .. (i + 1)] = {
                        no_sub_menu = true,
                        draw = function(s, rect)
                            local x, y = rect:to_world()
                            require "love-ui.pico8api":rectfill(x, y, x + rect.w, y + rect.h, index)
                        end,
                        func = function()
                            component[key] = pico8_colors[index]
                            color_preview:trigger_on_components("set_fill", pico8_colors[index])
                            anidraw:notify_modified(owner)
                            anidraw:clear_canvas()
                        end
                    }
                end
                color_preview:add_component {
                    was_triggered = function()
                        local x, y = color_preview:to_world(0, 0)
                        ui_rect:new(x, y, 10, 10, rect:root()):add_component(menu_widget:new(color_menu, rect))
                    end
                }
            end
        end
    end
    local function component_add_function(object, component_list, class_list)
        return function(cmp, rect)
            local menu = {}
            for i = 1, #class_list do
                local class = class_list[i]
                menu[class:gsub("_", " ") .. "_" .. i] = function()
                    component_list[#component_list + 1] = require("ad_stroke." .. class):new()
                    object:run_processing()
                    anidraw:clear_canvas()
                    anidraw:trigger_selected_objects_changed()
                end
            end
            local x, y = rect:to_world(0, 0)
            ui_rect:new(x, y, 10, 10, rect:root()):add_component(menu_widget:new(menu, rect))
        end
    end

    anidraw:add_object_selection_changed_listener(function(list)
        object_inspector_scroll_area.scroll_content:remove_all_children()
        for i = 1, #list do
            local object = list[i]
            local object_rect = ui_rect:new(0, 0, object_inspector_scroll_area.scroll_content.w, 20,
                object_inspector_scroll_area.scroll_content)
            object_rect:add_component(rectfill_component:new(6))
            object_rect:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
            local tf = textfield_component:new(object.name or object:tostr(), 1, 0, 0, 0, 0, 0)
            ui_rect:new(0, 0, object_rect.w, 20, object_rect, rectfill_component:new(9), tf)
            function tf:on_text_updated()
                object.name = self.text
                anidraw:notify_modified(object)
            end

            if object.editables then
                add_component_inspector(object_rect, object, object)
            end

            if object.processing_components then
                ui_rect:new(0, 0, object_rect.w - 10, 2, object_rect, rectfill_component:new(0))
                ui_rect:new(0, 0, object_rect.w, 20, object_rect, rectfill_component:new(10),
                    text_component:new("Processors", 1))
                for i = 1, #object.processing_components do
                    add_component_inspector(object_rect, object.processing_components[i], object,
                        object.processing_components, i)
                    ui_rect:new(0, 0, object_rect.w - 10, 1, object_rect, rectfill_component:new(0))
                end
                ui_theme:decorate_button_skin(ui_rect:new(0, 0, object_rect.w, 20, object_rect), "Add processor", nil,
                    component_add_function(object, object.processing_components, processors))
                ui_rect:new(0, 0, 10, 10, object_rect)
            end
            if object.drawing_components then
                ui_rect:new(0, 0, object_rect.w - 10, 2, object_rect, rectfill_component:new(0))
                ui_rect:new(0, 0, object_rect.w, 20, object_rect, rectfill_component:new(10),
                    text_component:new("Renderers", 1))
                for i = 1, #object.drawing_components do
                    add_component_inspector(object_rect, object.drawing_components[i], object, object.drawing_components,
                        i)
                    ui_rect:new(0, 0, object_rect.w - 10, 1, object_rect, rectfill_component:new(0))
                end
                ui_theme:decorate_button_skin(ui_rect:new(0, 0, object_rect.w, 20, object_rect), "Add renderer", nil,
                    component_add_function(object, object.drawing_components, {
                        "ad_stroke_simple_renderer",
                        "ad_stroke_triangulator_renderer",
                    }))
            end
        end
    end)
end

return object_inspector
