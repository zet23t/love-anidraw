local anidraw = require "anidraw.instance"

local ad_stroke = require "ad_stroke.ad_stroke"
local ad_stroke_direct_processor = require "ad_stroke.ad_stroke_direct_processor"
local ad_stroke_simple_renderer = require "ad_stroke.ad_stroke_simple_renderer"

local pen = {}

function pen:start()
    anidraw:finish()
    local stroke = ad_stroke:new()
    stroke:add_processor(ad_stroke_direct_processor:new())
    stroke:add_renderer(ad_stroke_simple_renderer:new(anidraw.current_color))
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