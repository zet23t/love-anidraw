local anidraw = require "anidraw.instance"

local ad_stroke = require "ad_stroke.ad_stroke"
local ad_stroke_direct_processor = require "ad_stroke.ad_stroke_direct_processor"
local ad_stroke_simple_renderer = require "ad_stroke.ad_stroke_simple_renderer"
local ad_stroke_boundary_processor = require "ad_stroke.ad_stroke_boundary_processor"
local ad_stroke_triangulator_renderer = require "ad_stroke.ad_stroke_triangulator_renderer"

local pen = {
    size = 5,
    min_size = 1,
    boundary_paint = false,
}

function pen:start()
    anidraw:finish()
    local color = {unpack(anidraw.current_color)}

    local stroke = ad_stroke:new()
    if self.boundary_paint then
        stroke:add_processor(ad_stroke_boundary_processor:new(color, self.size, self.min_size))
        stroke:add_renderer(ad_stroke_triangulator_renderer:new(color))
    else
        stroke:add_processor(ad_stroke_direct_processor:new())
        stroke:add_renderer(ad_stroke_simple_renderer:new(color, self.size, self.min_size))
    end
    local action = {}
    function action:finish()
        if stroke.finish then stroke:finish() end
        return stroke
    end
    function action:draw(t)
        stroke:draw(t)
    end
    function action:add(x, y, pressure)
        stroke:add(x, y, pressure)
    end
    anidraw.current_action = action
end

return pen