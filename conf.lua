local local_libs = ";scripts/?.lua;scripts/?/?.lua;lib/path2d/?.lua;lib/?/?.lua;lib/?.lua;lib/?/init.lua"
package.path = package.path .. local_libs
love.filesystem.setRequirePath(love.filesystem.getRequirePath()..local_libs)

function love.conf(t)
	t.console = true
	t.window.resizable = true
	t.window.vsync = false
	t.window.depth = 24
end