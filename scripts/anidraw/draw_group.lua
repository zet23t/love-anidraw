local ui_theme = require "love-ui.ui_theme.ui_theme"
local draw_group = require "love-util.class" "draw_group"
local anidraw = require "anidraw.instance"
local editables = require "anidraw.ui.editables"
draw_group.is_group = true
draw_group.icon = ui_theme.icon.open_folder
draw_group.mod_count = 0
draw_group.editables = editables:new()
    :toggle("hidden", "hidden", false)
    :toggle("locked", "locked", false)
    :options("animation_type", "animation type", {
        {"serial", "serial"},
        {"parallel", "parallel"},
    })

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

function draw_group:draw_highlight()
    for i=1,#self.instructions do
        local instruction = self.instructions[i]
        if not instruction.hidden and instruction.draw_highlight then
            instruction:draw_highlight() 
        end
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

return draw_group