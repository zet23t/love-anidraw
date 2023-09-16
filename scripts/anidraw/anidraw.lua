local serialize                           = require "love-util.serialize"
local binary_serialize                    = require "love-util.binary_serialize"
local anidraw                             = require "anidraw.instance"
local bench                               = require "love-util.bench"
local draw_group                          = require "anidraw.draw_group"
local late_command                        = require "love-util.late_command"
local recent_files                        = require "config.recent_files"
local deep_copy                           = require "love-util.deep_copy"

local _mt_weak_keys                       = { __mode = "k" }
anidraw.tools                             = {}
anidraw.registered_notification_listeners = setmetatable({}, _mt_weak_keys)
anidraw.tools.pen                         = require "anidraw.tools.pen"
anidraw.highlighted_instructions          = {}
local editing_history                     = {}

function anidraw:add_point(x, y, pressure)
    anidraw.current_action:add(x, y, pressure)
end

function anidraw:notify_modified(object, record_undo)
    if record_undo then
        while #editing_history > 50 do
            table.remove(editing_history, 1)
            editing_history.step = editing_history.step - 1
        end
        local record = {
            data = deep_copy {
                instructions = self.instructions,
                selected_objects = self.selected_objects,
                layers = self.layers,
            },
        }
        if editing_history.step then
            for i = #editing_history, editing_history.step + 1, -1 do
                table.remove(editing_history, i)
            end
        end
        editing_history.step = (editing_history.step or 0) + 1
        editing_history[editing_history.step] = record
        print("undo recoreded with step ", editing_history.step)
    end

    local dict = anidraw.registered_notification_listeners[object]
    if not dict then return end
    for fn in pairs(dict) do
        fn(object)
    end
end

function anidraw:undo()
    if editing_history.step and editing_history.step > 1 then
        editing_history.step = editing_history.step - 1
        print("applying step ", editing_history.step)
        local record = deep_copy(editing_history[editing_history.step])
        local new_anidraw = record.data
        for k, v in pairs(new_anidraw) do
            self[k] = v
        end
        anidraw:clear_canvas()
        late_command(function()
            collectgarbage()
            anidraw:notify_modified(self)
        end)
    else
        print("no undo: ", editing_history.step)
    end
end

function anidraw:unsubscribe_from(object, fn)
    local dict = anidraw.registered_notification_listeners[object]
    if not dict then return end
    dict[fn] = nil
end

function anidraw:subscribe_to(object, fn)
    local dict = anidraw.registered_notification_listeners[object]
    if not dict then
        dict = setmetatable({}, _mt_weak_keys)
        anidraw.registered_notification_listeners[object] = dict
    end
    dict[fn] = true
end

function anidraw:save(path)
    self.file_path = path or self.file_path or _G._saved_anidraw_path or "default.ad"
    recent_files:add(self.file_path)

    path = self.file_path
    local done = bench:mark("bin-save")
    local data = table.concat(binary_serialize:serialize {
        instructions = self.instructions,
        selected_objects = self.selected_objects,
        layers = self.layers,
    })
    done()
    _G._saved_anidraw_bin = data

    local fp = assert(io.open(path, "wb"))
    fp:write(data)
    fp:close()
    print("Saved content to " .. path)
    bench:flush_info()
end

function anidraw:load(path)
    if not path then
        path = recent_files:get_all()[1]
    end
    self.file_path = path or self.file_path or _G._saved_anidraw_path or "default.ad"
    recent_files:add(self.file_path)

    _G._saved_anidraw_path = self.file_path

    local suc, err = pcall(function()
        local fp = assert(io.open(self.file_path, "rb"))
        local data = fp:read("*a")
        fp:close()
        local new_anidraw = binary_serialize:deserialize(data)
        _G._saved_anidraw_bin = data
        for k, v in pairs(new_anidraw) do
            self[k] = v
        end
        anidraw:clear_canvas()
        late_command(function()
            collectgarbage()
            print("Loaded content from " .. self.file_path)
            editing_history = {}
            anidraw:notify_modified(self, true)
        end)
    end)
    if not suc then
        print(err)
    end
end

function anidraw:finish()
    if not anidraw.current_action then return end
    local obj = anidraw.current_action:finish()
    self.instructions[#self.instructions + 1] = obj
    local so = self.selected_objects[1]
    if so and so.is_group then
        so:add_instruction(obj)
    end

    anidraw.current_action = nil

    anidraw:notify_modified(self, true)
end

local layer = require "anidraw.layer"

function anidraw:get_layers()
    local layers = self.layers
    if not layers then
        layers = {}
        self.layers = layers
    end
    return layers
end

function anidraw:new_layer()
    local layers = self:get_layers()
    local new_layer = layer:new()
    layers[#layers + 1] = new_layer
    self:notify_modified(layers)
    self:notify_modified(self, true)
    return new_layer
end

function anidraw:get_layer_index(layer)
    local layers = self:get_layers()
    for i = 1, #layers do
        if layers[i] == layer then
            return i
        end
    end
    return nil
end

function anidraw:set_layer_index(layer, index)
    local layers = self:get_layers()
    for i = 1, #layers do
        if layers[i] == layer then
            table.remove(layers, i)
            table.insert(layers, math.min(index, #layers + 1), layer)
            self:notify_modified(layers)
            self:notify_modified(self, true)
            break
        end
    end
end

function anidraw:remove_layer(layer)
    local layers = self:get_layers()
    for i = 1, #layers do
        if layers[i] == layer then
            table.remove(layers, i)

            for i = #self.instructions, 1, -1 do
                local instruction = self.instructions[i]
                instruction:layer_was_removed(layer)
            end

            self:notify_modified(layers)
            self:notify_modified(self, true)
            self:clear_canvas()
            break
        end
    end
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

function anidraw:highlight_instruction_remove(instruction)
    if not self.highlighted_instructions[instruction] then return end
    for i = 1, #self.highlighted_instructions do
        if self.highlighted_instructions[i] == instruction then
            table.remove(self.highlighted_instructions, i)
            self.highlighted_instructions[instruction] = nil
            return
        end
    end
end

function anidraw:highlight_instruction_add(instruction)
    if not self.highlighted_instructions[instruction] then
        self.highlighted_instructions[instruction] = true
        self.highlighted_instructions[#self.highlighted_instructions + 1] = instruction
    end
end

function anidraw:select_object(object)
    self.selected_objects = { object }
    self:trigger_selected_objects_changed()
end

function anidraw:is_selected(object)
    for i = 1, #self.selected_objects do
        if self.selected_objects[i] == object then
            return true
        end
    end
    return false
end

function anidraw:add_object_selection_changed_listener(listener)
    on_selected_objects_changed_listeners[#on_selected_objects_changed_listeners + 1] = listener
end

function anidraw:remove_object_selection_changed_listener(listener)
    for i = #on_selected_objects_changed_listeners, 1, -1 do
        if on_selected_objects_changed_listeners[i] == listener then
            table.remove(on_selected_objects_changed_listeners, i)
        end
    end
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
    self:notify_modified(self, true)
end

function anidraw:replay(replay_speed)
    self.playback_time = love.timer.getTime()
    self.playback_speed = replay_speed or 1
end

function anidraw:clear()
    self.instructions = {}
    self.highlighted_instructions = {}
    self.layers = {}
    editing_history = {}
    self.file_path = nil
    _G._saved_anidraw_path = nil

    self:notify_modified(self)
    self:clear_canvas()
end

function anidraw:set_color(rgba)
    self.current_color = rgba
end

function anidraw:draw(draw_state, draw_temporary, layer)
    assert(draw_state)
    if self.grid_enabled and draw_temporary and not layer then
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
                        instruction:draw(remaining, draw_state, draw_temporary, layer)
                    end
                    break
                else
                    if not draw_state[instruction] then
                        local is_done = instruction:draw(remaining, draw_state, draw_temporary, layer)
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

    if draw_temporary then
        for i = 1, #self.highlighted_instructions do
            local instruction = self.highlighted_instructions[i]
            if instruction.draw_highlight and not instruction.hidden then
                instruction:draw_highlight()
            end
        end
    end
end

return anidraw
