- console: A console log would be nice
- Tool palette
    [x] Drawing
    [ ] Selection
    [ ] Erasing
    [ ] Color picker
    [ ]
-
- Processors
    [x] Straight line
    [ ] Boundary processor
    [ ] Smoothing processor
- Color selection
    [x] make pico8 color palette for now
- generic inspector for modifying components
    [x] add UI
    [x] Selection of created strokes via animation panel
    [x] Configuration of components
- Layers
    [ ] Consider how layers should work
        - Setting of the stroke or setting of the renderer?
        - If it's a setting of the stroke, the UI is relatively easy, as it's a 1:n relationship
        - If it's a setting of the renderer, the relationship is m:n - which is difficult to settle in UI
        - 
    [ ] add UI
    [ ] assignable layers
    [ ]
- Selection system
    [ ] allow selection of multiple objects
    [ ] highlight strokes mouseover
- Path structure
    [?] create mesh instead of rendering points
- Performance improvements
    [x] draw on canvas, refresh only on change