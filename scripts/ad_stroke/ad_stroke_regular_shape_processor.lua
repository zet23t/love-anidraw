local lerp3d                                = require "love-math.geom.3d.lerp3d"
local point_line_sqdist                     = require "love-math.geom.3d.point_line_sqdist"
local distance_squared                      = require "love-math.geom.3d.distance_squared"
local ad_stroke_regular_shape_processor     = require "love-util.class" "ad_stroke_regular_shape_processor"
local radians_delta                         = require "love-math.geom.2d.radians_delta"
local dot                                   = require "love-math.geom.2d.dot"
local vector_angle                          = require "love-math.geom.3d.vector_angle"
ad_stroke_regular_shape_processor.editables = {
    { key = "corners",      type = "number_slider", name = "corners",      min = 3,  max = 16, step = 1,    default = 4 },
    { key = "straightness", type = "number_slider", name = "straightness", min = -1, max = 1,  step = 0.01, default = 0.5 },
    { key = "rotation",     type = "number_slider", name = "rotation",     min = 0,  max = 1,  step = 0.01, default = 0.5 },
}
ad_stroke_regular_shape_processor.rotation  = 0
function ad_stroke_regular_shape_processor:new()
    return self:create {
        straightness = 0.5,
        corners = 4,
        rotation = 0,
    }
end

local function point_at(distance, points)
    local total_length = 0
    for i = 2, #points do
        local p, q = points[i], points[i - 1]
        local px, py, qx, qy = p[1], p[2], q[1], q[2]
        local length = distance_squared(qx, qy, 0, px, py, 0) ^ .5
        if total_length + length > distance then
            local t = (distance - total_length) / length
            return { lerp3d(t, px, py, 0, qx, qy, 0) }, i, t
        end
        total_length = total_length + length
    end
    return points[#points], #points - 1, 1
end

function ad_stroke_regular_shape_processor:process(ad_stroke, input_data, output_data)
    local total_length = 0
    if #output_data > 0 then
        input_data = output_data
    end
    for i = 2, #input_data do
        local p, q = input_data[i], input_data[i - 1]
        local px, py, qx, qy = p[1], p[2], q[1], q[2]
        total_length = total_length + distance_squared(qx, qy, 0, px, py, 0) ^ .5
    end
    local step_dist = 150
    local prev_dist
    local corners = {
        { index = 1, pqdist = 0, unpack(input_data[1]) }
    }
    --print">>>"
    for dist = 0, total_length - step_dist, step_dist / 6 do
        local p, index_p = point_at(dist, input_data)
        local q, index_q = point_at(dist + step_dist, input_data)
        local pqdist = distance_squared(p[1], p[2], 0, q[1], q[2], 0) ^ .5
        if pqdist < step_dist * 0.95 then
            local c = { 0, 128, 255 }
            --      print(dist, pqdist)
            local max_dist = 0
            local max_index = index_p
            for i = index_p + 1, index_q - 1 do
                local point = input_data[i]
                local dsq_p = distance_squared(point[1], point[2], 0, p[1], p[2], 0) ^ .5
                local dsq_q = distance_squared(point[1], point[2], 0, q[1], q[2], 0) ^ .5
                local d = dsq_p + dsq_q
                if d > max_dist then
                    max_dist = d
                    max_index = i
                end
            end
            local np = { unpack(input_data[max_index]) } -- point_at(dist + step_dist / 2, input_data)
            local angle = vector_angle(np[1], np[2], 0, p[1], p[2], 0, q[1], q[2], 0)
            if angle < math.pi * .75 then
                np.dist = dist + step_dist / 2
                np.pqdist = pqdist
                np.index = max_index
                local pc = corners[#corners]
                if not pc or distance_squared(np[1], np[2], 0, pc[1], pc[2], 0) ^ .5 > step_dist * .5 then
                    c[1] = 255
                    corners[#corners + 1] = np
                elseif pc.pqdist > pqdist then
                    c[2] = 255
                    corners[#corners] = np
                end
                ad_stroke:add_debug_draw(function()
                    love.graphics.setColor(unpack(c))
                    love.graphics.circle("fill", np[1], np[2], 5)
                    -- love.graphics.line(p[1], p[2], q[1], q[2])
                    -- local point = input_data[max_index]
                    -- love.graphics.line(p[1] * .5 + q[1] * .5, p[2] * .5 + q[2] * .5, point[1], point[2])
                    -- for i = index_p + 1, index_q do
                    --     local a, b = input_data[i - 1], input_data[i]
                    --     love.graphics.line(a[1], a[2], b[1], b[2])
                    -- end
                end)
            end
        end
        prev_dist = pqdist
    end
    corners[#corners + 1] = { index = #input_data, pqdist = 0, unpack(input_data[1]) }

    local new_output = {}
    --for i=1,#output_data do output_data[i] = nil end

    local t = self.straightness
    --output_data[#output_data + 1] = { input_data[1][1], input_data[1][2], t = 0, pressure = .15 }
    for i = 2, #corners do
        local ax, ay = unpack(corners[i - 1])
        local bx, by = unpack(corners[i])
        for j = corners[i - 1].index, corners[i].index do
            local p = input_data[j]
            local x, y = p[1], p[2]
            local index = input_data == output_data and j or (#output_data + 1)
            local sqd, lx, ly = point_line_sqdist(x, y, 0, ax, ay, 0, bx, by, 0)
            x, y = lerp3d(t, x, y, 0, lx, ly, 0)
            new_output[index] = { x, y, t = p.t, pressure = (p.pressure or 500) }
        end
    end

    for i = 1, #new_output do
        output_data[i] = new_output[i]
    end
    --output_data[#output_data + 1] = { input_data[#input_data][1], input_data[#input_data][2], t = #corners * .2,
    --   pressure = .15 }
end

function ad_stroke_regular_shape_processor:processx(ad_stroke, input_data, output_data)
    local vel = 0
    if #output_data > 0 then
        input_data = output_data
    end
    local first_point = input_data[1]
    local last_point = input_data[#input_data]
    local t = self.straightness
    local min_x, min_y, max_x, max_y
    for i = 1, #input_data do
        local p = input_data[i]
        local x, y = p[1], p[2]
        min_x = math.min(min_x or x, x)
        min_y = math.min(min_y or y, y)
        max_x = math.max(max_x or x, x)
        max_y = math.max(max_y or y, y)
    end

    local cx, cy = (min_x + max_x) / 2, (min_y + max_y) / 2
    local size_x, size_y = max_x - min_x, max_y - min_y
    local radius = distance_squared(cx, cy, 0, first_point[1], first_point[2], 0) ^ .5
    local angle_step = math.pi * 2 / self.corners
    local prev_corner = 0
    local corner_data = {}
    local n_side = #input_data / math.floor(self.corners)
    local pos = 0
    local offset
    local rot = self.rotation * math.pi * 2 / math.floor(self.corners)
    local stroke_turn_dir = 0
    local prev_angle
    for i = 1, #input_data do
        local angle = math.atan2(input_data[i][2] - cy, input_data[i][1] - cx)
        local diff = radians_delta(angle, prev_angle or angle)
        stroke_turn_dir = stroke_turn_dir + diff
        prev_angle = angle
    end
    for corner = 0, self.corners - 1 do
        local c = corner
        if stroke_turn_dir < 0 then
            c = self.corners - corner - 1
        end
        local min_angle = c * angle_step + rot
        local max_angle = min_angle + angle_step * (stroke_turn_dir < 0 and -1 or 1)
        local ax, ay = math.cos(min_angle) * radius + cx, math.sin(min_angle) * radius + cy
        local bx, by = math.cos(max_angle) * radius + cx, math.sin(max_angle) * radius + cy
        for i = 1, n_side do
            local lx, ly = lerp3d((i - 1) / (n_side - 1), ax, ay, 0, bx, by, 0)
            pos = pos + 1
            if not offset then
                local nearest_index
                local nearest_dist_sq
                for k = 1, #input_data do
                    local p = input_data[k]
                    local sqd = distance_squared(p[1], p[2], 0, lx, ly, 0)
                    if not nearest_dist_sq or sqd < nearest_dist_sq then
                        nearest_dist_sq = sqd
                        nearest_index = k
                    end
                end
                offset = nearest_index - 1
            end
            local idx = (pos - 1 + offset) % #input_data + 1
            local p = input_data[idx]
            local x, y = p[1], p[2]
            x, y = lerp3d(t, x, y, 0, lx, ly, 0)

            local index = input_data == output_data and idx or (#output_data + 1)
            output_data[index] = { x, y, t = p.t, pressure = (p.pressure or 500) / (vel * 0.0000 + 1) }
        end
    end
    -- for i=1,#input_data do
    --     local p = input_data[i]
    --     local x,y = p[1], p[2]
    --     local nsqd,nx,ny,ncorner
    --     for corner=0,self.corners - 1 do
    --         local min_angle = corner * angle_step
    --         local max_angle = min_angle + angle_step

    --         local ax,ay = math.cos(min_angle) * radius + cx, math.sin(min_angle) * radius + cy
    --         local bx,by = math.cos(max_angle) * radius + cx, math.sin(max_angle) * radius + cy
    --         local sqd, lx,ly = point_line_sqdist(x,y,0,ax, ay, 0, bx, by, 0)
    --         if not nsqd or nsqd > sqd then
    --             nsqd = sqd
    --             nx,ny = lx,ly
    --             ncorner = corner
    --         end
    --     end
    --     corner_data[i] = {
    --         corner = ncorner,
    --     }
    --     --x,y = lerp3d(t, x,y,0, nx,ny,0)

    --     -- local index = input_data == output_data and i or (#output_data + 1)
    --     -- output_data[index] = {x,y, t = p.t, pressure = (p.pressure or 500) / (vel * 0.0000 + 1)}
    -- end
    -- local prev_corner = corner_data[1].corner
    -- local corner_counter = {}
    -- for i=1,#corner_data do
    --     local corner_info = corner_data[i]
    --     local count = corner_counter[corner_info.corner] or 0
    --     corner_info.count = count
    --     corner_counter[corner_info.corner] = count + 1
    -- end
    -- for i=1,#input_data do
    --     local p = input_data[i]
    --     local x,y = p[1], p[2]
    --     local corner_info = corner_data[i]
    --     local min_angle = corner_info.corner * angle_step
    --     local max_angle = min_angle + angle_step
    --     local ax,ay = math.cos(min_angle) * radius + cx, math.sin(min_angle) * radius + cy
    --     local bx,by = math.cos(max_angle) * radius + cx, math.sin(max_angle) * radius + cy
    --     local t = corner_info.count / (corner_counter[corner_info.corner] - 1)
    --     local nx,ny = lerp3d(t, ax,ay,0, bx,by,0)
    --     x,y = lerp3d(self.straightness, x,y,0, nx,ny,0)
    --     local index = input_data == output_data and i or (#output_data + 1)
    --     output_data[index] = {x,y, t = p.t, pressure = (p.pressure or 500) / (vel * 0.0000 + 1)}
    -- end
end

return ad_stroke_regular_shape_processor
