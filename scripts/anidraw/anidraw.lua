local serialize = require "love-util.serialize"
local anidraw = require "anidraw.instance"

anidraw.tools = {}

anidraw.tools.pen = require "anidraw.tools.pen"

function anidraw:add_point(x, y, pressure)
    anidraw.current_action:add(x, y, pressure)
end

function anidraw:save()
    _G._saved_anidraw = serialize:serialize_to_string({
        instructions = self.instructions,
        selected_objects = self.selected_objects
    })
    local fp = assert(io.open("tmp.bin", "wb"))
    fp:write(_G._saved_anidraw)
    fp:close()
end

function anidraw:load()
    if _G._saved_anidraw then
        local new_anidraw = serialize:deserialize_from_string(_G._saved_anidraw)
        for k, v in pairs(new_anidraw) do
            self[k] = v
        end
    else
        local fp = assert(io.open("tmp.bin", "rb"))
        local data = fp:read("*a")
        fp:close()
        local new_anidraw = serialize:deserialize_from_string(data)
        for k, v in pairs(new_anidraw) do
            self[k] = v
        end
    end
end

function anidraw:finish()
    if not anidraw.current_action then return end
    self.instructions[#self.instructions + 1] = anidraw.current_action:finish()
    anidraw.current_action = nil
end

local on_selected_objects_changed_listeners = {};


function anidraw:trigger_selected_objects_changed()
    for i = 1, #on_selected_objects_changed_listeners do
        on_selected_objects_changed_listeners[i](self.selected_objects)
    end
end

function anidraw:select_object(object)
    self.selected_objects = { object }
    self:trigger_selected_objects_changed()
end

function anidraw:add_object_selection_changed_listener(listener)
    on_selected_objects_changed_listeners[#on_selected_objects_changed_listeners + 1] = listener
end

function anidraw:set_tool(tool)

end

function anidraw:delete_instruction(instruction)
    for i = 1, #self.instructions do
        if self.instructions[i] == instruction then
            table.remove(self.instructions, i)
            break
        end
    end
    for i = #self.selected_objects, 1, -1 do
        if self.selected_objects[i] == instruction then
            table.remove(self.selected_objects, i)
            self:trigger_selected_objects_changed()
            break
        end
    end
end

function anidraw:replay(replay_speed)
    self.playback_time = love.timer.getTime()
    self.playback_speed = replay_speed or 1
end

function anidraw:clear()
    self.instructions = {}
end

function anidraw:set_color(rgba)
    self.current_color = rgba
end

function anidraw:draw(draw_state, draw_temporary)
    if self.grid_enabled and draw_temporary then
        love.graphics.setColor(0, 0, 0, 0.1)
        for x = 0, self.canvas_size[1], self.grid_size do
            love.graphics.line(x, 0, x, self.canvas_size[2])
        end
        for y = 0, self.canvas_size[2], self.grid_size do
            love.graphics.line(0, y, self.canvas_size[1], y)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
    local t = (love.timer.getTime() - self.playback_time) * (self.playback_speed or 1)
    if #self.instructions > 0 then
        local start_time = self.instructions[1].start_time
        local remaining = t
        for i = 1, #self.instructions do
            local instruction = self.instructions[i]
            if remaining < instruction.finish_time then
                if draw_temporary then
                    instruction:draw(remaining)
                end
                break
            else
                if i > (draw_state or 0) then
                    draw_state = i
                    instruction:draw(remaining)
                end
            end
            remaining = remaining - (instruction.finish_time)
        end
    end
    if self.current_action and draw_temporary then
        self.current_action:draw(t)
    end
    return draw_state
end

return anidraw
