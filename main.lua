local pen_reading = require "pen_reading"
require "love-util.hotswap"

local ui_rect                       = require "love-ui.ui_rect"
local text_component                = require "love-ui.components.generic.text_component"
local pico8_colors                  = require "love-ui.pico8_colors"
local menubar_widget                = require "love-ui.widget.menubar_widget"
local parent_size_matcher_component = require "love-ui.components.layout.parent_size_matcher_component"
local weighted_position_component   = require "love-ui.components.layout.weighted_position_component"
local linear_layouter_component     = require "love-ui.components.layout.linear_layouter_component"
local scroll_area_widget            = require "love-ui.widget.scroll_area_widget"
local rectfill_component            = require "love-ui.components.generic.rectfill_component"
local distance_squared              = require "love-math.geom.3d.distance_squared"
local ui_theme                      = require "love-ui.ui_theme.ui_theme"
local menu_widget                   = require "love-ui.widget.menu_widget"
local textfield_component           = require "love-ui.components.generic.textfield_component"
local anidraw                       = require "anidraw"
local processors                    = require "anidraw.processors"

love.window.setTitle("love-ani-draw")

local function decorate_as_cmd_bar(left_bar)
    local groups = {}
    function left_bar:set_selected(rect)
        local group_list = rect.group_list
        if group_list then
            for i = 1, #group_list do
                group_list[i]:trigger_on_components("set_push_button_state", group_list[i] == rect)
            end
        end
        rect.cmd_fn()
    end

    function left_bar:cmd(icon, fn, group)
        local w = math.max(self.w, self.h)
        local rect = ui_rect:new(0, 0, w, w, self)
        rect.cmd_fn = fn
        if type(group) == "string" then
            local group_list = groups[group]
            ui_theme:decorate_push_button_skin(rect, not group_list, nil, icon, function(state)
                self:set_selected(rect)
            end)
            if not group_list then
                group_list = {}
                groups[group] = group_list
                self:set_selected(rect)
            end
            group_list[#group_list + 1] = rect
            rect.group_list = group_list
        elseif group then
            ui_theme:decorate_push_button_skin(rect, nil, nil, icon, fn)
        else
            ui_theme:decorate_button_skin(rect, nil, icon, fn)
        end
        return rect
    end

    function left_bar:cmd_space(s)
        ui_rect:new(0, 0, s or 4, s or 4, left_bar)
    end

    function left_bar:label(text)
        local tf = text_component:new(text, 6)
        tf:set_fitting_width(true)
        local rect = ui_rect:new(0, 0, 22, 22, self, tf)
        rect:update(0, 0)
    end
end

local function init(root_rect)
    local paint_component = {
        scale = 1,
        translate_x = 0,
        translate_y = 0,
        rotate = 0,
        transform = love.math.newTransform(),
    }

    function anidraw:clear_canvas()
        -- print(debug.traceback("clear canvas"))
        paint_component.canvas_draw_state = nil
    end

    root_rect:add_component(menubar_widget:new({ File_1 = function() end }, 1))
    local client_space = ui_rect:new(0, 0, 0, 0, root_rect, parent_size_matcher_component:new(19, 0, 0, 0))
    local top_bar_rect = ui_rect:new(0, 0, 0, 22, client_space, parent_size_matcher_component:new(0, 0, true, 0),
        rectfill_component:new(5))
    top_bar_rect:add_component(linear_layouter_component:new(1, true, 0, 0, 0, 0, 0))
    local right_bar_rect = ui_rect:new(0, 0, 300, 0, client_space, parent_size_matcher_component:new(0, 0, 0, true),
        rectfill_component:new(2))
    local bottom_bar = ui_rect:new(0, 0, right_bar_rect.w, 260, root_rect,
        parent_size_matcher_component:new(true, right_bar_rect.w, 0, 0))
    local left_bar = ui_rect:new(0, 0, 22, 22, client_space,
        parent_size_matcher_component:new(top_bar_rect.h, true, bottom_bar.h, 0),
        rectfill_component:new(5))

    local canvas_rect = ui_rect:new(20, 20, 500, 500, root_rect,
        parent_size_matcher_component:new(19 + top_bar_rect.h + 2, right_bar_rect.w + 2, bottom_bar.h + 2, left_bar.w + 2))
    canvas_rect:add_component(rectfill_component:new(6))

    right_bar_rect:add_component(linear_layouter_component:new(2, true, 0, 0, 0, 0, 5))
    left_bar:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 0))

    decorate_as_cmd_bar(left_bar)
    left_bar:cmd_space(8)
    left_bar:cmd(ui_theme.icon.cursor, function() end, "tools")
    left_bar:cmd(ui_theme.icon.hand, function() end, "tools")
    local pen_rect = left_bar:cmd(ui_theme.icon.pen, function() anidraw:set_tool("pen") end, "tools")
    left_bar:cmd(ui_theme.icon.eraser, function() end, "tools")
    left_bar:cmd_space()
    left_bar:cmd(ui_theme.icon.grid, function(state) anidraw.grid_enabled = state end, true)

    left_bar:set_selected(pen_rect)

    decorate_as_cmd_bar(top_bar_rect)

    local file_dialog_widget = require "love-ui.widget.file_dialog_widget"
    top_bar_rect:cmd(ui_theme.icon.save_disk, function()
        --anidraw:save()
        local fd = file_dialog_widget:new(ui_theme, "Save to file", "Save")
        if anidraw.path then
            fd:set_path(anidraw.path)
        end
        fd:show(root_rect, function(self, path)
            if path then
                if not path:match "%.ad" then
                    path = path .. ".ad"
                end
                anidraw:save(path)
            end
        end)
    end)
    top_bar_rect:cmd(ui_theme.icon.open_folder, function()
        local fd = file_dialog_widget:new(ui_theme, "Load from file", "Load")
        if anidraw.path then
            fd:set_path(anidraw.path)
        end
        fd:show(root_rect, function(self, path)
            if path then
                anidraw:load(path)
                anidraw:clear_canvas()
            end
        end)
    end)
    top_bar_rect:cmd_space()
    top_bar_rect:cmd(ui_theme.icon.undo, function() end)
    top_bar_rect:cmd(ui_theme.icon.redo, function() end)
    top_bar_rect:cmd_space(8)
    
    local add_slider = require "anidraw.ui.add_slider"

    --top_bar_rect:label("Pressure size:")
    add_slider("Pressure size: ", 250, 22, top_bar_rect, -50, 50, .1, function(value)
        anidraw.tools.pen.size = value
    end)

    top_bar_rect:cmd_space(8)
    -- top_bar_rect:label("min size:")
    add_slider("Min size: ", 250, 22, top_bar_rect, -50, 50, 0, function(value)
        anidraw.tools.pen.min_size = value
    end)

    top_bar_rect:cmd_space(8)
    top_bar_rect:cmd(ui_theme.icon.boundary_paint, function(state)
        anidraw.tools.pen.boundary_paint = state
    end, true)

    local colorpicker_rect = ui_rect:new(540, 20, right_bar_rect.w, 200, right_bar_rect)
    colorpicker_rect:add_component(rectfill_component:new(0))
    for i = 0, 15 do
        local x = i % 4
        local y = (i - x) / 4
        local color_rect = ui_rect:new(x * 50 + 2, y * 50 + 2, 46, 46, colorpicker_rect, rectfill_component:new(i))
        color_rect:add_component {
            was_triggered = function(cmp, rect)
                anidraw:set_color(pico8_colors[i])
            end
        }
    end

    local bottom_right_bar = ui_rect:new(0, 0, 0, 0, bottom_bar, parent_size_matcher_component:new(0, 0, 0, 300))
    local bottom_left_bar = ui_rect:new(0, 0, 300, 0, bottom_bar, parent_size_matcher_component:new(30, true, 0, 0))

    require "anidraw.ui.object_inspector":initialize(right_bar_rect)
    require "anidraw.ui.timeline_panel":initialize(bottom_right_bar)
    require "anidraw.ui.layer_panel":initialize(bottom_left_bar)

    local function replay(speed)
        anidraw:clear_canvas()
        anidraw:replay(speed)
    end

    local playback_bar = ui_rect:new(0, 0, right_bar_rect.w, 30, bottom_bar, rectfill_component:new(5))
    playback_bar:add_component(linear_layouter_component:new(1, true, 0, 0, 0, 0, 2))
    local playback_bar_layout = linear_layouter_component:new(1, true, 0, 0, 0, 0, 2)
    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.play, function()
        replay()
    end)

    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.play, function()
        replay(4)
    end)

    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.play, function()
        replay(8)
    end)

    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.close_x, function()
        anidraw:clear_canvas()
        anidraw:clear()
    end)


    local function stroke(self, pos_x, pos_y, pressure)
        anidraw.tools.pen:start(anidraw)
        while true do
            local to_x, to_y, pressure, finish = coroutine.yield()
            local dx, dy = to_x - pos_x, to_y - pos_y
            local d = (dx * dx + dy * dy) ^ .5
            if d > 0 then
                local nx, ny = dx / d, dy / d
                local n = 0
                local rad = 2
                local steps = finish and d or d / 2
                while distance_squared(to_x, to_y, 0, pos_x, pos_y, 0) > 2 and n < steps do
                    --self:paint_soft_circle(pos_x,pos_y,0,rad,1,1,0,.5)
                    pos_x, pos_y = pos_x + nx * rad / 2, pos_y + ny * rad / 2
                    n = n + 1
                end
                self.pressed_x, self.pressed_y = pos_x, pos_y
            end

            if finish then
                break
            end
            anidraw:add_point(to_x, to_y, pressure)
        end
        anidraw:finish()
    end

    function paint_component:was_released(rect, x, y)
        self.tracking_strokes = false
        if self.current_stroke then
            -- coroutine.resume(self.current_stroke, x, y, true)
            -- self.current_stroke = nil
        end
    end

    function paint_component:is_pressed_down(rect, x, y)
        self.tracking_strokes = true
        if not self.current_stroke then
            -- self.current_stroke = coroutine.create(stroke)
            -- coroutine.resume(self.current_stroke, self, x, y)
        end
        -- coroutine.resume(self.current_stroke, x, y)
    end

    local current_stroke
    local touches = {}
    local touch_cnt = 0
    local has_pen = false
    function love.touchreleased(id, x, y, dx, dy, pressure)
        love.touchmoved(id, x, y, dx, dy, pressure)

        x, y = canvas_rect:to_local(x, y)

        if current_stroke then
            local suc, err = coroutine.resume(current_stroke, x, y, 0, true)
            if not suc then
                print(debug.traceback(current_stroke, err))
            end
            current_stroke = nil
        end
        if touches[id] then
            touches[id] = nil
            touch_cnt = touch_cnt - 1
            if touch_cnt == 0 then
                has_pen = false
            end
        end
    end

    function love.touchpressed(id, x, y, dx, dy, pressure)
        if not touches[id] then
            touch_cnt = touch_cnt + 1
            local transform = paint_component.transform
            local pin_x, pin_y = transform:inverseTransformPoint(canvas_rect:to_local(x, y))
            touches[id] = {
                x = x,
                y = y,
                dx = 0,
                dy = 0,
                prev_x = x,
                prev_y = y,
                start_x = x,
                start_y = y,
                frames = 0,
                pin_x = pin_x,
                pin_y = pin_y
            }
        end
    end

    local debug_draw = {}
    local function draw_debug_circle(x, y, rad, r, g, b)
        debug_draw[#debug_draw + 1] = function()
            love.graphics.setColor(r or 1, g or 0, b or 0)
            love.graphics.circle("line", x, y, rad or 5)
            love.graphics.setColor(1, 1, 1)
        end
    end

    local function draw_debugs()
        for i = 1, #debug_draw do
            debug_draw[i]()
            debug_draw[i] = nil
        end
    end

    function love.touchmoved(id, x, y, dx, dy, pressure)
        if not paint_component.tracking_strokes then
            return
        end
        local transform = paint_component.transform
        local entries = pen_reading(id, function(pressure, px, py, index)
            local zoom = paint_component.zoom
            local x, y = canvas_rect:to_local(px, py)
            x, y = transform:inverseTransformPoint(x, y)
            if not current_stroke then
                current_stroke = coroutine.create(stroke)
                coroutine.resume(current_stroke, paint_component, x, y, pressure)
            end
            coroutine.resume(current_stroke, x, y, pressure)
            --print(x-px,y-py)
        end)
        if entries and #entries > 0 or has_pen then
            has_pen = true
            return
        end
        local touch = touches[id]
        if touch then
            touch.prev_x = touch.x
            touch.prev_y = touch.y
            touch.x = x
            touch.y = y
            touch.dx = dx
            touch.dy = dy

            touch.frames = touch.frames + 1
            if touch.frames < 2 or touch_cnt > 2 then
                return
            end

            local transform = paint_component.transform
            local touch_a = touch
            local touch_b
            for _, t in pairs(touches) do
                if t ~= touch_a then
                    touch_b = t
                    break
                end
            end

            local function update_transform()
                transform:reset()
                transform:rotate(paint_component.rotate)
                transform:scale(paint_component.scale, paint_component.scale)
                transform:translate(paint_component.translate_x, paint_component.translate_y)
            end

            -- two point gesture
            if touch_b then
                -- converting the touch points to canvas space (calling it "w" for "world")
                local wax, way = canvas_rect:to_local(touch_a.x, touch_a.y)
                local wbx, wby = canvas_rect:to_local(touch_b.x, touch_b.y)
                local wcx, wcy = canvas_rect:to_local(touch_a.prev_x, touch_a.prev_y)
                -- keeping the circles because it's useful for videos
                draw_debug_circle(wax, way, 30, 1, 0, 0)
                draw_debug_circle(wbx, wby, 30, 1, 0, 0)
                -- rotation is independent of transformations, so we can calculate it without much hassle
                local angle = math.atan2(way - wby, wax - wbx) - math.atan2(wcy - wby, wcx - wbx)

                -- original (o) and new (n) distances between the touch points in transformed space
                -- (pin = original touch point locations in transformed space)
                local odx, ody = touch_a.pin_x - touch_b.pin_x, touch_a.pin_y - touch_b.pin_y
                local odist = (odx * odx + ody * ody) ^ .5
                -- inverse (i) coordinates, so transformed space; it's where I struggled as it's
                -- counter intuitive; explanation: This is how we get the canvas space coordinates into
                -- the transformed space. Like the pinned coordinates.
                local iax, iay = transform:inverseTransformPoint(wax, way)
                local ibx, iby = transform:inverseTransformPoint(wbx, wby)
                -- new distance between the touch points in transformed space (analog to odx and ody)
                local ndx, ndy = iax - ibx, iay - iby
                -- new distance, analog to odist
                local ndist = (ndx * ndx + ndy * ndy) ^ .5
                local scale = ndist / odist
                -- we can now calculate the required scaling to make the distance match the touch points
                -- note: The max/min operation isn't good; it makes the translation jump between finger points
                -- because both points try to match the new location (whichever touch gets updated last)
                paint_component.scale = math.max(0.2, math.min(16, paint_component.scale * scale))
                paint_component.rotate = paint_component.rotate + angle
                -- update the transform using new scale and rotation
                update_transform()

                -- update to the new position: Using the center of both points is stable (using a or b alone isn't)
                local bx, by = (touch_b.pin_x + touch_a.pin_x) / 2, (touch_b.pin_y + touch_a.pin_y) / 2
                local nwbx, nwby = transform:inverseTransformPoint((wbx + wax) / 2, (wby + way) / 2)
                -- using the current center position in transformed space, we can calculate the translation
                -- needed to counteract rotation / scaling by comparing it to the pinned position
                paint_component.translate_x = paint_component.translate_x + nwbx - bx
                paint_component.translate_y = paint_component.translate_y + nwby - by
                -- another update to apply the translation
                update_transform()
            else -- one point gesture; much simpler
                local wax, way = canvas_rect:to_local(touch_a.x, touch_a.y)
                local iax, iay = transform:inverseTransformPoint(wax, way)
                paint_component.translate_x = paint_component.translate_x + iax - touch_a.pin_x
                paint_component.translate_y = paint_component.translate_y + iay - touch_a.pin_y
                update_transform()
            end
        end
    end

    function paint_component:draw(rect)
        local s = 1
        anidraw.grid_size = 128
        while s < self.scale do
            s = s * 2
            anidraw.grid_size = anidraw.grid_size / 2
        end

        --pen_reading()
        local cw, ch = unpack(anidraw.canvas_size)
        if not self.canvas or self.canvas:getWidth() ~= cw or self.canvas:getHeight() ~= ch then
            self.canvas = love.graphics.newCanvas(cw, ch)
            self.canvas_draw_state = nil
        end
        love.graphics.setCanvas(self.canvas)
        if not self.canvas_draw_state then
            love.graphics.clear(1, 1, 1, 0)
        end
        self.canvas_draw_state = self.canvas_draw_state or {}
        anidraw:draw(self.canvas_draw_state, false)
        love.graphics.setCanvas()

        local x, y = rect:to_world()
        local w, h = rect.w, rect.h
        love.graphics.setScissor(x, y, w, h)
        love.graphics.push()

        love.graphics.translate(rect:to_world())
        love.graphics.applyTransform(self.transform)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("line", 0, 0, cw, ch)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas)
        self.canvas_draw_state = self.canvas_draw_state or {}
        anidraw:draw(self.canvas_draw_state, true)
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(rect:to_world())
        draw_debugs()
        love.graphics.pop()

        love.graphics.setScissor()
    end

    canvas_rect:add_component(paint_component)

    ui_rect:new(0, 0, 100, 20, root_rect, weighted_position_component:new(1, 0)):add_component {
        draw = function(cmp, rect)
            love.graphics.print("FPS: " .. love.timer.getFPS(), rect:to_world())
        end
    }

    anidraw:load()
    anidraw:replay(16)
    anidraw:clear_canvas()
    anidraw:trigger_selected_objects_changed()
end

require "love-ui.uitk-setup" {
    update = function(dt)
    end,
    load = init
}

-- local maininfo = love.filesystem.getInfo("main.lua")

-- local function distance(x1,y1,x2,y2)
--     local dx,dy = x2-x1, y2-y1
--     return (dx*dx+dy*dy)^.5
-- end

-- local canvas

-- function love.load()
--     canvas = love.graphics.newCanvas()
-- end

-- local lines = {}
-- local current_line
-- local function handler()
--     if not love.mouse.isDown(1) then
--         return
--     end

--     current_line = {}
--     local px,py
--     while love.mouse.isDown(1) do
--         local x,y = love.mouse.getPosition()
--         if not px or distance(x,y,px,py) > 5 then
--             px,py = x,y
--             current_line[#current_line+1] = x
--             current_line[#current_line+1] = y
--         end
--         coroutine.yield()
--     end

--     love.graphics.setCanvas(canvas)


--     local x,y = current_line[1], current_line[2]
--     local target = 3
--     while target < #current_line do

--         target = target + 2
--     end

--     love.graphics.setCanvas()

-- end

-- local handler_routine = coroutine.create(handler)

-- function love.update(dt)
--     local info = love.filesystem.getInfo("main.lua")
--     if info.modtime > maininfo.modtime then
--         print "reloading"
--         love.load = nil
--         dofile "main.lua"
--         if love.load then love.load() end
--         return
--     end

--     if coroutine.status(handler_routine) == "dead" then
--         handler_routine = coroutine.create(handler)
--     end
--     local suc,err = coroutine.resume(handler_routine)
--     if not suc then
--         print(debug.traceback(handler_routine, err))
--     end
-- end


-- function love.draw()
--     love.graphics.clear()
--     love.graphics.draw(canvas)
--     if current_line and #current_line > 2 then
--         love.graphics.line(current_line)
--     end
-- end
