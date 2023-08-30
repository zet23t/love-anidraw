local processors = {
    "ad_stroke_smoothed_line_processor",
    "ad_stroke_straight_line_processor",
    "ad_stroke_regular_shape_processor",
    "ad_stroke_triangulator_renderer",
}

do
    -- need the classes to be loaded so deserialization can find them
    for i = 1, #processors do
        require("ad_stroke." .. processors[i])
    end
end

return processors
