local distance_squared = require "love-math.geom.3d.distance_squared"
local ad_stroke_direct_processor = require "love-util.class" "ad_stroke_direct_processor"
function ad_stroke_direct_processor:new()
    return self:create {}
end

function ad_stroke_direct_processor:process(ad_stroke, input_data, output_data)
    local lx,ly
    local vel = 0
    local lt = 0
    for i=1,#input_data do
        local p = input_data[i]
        local x,y = p[1], p[2]
        local sqd = distance_squared(x,y,0,lx,ly,0)
        if not lx or sqd > 9 then
            lx,ly = x,y
            local d = sqd ^ .5
            local dt = p.t - lt
            lt = p.t
            if dt > 0 then
                local v = d / dt
                vel = vel * .8 + v * .2
            end
            output_data[#output_data+1] = {x,y, t = p.t, pressure = (p.pressure or 500) / (vel * 0.0000 + 1)}
        end

    end
end

return ad_stroke_direct_processor