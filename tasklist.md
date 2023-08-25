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
    [x] Corner detection + straight lines
- Color selection
    [x] make pico8 color palette for now
- generic inspector for modifying components
    [x] add UI
    [x] Selection of created strokes via animation panel
    [x] Configuration of components
- Basic functionality
    [ ] Enabling / disabling drawing elements
- Grouping objects
    A group combines strokes into a set. A group should allow adding processors and renderers that are applied to every shape _after_ their own processors and renderers. Overriding colors etc. Layers are also selectable for these groups. UI wise, groups hide their members when folded.
    Implementation steps:
    [x] create UI to add a group
    [x] display groups in ui list
    [ ] selectable groups
        [ ] Animate options for groups
        [ ] Pre/Post-processors / Pre/Post-renderers
    [ ] foldable groups
    [x] groups get draw calls as instructions
        [x] fix issue of all instructions drawn simultanously
    [x] Make instructions assignable to groups
        [ ] reorderable lists
    [x] groups have instructions list for drawing
    [ ] Integrate groups into drawing workflow
        [ ] current drawing inserts into group
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