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
	action = "pause",
	menu = "pause",
	threshhold = 100,
	window_position = {
		x = nil,
		y = nil,
		display = nil
	},
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
	spawn_timer = 3,
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
	}
}

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

-- set up storage for menu data
menu_data = {
	pause = {},
	controls = {},
	sticks = {},
	save = {},
	quit = {},
	touch = {},
	template = {}
}

function love.quit()
	-- deal with the player trying to quit the game
	if game_status.menu ~= "quit_confirmed" then
		-- don't quit
		game_status.input_type = nil
		game_status.selected_item = 1
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
		game_status.menu = "pause"
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
	spawn.interface_fixed_data()
	
	-- reseed the random number generator
	love.math.setRandomSeed((math.floor(tonumber(os.date("%d")) / 10) + 1) * (tonumber(os.date("%w")) + 1) * tonumber(os.date("%I")) * (tonumber(os.date("%M")) + 1) * (math.floor(tonumber(os.date("%S")) / 12) + 1))
	
	player.appearance.small_sprite = love.graphics.newImage("assets/ship-small.png")
	player.width = player.appearance.small_sprite:getWidth()
	player.height = player.appearance.small_sprite:getHeight()
	
	love.graphics.setBackgroundColor(240, 240, 240)
	
	game_status.debug_text = "Welcome to Negative Space!"
	
	spawn.player(0, 235)
	
	player.form = "small"
	game_status.action = "play"
end

function love.update(dt)
	-- check if the game window is being moved
	local temp_window_position = {x = nil, y = nil, display = nil}
	temp_window_position.x, temp_window_position.y, temp_window_position.display = love.window.getPosition()
	if game_status.window_position.x ~= temp_window_position.x or game_status.window_position.y ~= temp_window_position.y or game_status.window_position.display ~= temp_window_position.display then
		-- the game window is being moved, pause the game for player safety and game state integrity
		if game_status.action == "pause" then
			game_status.menu = "pause"
			game_status.input_type = nil
			game_status.selected_item = 1
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
	
	if game_status.action == "play" then
		-- run the main game logic
		if controls.quick_detect.up then
			player.y = player.y - (player.medium_speed * dt)
		elseif controls.quick_detect.down then
			player.y = player.y + (player.medium_speed * dt)
		elseif controls.quick_detect.left then
			player.x = player.x - (player.medium_speed * dt)
		elseif controls.quick_detect.right then
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
	elseif game_status.action == "pause" then
		-- the game is paused
		
	end
end

function love.draw()
	-- draw the background
	
	-- draw the player
	if player.form == "small" then
		love.graphics.draw(player.appearance.small_sprite, player.x, player.y)
	end
	
	-- draw enemies
	
	-- draw projectiles
	
	-- draw UI
	
	if game_status.action == "pause" or game_status.action == "quit" then
		-- draw more UI
		
	end
end