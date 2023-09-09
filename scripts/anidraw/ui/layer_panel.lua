local textfield_component           = require "love-ui.components.generic.textfield_component"
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
local sprite_component              = require "love-ui.components.generic.sprite_component"
local late_command                  = require "love-util.late_command"



local layer_panel = {}


function layer_panel:initialize(parent_rect)
    local command_bar = ui_rect:new(0, 0, 0, 30, parent_rect, parent_size_matcher_component:new(0, 0, true, 0))
    command_bar:add_component(linear_layouter_component:new(1, true))
    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 22, 22, command_bar), nil, ui_theme.icon.add_layer,
        function()
            anidraw:new_layer()
        end)
    local layer_list = ui_rect:new(0, 0, 0, 0, parent_rect, parent_size_matcher_component:new(30, 0, 0, 0))
    local layer_scroll_area = scroll_area_widget:new(ui_theme, 180, 200)
    --fdasfsadlayer_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    layer_list:add_component(layer_scroll_area)
    layer_list:add_component(parent_size_matcher_component:new(25, 0, 0, 0))
    layer_scroll_area.scroll_content:add_component({
        layout_update_size = function(cmp, rect)
            rect.w = rect.parent.w - 20
        end
    })

    self.command_bar = command_bar
    self.layer_list = layer_list
    self.layer_scroll_area = layer_scroll_area
    self.layer_scroll_content = layer_scroll_area.scroll_content
    self.layer_rects = {}

    local function on_layer_updated()
        local layers = anidraw:get_layers()
        anidraw:subscribe_to(layers, function(layers) self:update_layers(layers) end)
        self:update_layers(layers)
    end

    -- need the reference because subscribers are weakly referenced
    self.on_layer_updated = on_layer_updated
    anidraw:subscribe_to(anidraw, on_layer_updated)
    on_layer_updated()
end

function layer_panel:update_layers(layers)
    local layer_rects_to_remove = {}
    for i = 1, #self.layer_rects do
        local layer_rect = self.layer_rects[i]
        layer_rects_to_remove[layer_rect.layer] = layer_rect
    end

    for i = 1, #layers do
        local layer = layers[i]
        local layer_rect = layer_rects_to_remove[layer]
        if not layer_rect then
            layer_rect = ui_rect:new(0, 0, 110, 22, self.layer_scroll_content)
            self.layer_rects[#self.layer_rects + 1] = layer_rect
            layer_rect.layer = layer
            layer_rect.layer_title = textfield_component:new(layer.name, 0, 0, 0, 0, 0, 0, 0.5)
            function layer_rect.layer_title:on_text_updated()
                layer.name = self.text
                anidraw:notify_modified(layer)
            end

            layer_rect.delete_button = ui_rect:new(0, 0, 22, 22, layer_rect,
                parent_size_matcher_component:new(0, 22, true, true))
            ui_theme:decorate_button_skin(layer_rect.delete_button, nil, ui_theme.icon.close_x,
                function()
                    anidraw:remove_layer(layer)
                end)
            layer_rect.layer_title_rect = ui_rect:new(0, 0, 0, 0, layer_rect,
                parent_size_matcher_component:new(0, 22 * 2, 0, 25))
            layer_rect.layer_title_rect:add_component(rectfill_component:new(15))
            layer_rect.layer_title_rect:add_component(layer_rect.layer_title)
            layer_rect:add_component({
                layout_update_size = function(cmp, rect)
                    rect.w = rect.parent.w
                end
            })

            layer_rect.handle_rect = ui_rect:new(0, 0, 22, 22, layer_rect,
                parent_size_matcher_component:new(0, 0, true, true))
            local dot_sprite = layer_rect.handle_rect:add_component(sprite_component:new(ui_theme.icon.circle_dot_dark, 3,
                3))
            layer_rect.handle_rect:add_component({
                update_icon = function(cmp, rect)
                    local active = cmp.is_inside or cmp.pressed
                    dot_sprite:set_sprite(active and ui_theme.icon.circle_dot_light or ui_theme.icon.circle_dot_dark)
                end,
                mouse_enter = function(cmp, rect)
                    cmp.is_inside = true
                    cmp:update_icon(rect)
                end,
                mouse_exit = function(cmp, rect)
                    cmp.is_inside = false
                    cmp:update_icon(rect)
                end,
                was_pressed_down = function(cmp, rect)
                    cmp.pressed = true
                    cmp:update_icon(rect)
                end,
                was_released = function(cmp, rect)
                    if cmp.layer_rect_over and cmp.layer_rect_over.layer ~= layer then
                        local relative_layer = cmp.layer_rect_over.layer
                        local layer_index = anidraw:get_layer_index(relative_layer)
                        if cmp.insert_before then
                            layer_index = math.max(layer_index - 1, 1)
                        end
                        anidraw:set_layer_index(layer, layer_index)
                    end
                    cmp.pressed = false
                    cmp:update_icon(rect)
                end,
                is_mouse_over = function(cmp, rect, mx, my)
                    cmp.mx, cmp.my = mx, my
                end,
                draw = function(cmp, rect)
                    if cmp.pressed then
                        local cx, cy = rect:to_world(rect:get_size(0.5))
                        local mx, my = love.mouse.getPosition()
                        local lx, ly = self.layer_scroll_content.parent:to_local(mx, my)
                        local hits = {}
                        self.layer_scroll_content:collect_hits(lx, ly, hits)
                        cmp.layer_rect_over = nil

                        for i = 1, #hits do
                            local hit = hits[i]
                            if hit.layer then
                                local lx, ly = hit:to_local(mx, my)
                                local before = ly < 5
                                local after = ly > hit.h - 5
                                if before or after then
                                    cmp.layer_rect_over = hit
                                    cmp.insert_before = before
                                end
                            end
                        end

                        late_command(
                            function()
                                love.graphics.setColor(pico8_colors[0])
                                if cmp.layer_rect_over then
                                    local hit = cmp.layer_rect_over
                                    local before = cmp.insert_before
                                    local wx, wy = hit:to_world(0, before and -3 or hit.h - 3)
                                    love.graphics.rectangle("fill", wx, wy, hit.w, 6)
                                end
                                love.graphics.line(cx, cy, mx, my)
                                love.graphics.setColor(1, 1, 1, 1)
                            end
                        )
                    end
                end,
            })
        else
            layer_rects_to_remove[layer] = nil
        end

        layer_rect.y = (i - 1) * 22
    end

    self.layer_scroll_content.h = #layers * 25

    for layer, layer_rect in pairs(layer_rects_to_remove) do
        layer_rect:remove()
    end
end

return layer_panel
