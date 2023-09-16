local editables                     = require "anidraw.ui.editables"
local anidraw                       = require "anidraw.instance"
local distance_squared              = require "love-math.geom.3d.distance_squared"

local ad_stroke_simple_renderer     = require "love-util.class" "ad_stroke_simple_renderer"
ad_stroke_simple_renderer.editables = editables:new()
    :layer("layer", "Layer")
    :color("color", "Color", { 1, 1, 1, 1 })
    :number_slider("min_size", "Min size", -50, 50, 1, 2)
    :number_slider("thickness", "Pressure size", -50, 50, 1, 5)


function ad_stroke_simple_renderer:new(color, size, min_size)
    return self:create {
        color = { unpack(color or { 1, 1, 1, 1 }) },
        min_size = min_size or 2,
        thickness = size or 5,
    }
end

local pressure_scale = 5
local min_size = 2
local function draw_strokes(output_data, t, min_size, thickness)
    local a = output_data[1]
    local x1, y1 = unpack(a)
    local rad = (a.pressure or 500) * pressure_scale + min_size
    if rad > 0 then
        -- love.graphics.circle("line", x1, y1, rad)
        love.graphics.circle("fill", x1, y1, rad)
    end
    if #output_data == 1 then
        return
    end
    -- for i = 2, #output_data do
    --     local a, b = output_data[i - 1], output_data[i]
    --     love.graphics.line(a[1], a[2], b[1], b[2])
    -- end
    local pnx, pny
    local last
    for i = 1, #output_data do
        local b = output_data[i]
        local a = output_data[i - 1] or b
        local c = output_data[i + 1] or b

        last = b
        if b.t > t then break end

        local x0, y0 = unpack(a)
        local x1, y1 = unpack(b)
        local x2, y2 = unpack(c)

        local dx0, dy0 = x1 - x0, y1 - y0
        local dx2, dy2 = x2 - x1, y2 - y1
        local len0 = math.sqrt(dx0 * dx0 + dy0 * dy0)
        local len1 = math.sqrt(dx2 * dx2 + dy2 * dy2)

        local nx0, ny0, nx1, ny1
        if len0 > 0 then
            nx0, ny0 = dx0 / len0, dy0 / len0
        end
        if len1 > 0 then
            nx1, ny1 = dx2 / len1, dy2 / len1
        end
        if nx0 then
            nx0, ny0 = nx0 or nx1, ny0 or ny1
            nx1, ny1 = nx1 or nx0, ny1 or ny0
            local dot = nx0 * nx1 + ny0 * ny1
            local rad0 = (a.pressure or .5) * thickness + min_size
            local rad1 = (b.pressure or .5) * thickness + min_size

            if dot < .85 then
                local rad = (b.pressure or .5) * thickness + min_size
                love.graphics.circle("fill", x1, y1, rad)
                if pnx then
                    local pax, pay = x0 + pny * rad0, y0 - pnx * rad0
                    local pbx, pby = x1 + pny * rad1, y1 - pnx * rad1
                    local pcx, pcy = x1 - pny * rad1, y1 + pnx * rad1
                    local pdx, pdy = x0 - pny * rad0, y0 + pnx * rad0
                    love.graphics.line(pax, pay, pbx, pby)
                    love.graphics.line(pcx, pcy, pdx, pdy)
                    love.graphics.polygon("fill", pax, pay, pbx, pby, pcx, pcy, pdx, pdy)
                end
                pnx, pny = nx1, ny1
            else
                local dx, dy = x2 - x0, y2 - y0
                local dist = math.sqrt(dx * dx + dy * dy)
                local nx, ny = dx / dist, dy / dist
                local nx0, ny0 = pnx or nx0, pny or ny0
                local pax, pay = x0 + ny0 * rad0, y0 - nx0 * rad0
                local pbx, pby = x1 + ny * rad1, y1 - nx * rad1
                local pcx, pcy = x1 - ny * rad1, y1 + nx * rad1
                local pdx, pdy = x0 - ny0 * rad0, y0 + nx0 * rad0
                -- love.graphics.line(pax, pay, pbx, pby)
                -- love.graphics.line(pcx, pcy, pdx, pdy)
                love.graphics.polygon("fill", pax, pay, pbx, pby, pcx, pcy, pdx, pdy)

                pnx, pny = nx, ny
            end
        end
    end
    local a = last
    local x1, y1 = unpack(a)
    local rad = (a.pressure or 500) * pressure_scale + min_size
    if rad > 0 then
        -- love.graphics.circle("line", x1, y1, rad)
        love.graphics.circle("fill", x1, y1, rad)
    end


    -- local left, right = {}, {}

    -- for i = 2, #output_data do
    --     local b, c = output_data[i - 1], output_data[i]

    --     if c.t > t then break end

    --     local d = output_data[i + 1] or c
    --     local a = output_data[i - 2] or b


    --     local x0, y0 = unpack(a)
    --     local x1, y1 = unpack(b)
    --     local x2, y2 = unpack(c)
    --     local x3, y3 = unpack(d)
    --     --love.graphics.line(x1,y1,x2,y2)
    --     local dx, dy = x2 - x1, y2 - y1
    --     local dist = math.sqrt(dx * dx + dy * dy)
    --     if dist < 1 then
    --         local rad = (b.pressure or .5) * thickness + min_size
    --         if rad > 0 then
                -- love.graphics.circle("line", x2, y2, rad)
    --             -- love.graphics.circle("fill", x2, y2, rad)
    --         end
    --     else
    --         local rad1 = (b.pressure or .5) * thickness + min_size
    --         local rad2 = (c.pressure or .5) * thickness + min_size

    --         local dx2,dy2 = x3 - x1, y3 - y1
    --         local dx0,dy0 = x2 - x0, y2 - y0
    --         local dist2 = math.sqrt(dx2 * dx2 + dy2 * dy2)
    --         local dist0 = math.sqrt(dx0 * dx0 + dy0 * dy0)

    --         local nx, ny = dx / dist, dy / dist
    --         local nx2, ny2 = dx2 / dist2, dy2 / dist2

    --         local nx0, ny0 = dx0 / dist0, dy0 / dist0

    --         local pax1, pay1 = x1 + ny0 * rad1, y1 - nx0 * rad1
    --         local pax2, pay2 = x1 - ny0 * rad1, y1 + nx0 * rad1
    --         local pbx1, pby1 = x2 + ny2 * rad2, y2 - nx2 * rad2
    --         local pbx2, pby2 = x2 - ny2 * rad2, y2 + nx2 * rad2

    --         if #left == 0 or ((distance_squared(pax1, pay1, 0, left[#left][1], left[#left][2], 0) > 1)
    --             and (distance_squared(pax2, pay2, 0, right[#right][1], right[#right][2], 0) > 1))
    --         then
    --             left[#left + 1] = {pax1, pay1, x1, y1}
    --             right[#right+1] = {pax2, pay2, x1, y1}
    --         end


    --         -- love.graphics.line(x1, y1, x2, y2)
    --         -- love.graphics.line(x2 + ny0 * rad1, y2 - nx0 * rad1, x2, y2)
    --         -- love.graphics.line(x2 + ny2 * rad1, y2 - nx2 * rad1, x2, y2)
    --         -- love.graphics.line(pax1, pay1, pax2, pay2)


    --         -- local nx, ny = dx / dist, dy / dist
    --         -- local n = 0
    --         -- for d = 0, dist, math.max(1,math.min(rad1,rad2)/2) do
    --         --     local rad = rad1 + (rad2 - rad1) * d / dist
    --         --     if rad > 0 then
            --         love.graphics.circle("line", x1 + nx * d, y1 + ny * d, rad)
    --         --         love.graphics.circle("fill", x1 + nx * d, y1 + ny * d, rad)
    --         --     end
    --         -- end
    --     end
    -- end

    -- for i = 2, #left do
    --     local a, b = left[i - 1], left[i]
    --     love.graphics.line(a[1], a[2], b[1], b[2])

    --     local c, d = right[i - 1], right[i]
    --     love.graphics.line(c[1], c[2], d[1], d[2])

    --     -- love.graphics.polygon("fill", a[1], a[2], b[1], b[2], d[1], d[2], c[1], c[2])
    --     -- love.graphics.line(a[1],a[2],c[1],c[2])
    --     -- love.graphics.line(b[1],b[2],d[1],d[2])
    -- end
    -- if #left < 2 then return end
    -- for i=0,1 do
    --     local a, b = left[i * (#left-1) + 1], right[i * (#left-1) + 1]
    --     local cx,cy = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
    --     local rad = math.sqrt((a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2])) / 2

    --     local ang = math.atan2(a[2]-cy,a[1]-cx)
    --     local segments = math.min(64,math.max(4,rad^.5*2))
    --     if i == 0 then ang = ang + math.pi end
    --     if ang and ang == ang then
    --         -- print(cx,cy,rad,ang,ang+math.pi)
    --         love.graphics.arc("fill", cx, cy, rad, ang, ang+math.pi)
            -- love.graphics.arc("line", cx, cy, rad, ang, ang+math.pi)
    --     end
    -- end
end

function ad_stroke_simple_renderer:layer_was_removed(instruction, layer)
    if layer == self.layer then
        self.layer = nil
        anidraw:notify_modified(instruction)
        anidraw:notify_modified(self)
    end
end

function ad_stroke_simple_renderer:draw(ad_stroke, output_data, t, layer)
    if layer ~= self.layer then return layer end
    local r, g, b, a = unpack(self.color)
    love.graphics.setColor(r, g, b, a)
    if #output_data == 1 then
        local a = output_data[1]
        local x1, y1 = unpack(a)
        local rad = (a.pressure or 500) * pressure_scale + min_size
        if rad > 0 then
            -- love.graphics.circle("line", x1, y1, rad)
            love.graphics.circle("fill", x1, y1, rad)
        end
        love.graphics.setColor(1, 1, 1)
        return
    end
    draw_strokes(output_data, t, self.min_size, self.thickness)
    love.graphics.setColor(1, 1, 1)
    return layer
end

return ad_stroke_simple_renderer
