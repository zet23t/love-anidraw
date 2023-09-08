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
            rect.w = rect.parent.w-20
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
            layer_rect = ui_rect:new(0, 0, 110, 25, self.layer_scroll_content)
            self.layer_rects[#self.layer_rects + 1] = layer_rect
            layer_rect.layer = layer
            layer_rect.layer_title = textfield_component:new(layer.name, 0, 0, 0, 0, 0, 0, 0.5)
            function layer_rect.layer_title:on_text_updated()
                layer.name = self.text
                anidraw:notify_modified(layer)
            end
            layer_rect.layer_title_rect = ui_rect:new(0, 0, 0, 0, layer_rect,
                parent_size_matcher_component:new(0, 30, 0, 25))
            layer_rect.layer_title_rect:add_component(rectfill_component:new(15))
            layer_rect.layer_title_rect:add_component(layer_rect.layer_title)
            layer_rect:add_component({
                layout_update_size = function(cmp, rect)
                    rect.w = rect.parent.w
                end
            })
        else
            layer_rects_to_remove[layer] = nil
        end

        layer_rect.y = (i - 1) * 25
    end

    self.layer_scroll_content.h = #layers * 25

    for layer, layer_rect in pairs(layer_rects_to_remove) do
        layer_rect:remove()
    end
end

return layer_panel
