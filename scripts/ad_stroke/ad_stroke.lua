local ad_stroke = require "love-util.class" "ad_stroke"
function ad_stroke:new()
    return self:create {
        input_data = {};
        output_data = {};
        processing_components = {};
        drawing_components = {};
        start_time = love.timer.getTime();
        finish_time = love.timer.getTime();
    }
end

function ad_stroke:run_components(components, fn, ...)
    for i=1,#components do
        local cmp = components[i]
        if not cmp[fn] then
            print("warning, no such function: ",fn,cmp)
                for k,v in pairs(cmp) do
                    print(k,v)
                end
        else
            cmp[fn](cmp, self, ...)
        end
    end
end

function ad_stroke:add_processor(cmp)
    self.processing_components[#self.processing_components+1] = cmp
    return self
end

function ad_stroke:add_renderer(cmp)
    self.drawing_components[#self.drawing_components+1] = cmp
    return self
end

function ad_stroke:run_processing()
    self.output_data = {}
    self:run_components(self.processing_components,"process", self.input_data, self.output_data)
end

function ad_stroke:add(x,y, pressure)
    local t = love.timer.getTime() - self.start_time
    self.input_data[#self.input_data+1] = { x, y, t = t, pressure = pressure}
    self.finish_time = t
    self:run_processing()
end

function ad_stroke:draw(t)
    self:run_components(self.drawing_components, "draw", self.output_data, t)
end

return ad_stroke