-- This module handles input and manages I/O devices.

local inbox = {}

function love.keypressed(key, scancode)
	-- handle key-presses in a different way than love.keyboard.isScancodeDown-- a decidely chunkier way
	inbox.chunky_input(scancode, "keyboard", key)
end


function love.gamepadpressed(gamepad, button)
	-- handle button-presses for use in menus and anything else that needs coarse-grained handling
	inbox.chunky_input(button, "controller")
end

function love.joystickadded(controller)
	-- a controller was connected, so make it the active controller
	if controller:isGamepad() then
		controls.controller = controller
	end
end

function love.joystickremoved()
	-- a controller was disconnected, so pause the game for player safety
	game_status.menu = "pause"
	game_status.selected_item = 1
	
	local all_controllers = love.joystick.getJoysticks()
	if #all_controllers > 0 then
		-- set the active controller to the last one in the list returned by LOVE
		controls.controller = all_controllers(#all_controllers)
	elseif #all_controllers == 0 then
		-- there are no controllers connected, so replace the controller table with
		-- some fallback functions that keep things working
		controls.controller = {
			isGamepadDown = function ()
				return nil
			end,
			getGamepadAxis = function ()
				return 0
			end
		}
	end
end


function inbox.chunky_input(pressed, input_device, keypress)
	-- this function handles discrete input (as opposed to continuous)
	
	-- account for different input types
	local control_set = nil
	
	if input_device == "keyboard" then
		control_set = controls.kbd.bindings
	elseif input_device == "controller" then
		control_set = controls.cnt
	end
	
	if game_status.menu == "none" then
		-- the game is proceeding normally
		if pressed == control_set.pause or pressed == "pause" then
			-- pause the game
			game_status.menu = "pause"
		elseif pressed == control_set.form_up then
			if player.form == "small" then
				player.form = "medium"
				player.height = player.medium_height
				player.y = player.y - ((player.medium_height - player.small_height) / 2)
			elseif player.form == "medium" then
				player.form = "large"
				player.height = player.large_height
				player.y = player.y - ((player.large_height - player.medium_height) / 2)
			end
		elseif pressed == control_set.form_down then
			if player.form == "large" then
				player.form = "medium"
				player.height = player.medium_height
				player.y = player.y + ((player.large_height - player.medium_height) / 2)
			elseif player.form == "medium" then
				player.form = "small"
				player.height = player.small_height
				player.y = player.y + ((player.medium_height - player.small_height) / 2)
			end
		end
	elseif game_status.menu == "pause" then
		-- the game is paused
		if pressed == control_set.pause or pressed == "pause" then
			-- unpause the game
			game_status.menu = "none"
		elseif pressed == "x" then
			-- the player is trying to quit the game
			game_status.menu = "quit_check"
		elseif pressed == control_set.debug then
			game_status.menu = "debug"
		end
	elseif game_status.menu == "game_over" then
		if pressed == control_set.pause or pressed == "pause" then
			-- unpause the game
			game_status.menu = "none"
		elseif pressed == "x" then
			-- the player is trying to quit the game
			game_status.menu = "quit_check"
		end
	elseif game_status.menu == "quit_check" then
		-- the player selected the quit option, ask if they're sure
		if pressed == control_set.pause or pressed == "backspace" or pressed == "b" then
			game_status.menu = "pause"
		elseif pressed == "x" then
			-- the player is trying to do a guaranteed quit of the game
			game_status.menu = "quit_confirmed"
			love.event.quit()
		end
	elseif game_status.menu == "debug" then
		-- debug mode is active, where the player can alter the game on a broad scale
		if pressed == control_set.debug or pressed == control_set.pause or pressed == "b" then
			game_status.menu = "pause"
		elseif pressed == "p" then
			player.alive = false
		elseif pressed == "h" then
			if player.health >= 1 then
				player.health = player.health - 1
			end
		elseif pressed == "g" then
			if player.health < player.max_health then
				player.health = player.health + 1
			end
		elseif pressed == "e" then
			-- kill all enemies
			for enemy_type_index, selected_enemy_type in pairs(map.enemies) do
				for enemy_index, selected_enemy in pairs(selected_enemy_type.locations) do
					selected_enemy.health = 0
				end
			end
		elseif pressed == "f" then
			-- grant the player full health
			player.health = player.max_health
		elseif pressed == "t" then
			-- resurrect the player (only effective when the player is dead but not despawned yet)
			player.alive = true
			player.health = 1
			player.spawn_timer = 3
		elseif pressed == "d" then
			-- engage Lua's interactive debugger and tell the user what's going on
			print("Interactive debugger launched, type \"cont\" and press Enter to resume the game")
			debug.debug()
		end
	end
end -- inbox.chunky_input


function inbox.instant_press()
	-- get which controls are being pressed right this instant; this is to be run once per update
	
	-- initialize timers
	local espresso = {
		pause = 0,
		main_attack = 0,
		up = 0,
		down = 0,
		left = 0,
		right = 0
	}
	
	if controls.controller:isGamepadDown(controls.cnt.up) then
		espresso.up = 1
	end
	if not controls.kbd.modifier.up then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.up) then
			espresso.up = 1
		end
	elseif controls.kbd.modifier.up then
		if love.keyboard.isDown(controls.kbd.bindings.up) then
			espresso.up = 1
		end
	end
	
	if controls.controller:isGamepadDown(controls.cnt.down) then
		espresso.down = 1
	end
	if not controls.kbd.modifier.down then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.down) then
			espresso.down = 1
		end
	elseif controls.kbd.modifier.down then
		if love.keyboard.isDown(controls.kbd.bindings.down) then
			espresso.down = 1
		end
	end
	
	if controls.controller:isGamepadDown(controls.cnt.left) then
		espresso.left = 1
	end
	if not controls.kbd.modifier.left then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.left) then
			espresso.left = 1
		end
	elseif controls.kbd.modifier.left then
		if love.keyboard.isDown(controls.kbd.bindings.left) then
			espresso.left = 1
		end
	end
	
	if controls.controller:isGamepadDown(controls.cnt.right) then
		espresso.right = 1
	end
	if not controls.kbd.modifier.right then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.right) then
			espresso.right = 1
		end
	elseif controls.kbd.modifier.right then
		if love.keyboard.isDown(controls.kbd.bindings.right) then
			espresso.right = 1
		end
	end
	
	if controls.controller:isGamepadDown(controls.cnt.main_attack) then
		espresso.main_attack = 1
	end
	if not controls.kbd.modifier.main_attack then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.main_attack) then
			espresso.main_attack = 1
		end
	elseif controls.kbd.modifier.main_attack then
		if love.keyboard.isDown(controls.kbd.bindings.main_attack) then
			espresso.main_attack = 1
		end
	end
	
	for key, value in pairs(espresso) do
		-- this control is being held down
		controls.quick_detect[key] = controls.quick_detect[key] - espresso[key]
		if espresso[key] == 0 then
			-- set the timer to 0 as this key isn't being pressed
			controls.quick_detect[key] = 0
		end
		if controls.quick_detect[key] < -9 then
			controls.quick_detect[key] = -9
		end
	end
end -- inbox.instant_press


function inbox.stick_poll(dt)
	-- check the active controller's analog sticks and translate their state into useful game data
	
	-- create a local table to make things a bit cleaner
	local sticks = controls.cnt.analog_sticks
	
	-- get and store the intensity of vertical and horizontal displacement of the analog sticks
	if controls.controller:getGamepadAxis("leftx") >= 0.05 then
		sticks.positions.left_horizontal = util.round(controls.controller:getGamepadAxis("leftx"), 0.01)
	elseif controls.controller:getGamepadAxis("leftx") <= -0.05 then
		sticks.positions.left_horizontal = util.round(controls.controller:getGamepadAxis("leftx"), 0.01)
	else
		sticks.positions.left_horizontal = 0
	end
	if controls.controller:getGamepadAxis("lefty") >= 0.05 then
		sticks.positions.left_vertical = util.round(controls.controller:getGamepadAxis("lefty"), 0.01)
	elseif controls.controller:getGamepadAxis("lefty") <= -0.05 then
		sticks.positions.left_vertical = util.round(controls.controller:getGamepadAxis("lefty"), 0.01)
	else
		sticks.positions.left_vertical = 0
	end
	if controls.controller:getGamepadAxis("rightx") >= 0.05 then
		sticks.positions.right_horizontal = util.round(controls.controller:getGamepadAxis("rightx"), 0.01)
	elseif controls.controller:getGamepadAxis("rightx") <= -0.05 then
		sticks.positions.right_horizontal = util.round(controls.controller:getGamepadAxis("rightx"), 0.01)
	else
		sticks.positions.right_horizontal = 0
	end
	if controls.controller:getGamepadAxis("righty") >= 0.1 then
		sticks.positions.right_vertical = util.round(controls.controller:getGamepadAxis("righty"), 0.01)
	elseif controls.controller:getGamepadAxis("righty") <= -0.1 then
		sticks.positions.right_vertical = util.round(controls.controller:getGamepadAxis("righty"), 0.01)
	else
		sticks.positions.right_vertical = 0
	end
end -- inbox.stick_poll

return inbox

-- this library copyright 2017-20 GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
