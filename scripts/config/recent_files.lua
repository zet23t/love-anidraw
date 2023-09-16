local config_settings = require "config_settings"
local max_files = 10
local recent_files = {}

function recent_files:get_all()
    return config_settings:get("recent_files", {})
end

function recent_files:add(path)
    local recent_files = self:get_all()
    for i = 1, #recent_files do
        if recent_files[i] == path then
            table.remove(recent_files, i)
            break
        end
    end
    table.insert(recent_files, 1, path)
    
    -- truncate
    while #recent_files > max_files do
        table.remove(recent_files)
    end
    config_settings:set("recent_files", recent_files)
end

return recent_files