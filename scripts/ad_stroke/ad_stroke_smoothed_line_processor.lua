local lerp3d = require "love-math.geom.3d.lerp3d"
local point_line_sqdist = require "love-math.geom.3d.point_line_sqdist"
local distance_squared = require "love-math.geom.3d.distance_squared"
local ad_stroke_smoothed_line_processor = require "love-util.class" "ad_stroke_smoothed_line_processor"
ad_stroke_smoothed_line_processor.editables = {
    {key = "straightness"; type = "number_slider"; name="straightness"; min = -1; max = 1; step = 0.01; default = 0.5},
}
function ad_stroke_smoothed_line_processor:new()
    return self:create {
        straightness = 0.5,
    }
end

function ad_stroke_smoothed_line_processor:process(ad_stroke, input_data, output_data)
    local vel = 0
    if #output_data > 0 then
        input_data = output_data
    end
    local first_point = input_data[1]
    local last_point = input_data[#input_data]
    local t = self.straightness
    for i=2,#input_data - 1 do
        local p = input_data[i]
        local x,y = p[1], p[2]
        local sqd, lx,ly = point_line_sqdist(x,y,0,first_point[1], first_point[2], 0, last_point[1], last_point[2], 0)
        x,y = lerp3d(t, x,y,0, lx,ly,0)
        local index = input_data == output_data and i or (#output_data + 1)
        output_data[index] = {x,y, t = p.t, pressure = (p.pressure or 500) / (vel * 0.0000 + 1)}
    end
end

return ad_stroke_smoothed_line_processor