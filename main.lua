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

local anidraw                       = require "anidraw"


love.window.setTitle("love-ani-draw")


local function init(root_rect)
    root_rect:add_component(menubar_widget:new({ File_1 = function() end }, 1))
    local client_space = ui_rect:new(0, 0, 0, 0, root_rect, parent_size_matcher_component:new(19, 0, 0, 0))
    local right_bar_rect = ui_rect:new(0, 0, 200, 0, client_space, parent_size_matcher_component:new(0, 0, 0, true),
        rectfill_component:new(2))
    local bottom_bar = ui_rect:new(0, 0, right_bar_rect.w, 260, root_rect,
        parent_size_matcher_component:new(true, right_bar_rect.w, 0, 0))
    local left_bar = ui_rect:new(0, 0, 22, 100, client_space, parent_size_matcher_component:new(0, true, bottom_bar.h, 0),
        rectfill_component:new(5))
    local timeline = ui_rect:new(0, 0, right_bar_rect.w, 200, bottom_bar, parent_size_matcher_component:new(30, 0, 0, 0))

    local canvas_rect = ui_rect:new(20, 20, 500, 500, root_rect,
        parent_size_matcher_component:new(19 + 2, right_bar_rect.w + 2, bottom_bar.h + 2, left_bar.w + 2))
    canvas_rect:add_component(rectfill_component:new(6))

    right_bar_rect:add_component(linear_layouter_component:new(2, true, 0, 0, 0, 0, 5))
    left_bar:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 0))
    local groups = {}

    local function set_selected(rect)
        local group_list = rect.group_list
        if group_list then
            for i = 1, #group_list do
                group_list[i]:trigger_on_components("set_push_button_state", group_list[i] == rect)
            end
        end
        rect.cmd_fn()
    end

    local function cmd(icon, fn, group)
        local rect = ui_rect:new(0, 0, left_bar.w, left_bar.w, left_bar)
        rect.cmd_fn = fn
        if type(group) == "string" then
            local group_list = groups[group]
            ui_theme:decorate_push_button_skin(rect, not group_list, nil, icon, function(state)
                set_selected(rect)
            end)
            if not group_list then
                group_list = {}
                groups[group] = group_list
                set_selected(rect)
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
    local function cmd_space()
        ui_rect:new(0, 0, left_bar.w, 4, left_bar)
    end
    cmd(ui_theme.icon.undo, function() end)
    cmd(ui_theme.icon.redo, function() end)
    cmd_space()
    cmd(ui_theme.icon.cursor, function() end, "tools")
    cmd(ui_theme.icon.hand, function() end, "tools")
    local pen_rect = cmd(ui_theme.icon.pen, function() anidraw:set_tool("pen") end, "tools")
    cmd(ui_theme.icon.eraser, function() end, "tools")
    cmd_space()
    cmd(ui_theme.icon.grid, function(state) anidraw.grid_enabled = state end, true)

    set_selected(pen_rect)

    local colorpicker_rect = ui_rect:new(540, 20, 200, 200, right_bar_rect)
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



    local timeline_scroll_area = scroll_area_widget:new(ui_theme, 180, 200)
    timeline:add_component(timeline_scroll_area)
    timeline_scroll_area.scroll_content:add_component(linear_layouter_component:new(2, false, 0, 0, 0, 0, 2))
    timeline_scroll_area.scroll_content:add_component {
        timeline_map = {},
        map_timeline = function(cmp, rect, instruction)
            if cmp.timeline_map[instruction] then return end
            local instruction_rect = ui_rect:new(0, 0, rect.w, 20, rect, rectfill_component:new(nil, 0))
            ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, instruction_rect,
                weighted_position_component:new(1, 0.5)), nil, ui_theme.icon.close_x, function()
                anidraw:delete_instruction(instruction)
            end)
            cmp.timeline_map[instruction] = instruction_rect
        end,
        update = function(cmp, rect)
            local map = {}
            for i = 1, #anidraw.instructions do
                local instruction = anidraw.instructions[i]
                cmp:map_timeline(rect, instruction)
                map[instruction] = true
            end
            for k, v in pairs(cmp.timeline_map) do
                if not map[k] then
                    cmp.timeline_map[k] = nil
                    v:remove()
                end
            end
        end
    }

    local playback_bar = ui_rect:new(0, 0, right_bar_rect.w, 30, bottom_bar, rectfill_component:new(5))
    playback_bar:add_component(linear_layouter_component:new(1, true, 0, 0, 0, 0, 2))
    local playback_bar_layout = linear_layouter_component:new(1, true, 0, 0, 0, 0, 2)
    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.play, function()
        anidraw:replay()
    end)

    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.play, function()
        anidraw:replay(4)
    end)

    ui_theme:decorate_button_skin(ui_rect:new(0, 0, 20, 20, playback_bar), nil, ui_theme.icon.close_x, function()
        anidraw:clear()
    end)

    local paint_component = {}

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

    function love.touch_released(id, x, y, dx, dy, pressure)
        love.touch_moved(id, x, y, dx, dy, pressure)

        x, y = canvas_rect:to_local(x, y)

        if current_stroke then
            local suc, err = coroutine.resume(current_stroke, x, y, 0, true)
            if not suc then
                print(debug.traceback(current_stroke, err))
            end
            current_stroke = nil
        end
    end

    function love.touch_pressed(id, x, y, dx, dy, pressure)

    end

    function love.touch_moved(id, x, y, dx, dy, pressure)
        if paint_component.tracking_strokes then
            pen_reading(id, function(pressure, px, py)
                local x, y = canvas_rect:to_local(px, py)
                if not current_stroke then
                    current_stroke = coroutine.create(stroke)
                    coroutine.resume(current_stroke, paint_component, x, y, pressure)
                end
                coroutine.resume(current_stroke, x, y, pressure)

                --print(x-px,y-py)
            end)
        end
    end

    function paint_component:draw(rect)
        --pen_reading()
        local x, y = rect:to_world()
        local w, h = rect.w, rect.h
        love.graphics.setScissor(x, y, w, h)
        love.graphics.push()

        love.graphics.translate(rect:to_world())
        love.graphics.scale(1, 1)
        anidraw:draw()
        love.graphics.pop()

        love.graphics.setScissor()
    end

    canvas_rect:add_component(paint_component)

    ui_rect:new(0, 0, 100, 20, root_rect, weighted_position_component:new(1, 0)):add_component {
        draw = function(cmp, rect)
            love.graphics.print("FPS: " .. love.timer.getFPS(), rect:to_world())
        end
    }
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
