local anidraw = require "anidraw.instance"

anidraw.tools = {}

anidraw.tools.pen = require "anidraw.tools.pen"

function anidraw:add_point(x,y, pressure)
    anidraw.current_action:add(x,y, pressure)
end

function anidraw:finish()
    if not anidraw.current_action then return end
    self.instructions[#self.instructions+1] = anidraw.current_action:finish()
    anidraw.current_action = nil
    print "finish"
end

anidraw.instructions = {}

function anidraw:set_tool(tool)
    
end

function anidraw:delete_instruction(instruction)
    for i=1,#self.instructions do
        if self.instructions[i] == instruction then
            table.remove(self.instructions, i)
            return
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

function anidraw:draw()
    if self.grid_enabled then
        love.graphics.setColor(0,0,0,0.1)
        for x=0,love.graphics.getWidth(),self.grid_size do
            love.graphics.line(x, 0, x, love.graphics.getHeight())
        end
        for y=0,love.graphics.getHeight(),self.grid_size do
            love.graphics.line(0, y, love.graphics.getWidth(), y)
        end
        love.graphics.setColor(1,1,1,1)
    end
    local t = (love.timer.getTime() - self.playback_time) * (self.playback_speed or 1)
    if #self.instructions > 0 then 
        local start_time = self.instructions[1].start_time
        local remaining = t
        for i=1,#self.instructions do
            local instruction = self.instructions[i]
            instruction:draw(remaining)
            --print(i, remaining)
            remaining = remaining - (instruction.finish_time)
            if remaining < 0 then break end
        end
    end
    if self.current_action then
        self.current_action:draw(t)
    end
end

return anidraw