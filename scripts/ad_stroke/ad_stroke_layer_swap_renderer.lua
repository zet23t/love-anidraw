local editables                         = require "anidraw.ui.editables"
local ad_stroke_layer_swap_renderer     = require "love-util.class" "ad_stroke_layer_swap_renderer"
local anidraw                           = require "anidraw.instance"
ad_stroke_layer_swap_renderer.editables = editables:new()
    :layer("layer_a", "Layer A")
    :layer("layer_b", "Layer B")

function ad_stroke_layer_swap_renderer:new(color)
    return self:create {
        color = {}
    }
end

function ad_stroke_layer_swap_renderer:layer_was_removed(instruction, layer)
    if layer == self.layer_a then
        self.layer_a = nil
        anidraw:notify_modified(self)
        anidraw:notify_modified(instruction)
    end

    if layer == self.layer_b then
        self.layer_b = nil
        anidraw:notify_modified(self)
        anidraw:notify_modified(instruction)
    end
end

function ad_stroke_layer_swap_renderer:draw(ad_stroke, output_data, t, layer)
    if layer == self.layer_a then
        return self.layer_b
    elseif layer == self.layer_b then
        return self.layer_a
    end

    return layer
end

return ad_stroke_layer_swap_renderer
