-- This is the central module of the game.
-- All of the large-scale logic is here, along with miscellaneous small tasks.

-- utilities module
util = require "util"
-- spawn module
spawn = require "spawn"
-- collision module
shc = require "shc"
-- input and I/O device module
inbox = require "inbox"

-- set up broad-ranging game data
game_status = {
	action = nil,
	menu = nil,
	threshhold = 144,
	window_position = {
		x = nil,
		y = nil,
		display = nil
	},
	debug_messages = true,
	debug_text = nil
}

-- set up player data
player = {
	x = 0,
	y = 0,
	width = 0,
	height = 0,
	form = "small",
	health = 3,
	max_health = 3,
	hurt = false,
	flinch_timer = 0,
	spawn_timer = 0,
	flicker_timer = 0,
	flicker_max = 0.070,
	low_speed = 120,
	medium_speed = 150,
	high_speed = 180,
	alive = false,
	appearance = {
		small_sprite = nil,
		medium_sprite = nil,
		large_sprite = nil
	},
	projectile_speed = 200,
	projectile_sprite = nil,
	projectile_timer = 0,
	projectiles = {}
}

player.projectiles[1] = { x = -100, y = 100 }
player.projectiles[2] = { x = -100, y = 100 }
player.projectiles[3] = { x = -100, y = 100 }
player.projectiles[4] = { x = -100, y = 100 }
player.projectiles[5] = { x = -100, y = 100 }

-- set up data for game controls
controls = {
	kbd = {
		bindings = {
			pause = "escape",
			ability = "x",
			main_attack = "c",
			up = "up",
			down = "down",
			left = "left",
			right = "right",
			debug = "`"
		},
		modifier = {
			pause = true,
			ability = false,
			main_attack = false,
			up = true,
			down = true,
			left = true,
			right = true,
			debug = false
		}
	},
	cnt = {
		pause = "start",
		ability = "a",
		main_attack = "x",
		up = "dpup",
		down = "dpdown",
		left = "dpleft",
		right = "dpright",
		analog_sticks = {
			movement_stick = "left",
			inversion = "disabled",
			slow_horizontal_threshhold = 0.1,
			slow_vertical_threshhold = 0.1,
			medium_horizontal_threshhold = 0.35,
			medium_vertical_threshhold = 0.35,
			fast_horizontal_threshhold = 0.65,
			fast_vertical_threshhold = 0.65,
			positions = {
				left_horizontal = 0,
				left_vertical = 0,
				right_horizontal = 0,
				right_vertical = 0,
			}
		}
	},
	quick_detect = {
		pause = 0,
		ability = 0,
		main_attack = 0,
		up = 0,
		down = 0,
		left = 0,
		right = 0,
		debug = 0
	},
	clash_cooldown = nil,
	controller = nil
}
--[[
glossary of named states and important variables and data points for controls:
	kbd: table -- holds keyboard controls
	cnt: table -- holds controller (gamepad) controls
	touch: table -- holds touchscreen controls and data
	pause ... accept: string, format determined by LOVE -- gameplay and menu controls
	analog_sticks: table -- holds data relating to analog sticks
		movement_stick: left | right | disabled -- which analog stick is used to move and access menus
		inversion: horizontal | vertical | both | disabled -- which analog stick directions are reversed
		horizontal_threshhold: 0.1 ... 1.0 -- threshhold for horizontal analog stick movement to cause action
		vertical_threshhold: 0.1 ... 1.0 -- threshhold for vertical analog stick movement to cause action
		positions: table -- holds the intensity of horizontal and vertical displacement of each analog stick
			left_horizontal ... right_vertical: -1.0 ... 1.0 -- degree of inclination in a dimension per stick
	clash_cooldown: number, seconds -- manages various control error cooldowns
	controller: table -- holds various data and functions relating to the active controller
]]--

enemies = {
	timer = 8,
	basic = {
		sprite = nil,
		locations = {}
	}
}

function love.quit()
	-- deal with the player trying to quit the game
	if game_status.menu ~= "quit_confirmed" then
		-- don't quit
		game_status.input_type = nil
		game_status.selected_item = 1
		game_status.action = "pause"
		game_status.menu = "quit_check"
		return true
	elseif game_status.menu == "quit_confirmed" then
		-- completely quit the game
		return false
	end
end

function love.focus(focused_on_game)
	-- this function is called when the OS's focus is put on the game and when focus is taken away;
	-- this includes minimizing and un-minimizing the game
	
	if not focused_on_game and game_status.menu == "none" then
		-- pause the game if the player switches away from it and it's not already paused
		game_status.action = "pause"
		if game_status.menu == "none" or game_status.menu == "pause" then
			game_status.menu = "pause"
		end
		game_status.selected_item = 1
		if game_status.debug_messages then
			print("Game paused")
			game_status.debug_text = "Game paused"
		end
	end
end


function love.load(arg)
	-- this function is called when the game starts
	
	-- prepare game data and spawn game objects
	spawn.prepare_constant_data()
	
	-- reseed the random number generator
	love.math.setRandomSeed((math.floor(tonumber(os.date("%d")) / 10) + 1) * (tonumber(os.date("%w")) + 1) * tonumber(os.date("%I")) * (tonumber(os.date("%M")) + 1) * (math.floor(tonumber(os.date("%S")) / 12) + 1))
	
	player.width = player.appearance.small_sprite:getWidth()
	player.height = player.appearance.small_sprite:getHeight()
	
	love.graphics.setBackgroundColor(240, 240, 240)
	
	game_status.debug_text = "Welcome to Negative Space!"
	
	spawn.player(0, 235)
	
	player.form = "small"
	
	game_status.menu = "pause"
	game_status.action = "pause"
end -- love.load


function love.update(dt)
	-- this function is called once per frame, contains game logic, and provides a delta-time variable
	
	-- check if the game window is being moved
	local temp_window_position = {x = nil, y = nil, display = nil}
	temp_window_position.x, temp_window_position.y, temp_window_position.display = love.window.getPosition()
	if game_status.window_position.x ~= temp_window_position.x or game_status.window_position.y ~= temp_window_position.y or game_status.window_position.display ~= temp_window_position.display then
		-- the game window is being moved, pause the game for player safety and game state integrity
		if game_status.action == "play" then
			game_status.action = "pause"
			if game_status.menu == "none" then
				game_status.menu = "pause"
			end
			game_status.input_type = nil
			game_status.window_position.x, game_status.window_position.y, game_status.window_position.display = love.window.getPosition()
			if game_status.debug_messages then
				print("Game paused")
				game_status.debug_text = "Game paused"
			end
		end
	end
	
	-- poll the active controller's analog sticks
	if controls.controller then
		inbox.stick_poll(dt)
	end
	
	-- set some convenience data to deal with controls
	inbox.instant_press()
	
	if game_status.menu == "none" then
		-- run the main game logic
		
		for enemy_index, selected_enemy in pairs(enemies.basic.locations) do
			-- loop over enemies
			
			-- move enemies
			if selected_enemy.direction == "left" then
				selected_enemy.x = selected_enemy.x - selected_enemy.speed * dt
			elseif selected_enemy.direction == "right" then
				selected_enemy.x = selected_enemy.x + selected_enemy.speed * dt
			elseif selected_enemy.direction == "up" then
				selected_enemy.y = selected_enemy.y - selected_enemy.speed * dt
			elseif selected_enemy.direction == "down" then
				selected_enemy.y = selected_enemy.y + selected_enemy.speed * dt
			end
			
			-- check for collisions with the player
			if player.flinch_timer == 0 then
				if shc.check_collision(player.x, player.y, player.width, player.height, selected_enemy.x, selected_enemy.y, selected_enemy.width, selected_enemy.height, "full") then
					-- damage the player
					player.health = player.health - 1
					player.flinch_timer = 1
				end
			end
			
			-- check for enemies leaving the screen
			if selected_enemy.x + selected_enemy.width < 0 or selected_enemy.x > love.graphics.getWidth() or selected_enemy.y + selected_enemy.height < 0 or selected_enemy.y > love.graphics.getHeight() then
				-- the enemy is off the screen, despawn it
				enemies.basic.locations[enemy_index] = nil
			end
			
			-- check for player projectiles hitting an enemy
			for projectile_index, selected_projectile in pairs(player.projectiles) do
				if shc.check_collision(selected_projectile.x, selected_projectile.y, player.projectile_sprite:getWidth(), player.projectile_sprite:getHeight(), selected_enemy.x, selected_enemy.y, selected_enemy.width, selected_enemy.height, "full") then
					-- the enemy was hit, despawn it
					enemies.basic.locations[enemy_index] = nil
					selected_projectile.x = -100
				end
			end
		end
		
		if player.flinch_timer > 0 then
			player.flinch_timer = player.flinch_timer - dt
		elseif player.flinch_timer <= 0 then
			player.flinch_timer = 0
		end
		
		if player.alive then
			if controls.quick_detect.up < controls.quick_detect.down then
				player.y = player.y - (player.medium_speed * dt)
			elseif controls.quick_detect.down < controls.quick_detect.up then
				player.y = player.y + (player.medium_speed * dt)
			end
			if controls.quick_detect.left < controls.quick_detect.right then
				player.x = player.x - (player.medium_speed * dt)
			elseif controls.quick_detect.right < controls.quick_detect.left then
				player.x = player.x + (player.medium_speed * dt)
			end
			
			if player.x < 0 then
				player.x = 0
			elseif player.x + player.width > game_status.threshhold then
				player.x = game_status.threshhold - player.width
			end
			if player.y < 0 then
				player.y = 0
			elseif player.y + player.height > love.graphics.getHeight() then
				player.y = love.graphics.getHeight() - player.height
			end
			
			if player.projectile_timer > 0 then
				player.projectile_timer = player.projectile_timer - dt
			elseif player.projectile_timer <= 0 then
				player.projectile_timer = 0
			end
			
			if controls.quick_detect.main_attack ~= 0 then
				-- attack of the player (attack)
				spawn.player_projectile(player.x + player.width, player.y + (player.height / 2))
			end
			
			for projectile_index, selected_projectile in pairs(player.projectiles) do
				if selected_projectile.x >= love.graphics.getWidth() then
					selected_projectile.x = -100
				elseif selected_projectile.x > 0 and selected_projectile.x < love.graphics.getWidth() then
					selected_projectile.x = selected_projectile.x + (player.projectile_speed * dt)
				end
			end
			
			if player.health <= 0 then
				player.spawn_timer = 3
				player.alive = false
			end
		elseif not player.alive then
			-- the player is dead
			player.spawn_timer = player.spawn_timer - dt
			if player.spawn_timer <= 0 then
				player.spawn_timer = 0
				spawn.player(0, 235)
			end
		end
		
		if enemies.timer > 0 then
			enemies.timer = enemies.timer - dt
		elseif enemies.timer <= 0 then
			enemies.timer = 0
			local rand_x = util.weighted_random(750, 950, 880)
			local rand_y = util.weighted_random(50, 450, 250)
			spawn.enemy("standard", 25, 25, rand_x, rand_y, "left", 100, 1)
			enemies.timer = 4
		end
	elseif game_status.menu == "pause" then
		-- the game is paused
		
	end
end -- love.update


function love.draw()
	-- draw the background
	
	-- draw the player
	if player.form == "small" then
		love.graphics.draw(player.appearance.small_sprite, player.x, player.y)
	end
	
	-- draw enemies
	for enemy_index, selected_enemy in pairs(enemies.basic.locations) do
		love.graphics.draw(enemies.basic.sprite, selected_enemy.x, selected_enemy.y)
	end
	
	-- draw projectiles
	for projectile_index, selected_projectile in pairs(player.projectiles) do
		love.graphics.draw(player.projectile_sprite, selected_projectile.x, selected_projectile.y)
	end
	
	-- draw UI
	
	if game_status.menu == "pause" then
		-- draw more UI
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(240, 240, 240)
		love.graphics.printf("PAUSE", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("X TO QUIT", 0, 264, love.graphics.getWidth(), "center")
	elseif game_status.menu == "quit_check" then
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(240, 240, 240)
		love.graphics.printf("REALLY QUIT?", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("X TO QUIT", 0, 264, love.graphics.getWidth(), "center")
	elseif game_status.menu == "debug" then
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(240, 240, 240)
		love.graphics.printf("DEBUG", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("kill Player - take Health - Give health - kill Enemies - console Info - Reset powerups - Full health - resurrecT player - console Debug", love.graphics.getWidth() * 3/8, 264, love.graphics.getWidth() / 4, "center")
	end
end -- love.draw
