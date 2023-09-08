local ui_theme   = require "love-ui.ui_theme.ui_theme"
local debug_draw = {}

local ad_stroke  = require "love-util.class" "ad_stroke"
ad_stroke.icon   = ui_theme.icon.pen

function ad_stroke:new()
    return self:create {
        input_data = {},
        output_data = {},
        processing_components = {},
        drawing_components = {},
        start_time = love.timer.getTime(),
        finish_time = love.timer.getTime(),
    }
end

function ad_stroke:run_components(components, fn, ...)
    for i = 1, #components do
        local cmp = components[i]
        if not cmp[fn] then
            -- print("warning, no such function: ", fn, cmp)
            -- for k, v in pairs(cmp) do
            --     print(k, v)
            -- end
        else
            cmp[fn](cmp, self, ...)
        end
    end
end

function ad_stroke:add_processor(cmp)
    self.processing_components[#self.processing_components + 1] = cmp
    return self
end

function ad_stroke:add_renderer(cmp)
    self.drawing_components[#self.drawing_components + 1] = cmp
    return self
end

local function run_group_processors(self, getter, which, fn_name, group, ...)
    if not group then return end
    run_group_processors(self, getter, which, fn_name, group.group, ...)
    if not group[getter] then
        print("warning, no such function: ", getter, group, getmetatable(group))
        for index, value in pairs(group) do
            print(index, value)
        end
    end
    local preprocessing = group[getter](group)[which]
    for i=1,#preprocessing do
        local cmp = preprocessing[i]
        cmp[fn_name](cmp, self, ...)
    end
end

function ad_stroke:run_processing()
    self.output_data = {}
    debug_draw[self] = {}
    run_group_processors(self, "get_preprocessing_components", "processing_components", "process", self.group, self.input_data, self.output_data)
    self:run_components(self.processing_components, "process", self.input_data, self.output_data)
    run_group_processors(self, "get_postprocessing_components", "processing_components", "process", self.group, self.input_data, self.output_data)
end

function ad_stroke:add(x, y, pressure)
    self.polygon_points = nil
    local t = love.timer.getTime() - self.start_time
    self.input_data[#self.input_data + 1] = { x, y, t = t, pressure = pressure }
    self.finish_time = t
    self:run_processing()
end

function ad_stroke:tostr()
    return "Stroke (" .. #self.input_data .. ")"
end

function ad_stroke:add_debug_draw(fn)
    debug_draw[self][#debug_draw[self] + 1] = fn
end

local function sqd(x1,y1,x2,y2)
    local dx,dy = x2-x1,y2-y1
    return dx*dx+dy*dy
end

function ad_stroke:draw_highlight()
    if not self.polygon_points then
        self.polygon_points = {}
        local px, py
        for i = 1, #self.input_data do
            local x, y = unpack(self.input_data[i])
            
            if not px or sqd(px,py,x,y) > 2 then
                self.polygon_points[#self.polygon_points + 1] = x
                self.polygon_points[#self.polygon_points + 1] = y
                px, py = x, y
            end
        end
    end

    if #self.polygon_points < 4 then return end
    
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineJoin("none")
    love.graphics.setLineWidth(5)
    love.graphics.setColor(0, 0, 0)
    love.graphics.line(self.polygon_points)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.polygon_points)
    love.graphics.setLineWidth(lw)
end

local function run_group_renderer(self, getter, which, fn_name, group, output_data, t, layer)
    if not group then return layer end
    layer = run_group_renderer(self, getter, which, fn_name, group.group, output_data, t, layer)
    if not group[getter] then
        print("warning, no such function: ", getter, group, getmetatable(group))
        for index, value in pairs(group) do
            print(index, value)
        end
    end
    local preprocessing = group[getter](group)[which]
    for i=1,#preprocessing do
        local cmp = preprocessing[i]
        layer = cmp[fn_name](cmp, self, output_data, t, layer)
    end
    return layer
end
function ad_stroke:get_run_children_renderers_state()
    if not self.group then return true end
    return self.group:get_run_children_renderers_state()
end

function ad_stroke:layer_was_removed(layer)
    self:run_components(self.processing_components, "layer_was_removed", layer)
    self:run_components(self.drawing_components, "layer_was_removed", layer)
end

function ad_stroke:draw(t, draw_state, temporary, layer)
    layer = run_group_renderer(self, "get_preprocessing_components", "drawing_components", "draw", self.group, self.output_data, t, layer)
    
    if self:get_run_children_renderers_state() then
        local components = self.drawing_components
        for i = 1, #components do
            local cmp = components[i]
            if not cmp.draw then
                print("warning, no draw function: ", cmp)
                for k, v in pairs(cmp) do
                    print(k, v)
                end
            else
                layer = cmp:draw(self, self.output_data, t, layer)
            end
        end
    end
    
    layer = run_group_renderer(self, "get_postprocessing_components", "drawing_components", "draw", self.group, self.output_data, t, layer)
    
    local dd = debug_draw[self]
    if dd then
        for i = 1, #dd do
            dd[i]()
        end
    end
end

return ad_stroke
