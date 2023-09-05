local editables = require "anidraw.ui.editables"

local layer = require "love-util.class" "layer"

layer.name = "unnamed layer"
layer.editables = editables:new()
    :toggle("hidden", "hidden", false)
    
function layer:new()
    return self:create {}
end

return layer