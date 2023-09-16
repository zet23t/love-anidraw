local binary_serialize = require "love-util.binary_serialize"

local config_file = "config_settings.dat"
local config_path = love.filesystem.getSaveDirectory() .. "/" .. config_file
local config_settings = {}
local data

local function get_data()
    if not data then
        local path = config_file
        if love.filesystem.getInfo(path) then
            local content = love.filesystem.read(path)
            data = binary_serialize:deserialize(content)
        else
            print("no config file found",path)
            data = {}
        end
    end
    return data
end

function config_settings:get(key, default)
    local data = get_data()
    local value = data[key]
    if value == nil then return default end
    return value
end

function config_settings:set(key, value)
    local data = get_data()
    data[key] = value
    local path = config_path
    
    local content = table.concat(binary_serialize:serialize(data))
    love.filesystem.write(config_file, content)
    print("saved config size: " .. #content)
end

return config_settings