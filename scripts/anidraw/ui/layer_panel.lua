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



local layer_panel = {}

function layer_panel:initialize(parent_rect)
    local command_bar = ui_rect:new(0,0,0,30,parent_rect, parent_size_matcher_component:new(0,0,true,0))
    command_bar:add_component(linear_layouter_component:new(1,true))
    ui_theme:decorate_button_skin(ui_rect:new(0,0,22,22,command_bar), nil, ui_theme.icon.big_blue_dash, function() end)
    local layer_list = ui_rect:new(0, 0, 0, 0, parent_rect, parent_size_matcher_component:new(30, 0, 0, 0))
    local layer_scroll_area = scroll_area_widget:new(ui_theme, 180, 200)
    layer_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    layer_list:add_component(layer_scroll_area)
    
end

return layer_panel