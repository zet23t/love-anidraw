local anidraw         = require "anidraw"
local menubar_widget  = require "love-ui.widget.menubar_widget"
local config_settings = require "config_settings"
local recent_files    = require "config.recent_files"

local load_dialog     = require "anidraw.ui.load"
local save_dialog     = require "anidraw.ui.save"

local main_menu_bar   = {}

function main_menu_bar:initialize(root_rect)
    root_rect:add_component(menubar_widget:new({
        File_1 = {
            New_1 = function() anidraw:clear() end,
            _2 = true,
            Revert_3 = function() anidraw:load() end,
            Load_4 = load_dialog(root_rect),
            ["Recent_5"] = {
                get_menu = function()
                    local recent_files = recent_files:get_all()
                    local menu = {}
                    for i = 1, #recent_files do
                        local path = recent_files[i]
                        local name = path:match("[^/]*$")
                        menu[name:gsub("_"," ").."_"..i] = function() anidraw:load(path) end
                    end
                    return menu
                end
            },
            Save_6 = function() anidraw:save() end,
            ["Save as_7"] = save_dialog(root_rect),
            _8 = true,
            Exit_9 = function() love.event.quit(0) end,
        }
    }, 1))
end

return main_menu_bar
