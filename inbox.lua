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
		if game_status.debug_messages then
			print(string.format("Controller added, %s is the active controller", controls.controller:getName()))
			game_status.debug_text = string.format("Controller added, %s is the active controller", controls.controller:getName())
		end
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
		if game_status.debug_messages then
			print(string.format("Controller disconnected, %s is the active controller, game paused"), controls.controller)
			game_status.debug_text = string.format("Controller disconnected, %s is the active controller, game paused", controls.controller)
		end
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
		if game_status.debug_messages then
			print("Controller disconnected, no controllers detected, game paused")
			game_status.debug_text = "Controller disconnected, no controllers detected, game paused"
		end
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
	
	if game_status.action == "play" then
		-- the game is proceeding normally
		if pressed == control_set.pause or pressed == "pause" then
			-- pause the game
			game_status.action = "pause"
			game_status.menu = "pause"
			if game_status.debug_messages then
				print("Game paused")
				game_status.debug_text = "Game paused"
			end
		end
	elseif game_status.action == "pause" then
		-- the game is paused
		if game_status.menu == "pause" then
			if pressed == control_set.pause or pressed == "pause" then
				-- unpause the game
				game_status.action = "play"
				game_status.menu = "none"
				if game_status.debug_messages then
					print("Game unpaused")
					game_status.debug_text = "Game unpaused"
				end
			elseif pressed == "x" then
				-- the player is trying to do a guaranteed quit of the game
				game_status.menu = "quit_check"
				if game_status.debug_messages then
					print("Entered quit confirmation dialog box")
					game_status.debug_text = "Entered quit confirmation dialog box"
				end
			elseif pressed == control_set.debug then
				game_status.menu = "debug"
				if game_status.debug_messages then
					print("Entered debug mode")
					game_status.debug_text = "Entered debug mode"
				end
			end
		elseif game_status.menu == "quit_check" then
			-- the player selected the quit option, ask if they're sure
			if pressed == control_set.pause or pressed == "backspace" or pressed == "b" then
				game_status.menu = "pause"
			elseif pressed == "x" then
				-- the player is trying to do a guaranteed quit of the game
				if game_status.debug_messages then
					print("Player quit the game")
					game_status.debug_text = "Player quit the game"
				end
				game_status.menu = "quit_confirmed"
				love.event.quit()
			end
		elseif game_status.menu == "debug" then
			-- debug mode is active, where the player can alter the game on a broad scale
			if pressed == control_set.debug or pressed == control_set.pause or pressed == "b" then
				game_status.menu = "pause"
				if game_status.debug_messages then
					print("Exited debug mode")
					game_status.debug_text = "Exited debug mode"
				end
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
			elseif pressed == "i" then
				-- turn debug info on or off
				if game_status.debug_stats then
					game_status.debug_stats = false
				elseif not game_status.debug_stats then
					game_status.debug_stats = true
				end
			elseif pressed == "r" then
				-- reset the player's powerup state
				
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
	end
end -- inbox.chunky_input


function inbox.instant_press()
	-- get which controls are being pressed right this instant; this is to be run once per update
	
	-- initialize timers
	local espresso = {
		pause = 0,
		ability = 0,
		main_attack = 0,
		up = 0,
		down = 0,
		left = 0,
		right = 0,
		debug = 0
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
	
	if controls.controller:isGamepadDown(controls.cnt.ability) then
		espresso.ability = 1
	end
	if not controls.kbd.modifier.ability then
		if love.keyboard.isScancodeDown(controls.kbd.bindings.ability) then
			espresso.ability = 1
		end
	elseif controls.kbd.modifier.ability then
		if love.keyboard.isDown(controls.kbd.bindings.ability) then
			espresso.ability = 1
		end
	end
	
	for key, value in pairs(espresso) do
		-- this control is being held down
		controls.quick_detect[key] = controls.quick_detect[key] - espresso[key]
		if espresso[key] == 0 then
			-- set the timer to 0 as this key isn't being pressed
			controls.quick_detect[key] = 0
		end
		if controls.quick_detect[key] <= -9 then
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
		sticks.positions.left_horizontal = util.round(controls.controller:getGamepadAxis("leftx"), 0.1)
	elseif controls.controller:getGamepadAxis("leftx") <= -0.05 then
		sticks.positions.left_horizontal = util.round(controls.controller:getGamepadAxis("leftx"), 0.1)
	else
		sticks.positions.left_horizontal = 0
	end
	if controls.controller:getGamepadAxis("lefty") >= 0.05 then
		sticks.positions.left_vertical = util.round(controls.controller:getGamepadAxis("lefty"), 0.1)
	elseif controls.controller:getGamepadAxis("lefty") <= -0.05 then
		sticks.positions.left_vertical = util.round(controls.controller:getGamepadAxis("lefty"), 0.1)
	else
		sticks.positions.left_vertical = 0
	end
	if controls.controller:getGamepadAxis("rightx") >= 0.05 then
		sticks.positions.right_horizontal = util.round(controls.controller:getGamepadAxis("rightx"), 0.1)
	elseif controls.controller:getGamepadAxis("rightx") <= -0.05 then
		sticks.positions.right_horizontal = util.round(controls.controller:getGamepadAxis("rightx"), 0.1)
	else
		sticks.positions.right_horizontal = 0
	end
	if controls.controller:getGamepadAxis("righty") >= 0.1 then
		sticks.positions.right_vertical = util.round(controls.controller:getGamepadAxis("righty"), 0.1)
	elseif controls.controller:getGamepadAxis("righty") <= -0.1 then
		sticks.positions.right_vertical = util.round(controls.controller:getGamepadAxis("righty"), 0.1)
	else
		sticks.positions.right_vertical = 0
	end
end -- inbox.stick_poll

return inbox

-- this library copyright 2017-20 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
