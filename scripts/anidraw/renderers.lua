local renderers = {
    "ad_stroke_simple_renderer",
    "ad_stroke_triangulator_renderer",
    "ad_stroke_layer_swap_renderer",
}

do
    -- need the classes to be loaded so deserialization can find them
    for i = 1, #renderers do
        require("ad_stroke." .. renderers[i])
    end
end

return renderers
