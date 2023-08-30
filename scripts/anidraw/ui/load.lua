local file_dialog_widget = require "love-ui.widget.file_dialog_widget"
local ui_theme           = require "love-ui.ui_theme.ui_theme"
local anidraw            = require "anidraw"

return
    function(root_rect)
        return function()
            local fd = file_dialog_widget:new(ui_theme, "Load from file", "Load")
            if anidraw.path then
                fd:set_path(anidraw.path)
            end
            fd:show(root_rect, function(self, path)
                if path then
                    anidraw:load(path)
                    anidraw:clear_canvas()
                end
            end)
        end
    end
