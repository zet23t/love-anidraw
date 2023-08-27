local serialize = require "love-util.serialize"
local binary_serialize = require "love-util.binary_serialize"
local anidraw = require "anidraw.instance"
local ui_theme = require "love-ui.ui_theme.ui_theme"
local bench = require "love-util.bench"

anidraw.tools = {}
anidraw.registered_notification_listeners = setmetatable({}, { __mode = "k" })
anidraw.tools.pen = require "anidraw.tools.pen"

function anidraw:add_point(x, y, pressure)
    anidraw.current_action:add(x, y, pressure)
end

function anidraw:notify_modified(object)
    local list = anidraw.registered_notification_listeners[object]
    if not list then return end
    for i = 1, #list do
        list[i](object)
    end
end

function anidraw:unsubscribe_from(object, fn)
    local list = anidraw.registered_notification_listeners[object]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == fn then
            table.remove(list, i)
        end
    end
end

function anidraw:subscribe_to(object, fn)
    local list = anidraw.registered_notification_listeners[object]
    if not list then
        list = {}
        anidraw.registered_notification_listeners[object] = list
    end
    list[#list + 1] = fn
end

function anidraw:save()
    local done = bench:mark("bin-save")
    local data = table.concat(binary_serialize:serialize{
        instructions = self.instructions,
        selected_objects = self.selected_objects,
    })
    done()
    _G._saved_anidraw_bin = data

    -- done = bench:mark("lua-save")
    -- local lua_data = serialize:serialize_to_string({
    --     instructions = self.instructions,
    --     selected_objects = self.selected_objects
    -- })
    -- done()
    -- bench:flush_info()
    -- print("Saved bin bytes: " .. #data .. " lua bytes: "..#_G._saved_anidraw)

    -- local fp = assert(io.open("tmp.bin", "wb"))
    -- fp:write(_G._saved_anidraw)
    -- fp:close()

    local fp = assert(io.open("tmp2.bin", "wb"))
    fp:write(data)
    fp:close()
end

function anidraw:load()
    if _G._saved_anidraw_bin then
        local done = bench:mark("bin-load")

        local new_anidraw = binary_serialize:deserialize(_G._saved_anidraw_bin)
        for k, v in pairs(new_anidraw) do
            self[k] = v
        end
        done()
        bench:flush_info()
    else
        local fp = assert(io.open("tmp2.bin", "rb"))
        local data = fp:read("*a")
        fp:close()
        local new_anidraw = binary_serialize:deserialize(data)
        _G._saved_anidraw_bin = data
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

local draw_group = require "love-util.class" "draw_group"
draw_group.is_group = true
draw_group.icon = ui_theme.icon.open_folder
draw_group.mod_count = 0
function draw_group:new(name)
    return self:create {
        name = name or "New Group",
        instructions = {},
        finish_time = 0,
    }
end

function draw_group:add_instruction(instruction)
    if instruction.group == self then return end

    if instruction.group then
        instruction.group:remove_instruction(instruction)
    else
        anidraw:delete_instruction(instruction)
    end
    instruction.group = self
    self.instructions[#self.instructions + 1] = instruction
    self:flag_modified()
    self:update_finish_time()
    anidraw:clear_canvas()
end

function draw_group:flag_modified()
    self.mod_count = self.mod_count + 1
    anidraw:notify_modified(self)
end

function draw_group:tostr()
    return self.name .. " [" .. #self.instructions .. "]"
end

function draw_group:remove_instruction(instruction)
    for i = 1, #self.instructions do
        if self.instructions[i] == instruction then
            table.remove(self.instructions, i)
            instruction.group = nil
            self:update_finish_time()
            self:flag_modified()
            break
        end
    end
end

function draw_group:update_finish_time()
    local prev_time = self.finish_time
    self.finish_time = 0
    for i = 1, #self.instructions do
        local instruction = self.instructions[i]
        if not instruction.hidden then
            self.finish_time = instruction.finish_time + self.finish_time
        end
    end
    if self.finish_time ~= prev_time then
        anidraw:trigger_selected_objects_changed()
    end
end

function draw_group:draw(t, draw_state, draw_temporary)
    self:update_finish_time()
    if #self.instructions > 0 then
        local start_time = self.instructions[1].start_time
        local remaining = t
        for i = 1, #self.instructions do
            local instruction = self.instructions[i]
            if not instruction.hidden then
                if remaining < instruction.finish_time then
                    if draw_temporary then
                        instruction:draw(remaining, draw_state, draw_temporary)
                    end
                    return false
                else --if not draw_temporary then
                    if not draw_state[instruction] then
                        local is_done = instruction:draw(remaining, draw_state, draw_temporary)
                        if not draw_temporary then
                            draw_state[instruction] = is_done or is_done == nil
                        end
                    end
                end
                remaining = remaining - (instruction.finish_time)
            end
        end
    end
    -- for i = 1, #self.instructions do
    --     self.instructions[i]:draw(t)
    -- end
    return true
end

local function prepare_insertion(self, instruction)
    self:add_instruction(instruction)
    for i = 1, #self.instructions do
        if self.instructions[i] == instruction then
            table.remove(self.instructions, i)
            break
        end
    end
end

function draw_group:insert_before(instruction, before)
    prepare_insertion(self, instruction)
    for i = 1, #self.instructions do
        if self.instructions[i] == before then
            table.insert(self.instructions, i, instruction)
            break
        end
    end
    self:flag_modified()
    anidraw:clear_canvas()
end

function draw_group:insert_after(instruction, after)
    prepare_insertion(self, instruction)
    for i = 1, #self.instructions do
        if self.instructions[i] == after then
            table.insert(self.instructions, i + 1, instruction)
            break
        end
    end
    self:flag_modified()
    anidraw:clear_canvas()

end

local function prepare_insertion(self, instruction)
    if instruction.group then
        instruction.group:remove_instruction(instruction)
    end
    for i = 1, #self.instructions do
        if self.instructions[i] == instruction then
            table.remove(self.instructions, i)
            break
        end
    end
end
function anidraw:insert_before(instruction, before)
    prepare_insertion(self, instruction)

    for i = 1, #self.instructions do
        if self.instructions[i] == before then
            table.insert(self.instructions, i, instruction)
            break
        end
    end
    anidraw:clear_canvas()
end

function anidraw:insert_after(instruction, after)
    prepare_insertion(self, instruction)

    for i = 1, #self.instructions do
        if self.instructions[i] == after then
            table.insert(self.instructions, i + 1, instruction)
            break
        end
    end
    anidraw:clear_canvas()
end

function anidraw:create_new_group(name)
    self:finish()
    local group = draw_group:new(name)
    self.instructions[#self.instructions + 1] = group
    self.selected_objects = { group }
    self:trigger_selected_objects_changed()
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
    if instruction.group then
        instruction.group:remove_instruction(instruction)
    end
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
    assert(draw_state)
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
            if not instruction.hidden then

                if remaining < instruction.finish_time then
                    if draw_temporary or instruction.is_group then
                        instruction:draw(remaining, draw_state, draw_temporary)
                    end
                    break
                else
                    if not draw_state[instruction] then
                        local is_done = instruction:draw(remaining, draw_state, draw_temporary)
                        if not draw_temporary then
                            draw_state[instruction] = is_done or is_done == nil
                        end
                    end
                end
                remaining = remaining - (instruction.finish_time)
            end
        end
    end
    if self.current_action and draw_temporary then
        self.current_action:draw(t)
    end
end

return anidraw
