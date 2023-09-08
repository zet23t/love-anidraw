- console: A console log would be nice
- Tool palette
    [x] Drawing
    [ ] Selection
    [ ] Erasing
    [ ] Color picker
    [ ] Width manipulator
    [ ] Deformator
- Loading / saving to file
    [x] Dialog with file selector
    [ ] File view filtering
    [ ] save vs save as
    [ ] recent files
    [ ] Populating the "file" menubar options
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
    [x] Enabling / disabling drawing elements

- Grouping objects
    A group combines strokes into a set. A group should allow adding processors and renderers that are applied to every shape _after_ their own processors and renderers. Overriding colors etc. Layers are also selectable for these groups. UI wise, groups hide their members when folded.
    Implementation steps:
    [x] create UI to add a group
    [x] display groups in ui list
    [x] selectable groups
        [ ] Animate options for groups
        [ ] Pre/Post-processors / Pre/Post-renderers
    [x] foldable groups
    [x] visibility toggle
    [ ] Optimize sorting and drawing of list
        - Create a list of all instructions
        - Select those visible
        - update rects (delete invisible, create newly visible)
        - doesn't need sorting
    [x] groups get draw calls as instructions
        [x] fix issue of all instructions drawn simultanously
    [x] Make instructions assignable to groups
        [x] reorderable lists
    [x] groups have instructions list for drawing
    [ ] Integrate groups into drawing workflow
        [ ] current drawing inserts into group
- Layers
    [x] Consider how layers should work
        - Setting of the stroke or setting of the renderer?
        - If it's a setting of the stroke, the UI is relatively easy, as it's a 1:n relationship
        - If it's a setting of the renderer, the relationship is m:n - which is difficult to settle in UI
        - 
    [x] add UI
    [x] assignable layers
    [ ] Layer rendering
    [ ] Groups layer assignment remapping: 
        By mapping a layer such as "no layer" to a layer (or the reverse), the drawing setup can conveniently change drawing operations without taking freedom away from child operations
- Selection system
    [ ] allow selection of multiple objects
    [ ] highlight strokes mouseover
- Path structure
    [?] create mesh instead of rendering points
- Performance improvements
    [x] draw on canvas, refresh only on change
    [ ] Optimize line renderer
- Groups
    [ ] Group components for the instruction itself
    [ ] Processors and renderers on groups
        [ ] Prepend to existing child renderers / processors
        [ ] Append to existing child renderers / processors
        [ ] Disabling renderers / processors of children

