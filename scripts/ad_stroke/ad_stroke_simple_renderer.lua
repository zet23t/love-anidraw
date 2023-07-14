local ad_stroke_simple_renderer = require "love-util.class" "ad_stroke_simple_renderer"
function ad_stroke_simple_renderer:new(color)
    return self:create {
        color = {unpack(color or {1, 1, 1, 1})},
        min_size = 2,
        thickness = 5,
    }
end

local pressure_scale = 5
local min_size = 2
local function draw_strokes(output_data, t, min_size)
    for i = 2, #output_data do
        local a, b = output_data[i - 1], output_data[i]
        if b.t > t then break end
        local x1, y1 = unpack(a)
        local x2, y2 = unpack(b)
        --love.graphics.line(x1,y1,x2,y2)
        local dx, dy = x2 - x1, y2 - y1
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 1 then
            love.graphics.circle("fill", x2, y2, (a.pressure or .5) * pressure_scale + min_size)
        else
            local nx, ny = dx / dist, dy / dist
            local rad1 = (a.pressure or .5) * pressure_scale + min_size
            local rad2 = (b.pressure or .5) * pressure_scale + min_size
            local n = 0
            for d = 0, dist, 1 do
                local rad = rad1 + (rad2 - rad1) * d / dist
                love.graphics.circle("fill", x1 + nx * d, y1 + ny * d, rad)
            end
        end
    end
end

function ad_stroke_simple_renderer:draw(ad_stroke, output_data, t)
    local r,g,b,a = unpack(self.color)
    love.graphics.setColor(r,g,b,a)
    if #output_data == 1 then
        local a = output_data[1]
        local x1, y1 = unpack(a)
        love.graphics.circle("fill", x1, y1, (a.pressure or 500) * pressure_scale + min_size)
        love.graphics.setColor(1, 1, 1)
        return
    end
    draw_strokes(output_data, t, min_size)
    love.graphics.setColor(1, 1, 1)
end

return ad_stroke_simple_renderer
