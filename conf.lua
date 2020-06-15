-- This file has basic configuration information and is processed before the main file.

function love.conf(t)
	t.window.title = "Negative Space"
	t.window.width = 1000
	t.window.height = 500
	t.identity = "Negative Space"
	t.console = true
	t.modules.physics = false
	t.modules.video = false
	t.modules.thread = false
end
