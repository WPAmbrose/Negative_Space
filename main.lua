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
	menu = nil,
	threshhold = 144,
	points = 0,
	window_position = {
		x = nil,
		y = nil,
		display = nil
	}
}

-- set up player data
player = {
	x = 0,
	y = 0,
	width = 0,
	height = 0,
	form = "small",
	small_height = 0,
	medium_height = 0,
	large_height = 0,
	health = 3,
	max_health = 3,
	hurt = false,
	flinch_timer = 0,
	spawn_timer = 0,
	flicker_timer = 0,
	flicker_max = 0.070,
	horizontal_speed = nil,
	vertical_speed = nil,
	low_speed = 120,
	medium_speed = 150,
	high_speed = 180,
	alive = false,
	lives = 3,
	appearance = {
		small_sprite = nil,
		medium_sprite = nil,
		large_sprite = nil
	},
	projectile_speed = 240,
	slow_projectile_speed = 210,
	small_projectile_sprite = nil,
	large_projectile_sprite = nil,
	projectile_timer = 0,
	small_projectiles = {},
	large_projectiles = {}
}

-- set up data for game controls
controls = {
	kbd = {
		bindings = {
			pause = "escape",
			main_attack = "c",
			form_up = "x",
			form_down = "z",
			up = "up",
			down = "down",
			left = "left",
			right = "right",
			debug = "`"
		},
		modifier = {
			pause = true,
			main_attack = false,
			form_up = false,
			form_down = false,
			up = true,
			down = true,
			left = true,
			right = true,
			debug = false
		}
	},
	cnt = {
		pause = "start",
		main_attack = "a",
		form_up = "x",
		form_down = "b",
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
		main_attack = 0,
		up = 0,
		down = 0,
		left = 0,
		right = 0,
		debug = 0
	},
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
	controller: table -- holds various data and functions relating to the active controller
]]--

map = {
	stars = {
		near_stars = {
			image = nil,
			quad = nil,
			speed = 3.4,
			spawn_group = spawn.star_group,
			spawn_stars = spawn.stars,
			groups = {}
		},
		far_stars = {
			image = nil,
			quad = nil,
			speed = 2,
			spawn_group = spawn.star_group,
			spawn_stars = spawn.stars,
			groups = {}
		}
	},
	explosions = {}
}

enemies = {
	spawn_timer = 7,
	spawn_latch = 2.70,
	attack_timer = 8.5,
	attack_latch = 1.35,
	weight_point = love.graphics.getHeight() / 2,
	weight_wait = 12,
	basic = {
		sprite = nil,
		locations = {},
		projectiles = {
			sprite = nil,
			speed = 180,
			width = 25,
			height = 25,
			locations = {}
		}
	}
}

function love.focus(focused_on_game)
	-- this function is called when the OS's focus is put on the game and when focus is taken away;
	-- this includes minimizing and un-minimizing the game
	
	if not focused_on_game and game_status.menu == "none" then
		-- pause the game if the player switches away from it and it's not already paused
		if game_status.menu == "none" or game_status.menu == "pause" then
			game_status.menu = "pause"
		end
		game_status.selected_item = 1
	end
end

function love.mousemoved(x, y, dx, dy)
	if player.alive and game_status.menu == "none" then
		-- move the player with the mouse as long as they're alive and the game isn't paused
		player.x = player.x + (dx * 2/3)
		player.y = player.y + (dy * 2/3)
	end
end

function love.mousepressed(x, y, button)
	if game_status.menu == "game_over" then
		game_status.menu = "pause"
	end
end

function love.wheelmoved(x, y)
	if player.alive and not player.hurt then
		if y > 0 then
			if player.form == "small" then
				player.form = "medium"
				player.height = player.medium_height
				player.y = player.y - ((player.medium_height - player.small_height) / 2)
			elseif player.form == "medium" then
				player.form = "large"
				player.height = player.large_height
				player.y = player.y - ((player.large_height - player.medium_height) / 2)
			end
		elseif y < 0 then
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
	end
end

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


function love.load(arg)
	-- this function is called when the game starts
	
	-- prepare game data and spawn game objects
	spawn.prepare_constant_data()
	
	-- reseed the random number generator
	love.math.setRandomSeed((math.floor(tonumber(os.date("%d")) / 10) + 1) * (tonumber(os.date("%w")) + 1) * tonumber(os.date("%I")) * (tonumber(os.date("%M")) + 1) * (math.floor(tonumber(os.date("%S")) / 12) + 1))
	
	player.width = player.appearance.small_sprite:getWidth()
	player.height = player.appearance.small_sprite:getHeight()
	
	love.graphics.setBackgroundColor(236, 240, 236)
	
	love.mouse.setRelativeMode(true)
	
	spawn.player(0, 235)
	
	player.form = "small"
	player.height = player.small_height
	
	game_status.menu = "pause"
end -- love.load


function love.update(dt)
	-- this function is called once per frame, contains game logic, and provides a delta-time variable
	
	-- check if the game window is being moved
	local temp_window_position = {x = nil, y = nil, display = nil}
	temp_window_position.x, temp_window_position.y, temp_window_position.display = love.window.getPosition()
	if game_status.window_position.x ~= temp_window_position.x or game_status.window_position.y ~= temp_window_position.y or game_status.window_position.display ~= temp_window_position.display then
		-- the game window is being moved, pause the game for player safety and game state integrity
		if game_status.menu == "none" then
			game_status.menu = "pause"
		end
		game_status.input_type = nil
		game_status.window_position.x, game_status.window_position.y, game_status.window_position.display = love.window.getPosition()
	end
	
	-- get the controls being pressed right now
	inbox.instant_press()
	
	local quick_detect = controls.quick_detect
	
	if quick_detect.up or quick_detect.down then
		player.vertical_speed = player.medium_speed
	end
	if quick_detect.left or quick_detect.right then
		player.horizontal_speed = player.medium_speed
	end
	
	-- poll the active controller's analog sticks and set various data relating to movement
	local sticks = controls.cnt.analog_sticks
	if controls.controller then
		inbox.stick_poll(dt)
		
		-- fudge the controls a bit
		if sticks.positions.left_vertical > sticks.slow_vertical_threshhold then
			controls.quick_detect.down = -1
		elseif sticks.positions.left_vertical < -sticks.slow_vertical_threshhold then
			controls.quick_detect.up = -1
		end
		
		if sticks.positions.left_horizontal > sticks.slow_horizontal_threshhold then
			controls.quick_detect.right = -1
		elseif sticks.positions.left_horizontal < -sticks.slow_horizontal_threshhold then
			controls.quick_detect.left = -1
		end
		
		-- set movement speeds in different directions
		if math.abs(sticks.positions.left_vertical) >= sticks.slow_vertical_threshhold then
			player.vertical_speed = player.low_speed
			if math.abs(sticks.positions.left_vertical) >= sticks.medium_vertical_threshhold then
				player.vertical_speed = player.medium_speed
				if math.abs(sticks.positions.left_vertical) >= sticks.fast_vertical_threshhold then
					player.vertical_speed = player.high_speed
				end
			end
		end
		
		if math.abs(sticks.positions.left_horizontal) >= sticks.slow_horizontal_threshhold then
			player.horizontal_speed = player.low_speed
			if math.abs(sticks.positions.left_horizontal) >= sticks.medium_horizontal_threshhold then
				player.horizontal_speed = player.medium_speed
				if math.abs(sticks.positions.left_horizontal) >= sticks.fast_horizontal_threshhold then
					player.horizontal_speed = player.high_speed
				end
			end
		end
	end
	
	if love.mouse.isDown(1) then
		quick_detect.main_attack = -1
	end
	
	if game_status.menu == "none" then
		-- run the main game logic
		
		local added_points = 0
		
		for enemy_index, selected_enemy in pairs(enemies.basic.locations) do
			-- loop over enemies
			
			-- move enemies
			if selected_enemy.horizontal_direction == "left" then
				selected_enemy.x = selected_enemy.x - selected_enemy.speed * dt
			elseif selected_enemy.horizontal_direction == "right" then
				selected_enemy.x = selected_enemy.x + selected_enemy.speed * dt
			end
			if selected_enemy.vertical_direction == "up" then
				selected_enemy.y = selected_enemy.y - selected_enemy.speed * dt
			elseif selected_enemy.vertical_direction == "down" then
				selected_enemy.y = selected_enemy.y + selected_enemy.speed * dt
			end
			
			-- check for collisions with the player
			if not player.hurt then
				if shc.check_collision(player.x, player.y, player.width, player.height, selected_enemy.x, selected_enemy.y, selected_enemy.width, selected_enemy.height, "full") then
					-- damage the player
					player.health = player.health - 1
					player.flinch_timer = 1
					player.hurt = true
				end
			end
			
			-- check for enemies leaving the screen
			if selected_enemy.x + selected_enemy.width < 0 or selected_enemy.x > love.graphics.getWidth() or selected_enemy.y + selected_enemy.height < 0 or selected_enemy.y > love.graphics.getHeight() then
				-- the enemy is off the screen, despawn it
				enemies.basic.locations[enemy_index] = enemies.basic.locations[#enemies.basic.locations]
				enemies.basic.locations[#enemies.basic.locations] = nil
			end
			
			-- check for player projectiles hitting an enemy
			for projectile_index, selected_projectile in pairs(player.small_projectiles) do
				if shc.check_collision(selected_projectile.x, selected_projectile.y, player.small_projectile_sprite:getWidth(), player.small_projectile_sprite:getHeight(), selected_enemy.x, selected_enemy.y, selected_enemy.width, selected_enemy.height, "full") then
					-- despawn the enemy
					enemies.basic.locations[enemy_index] = enemies.basic.locations[#enemies.basic.locations]
					enemies.basic.locations[#enemies.basic.locations] = nil
					if player.form ~= "large" then
						player.projectile_timer = 0.001
					end
					-- make an explosion
					spawn.explosion(selected_projectile.x + player.small_projectile_sprite:getWidth(), selected_projectile.y + (player.small_projectile_sprite:getHeight() / 2), 7, 14)
					-- add points
					added_points = added_points + 20
					if selected_enemy.vertical_direction ~= "none" then
						added_points = added_points + 10
					end
					if selected_enemy.horizontal_direction == "right" then
						added_points = added_points + 10
					end
					-- get rid of the projectile
					table.remove(player.small_projectiles, projectile_index)
				end
			end
			
			for projectile_index, selected_projectile in pairs(player.large_projectiles) do
				if shc.check_collision(selected_projectile.x, selected_projectile.y, player.large_projectile_sprite:getWidth(), player.large_projectile_sprite:getHeight(), selected_enemy.x, selected_enemy.y, selected_enemy.width, selected_enemy.height, "full") then
					-- despawn the enemy
					enemies.basic.locations[enemy_index] = enemies.basic.locations[#enemies.basic.locations]
					enemies.basic.locations[#enemies.basic.locations] = nil
					spawn.explosion(selected_projectile.x + player.large_projectile_sprite:getWidth(), selected_projectile.y + (player.large_projectile_sprite:getHeight() / 2), 7, 14)
					-- add points
					added_points = added_points + 20
					if selected_enemy.vertical_direction ~= "none" then
						added_points = added_points + 10
					end
					if selected_enemy.horizontal_direction == "right" then
						added_points = added_points + 10
					end
				end
			end
		end
		
		for projectile_index, selected_projectile in pairs(enemies.basic.projectiles.locations) do
			-- loop over enemy projectiles
			
			-- move projectiles
			selected_projectile.x = selected_projectile.x - enemies.basic.projectiles.speed * dt
			
			-- check for player collisions
			if not player.hurt then
				if shc.check_collision(selected_projectile.x, selected_projectile.y, enemies.basic.projectiles.width, enemies.basic.projectiles.height, player.x, player.y, player.width, player.height, "left") then
					-- damage the player
					player.health = player.health - 1
					player.flinch_timer = 1
					player.hurt = true
				end
			end
			
			-- check for player projectiles hitting an enemy projectile
			for player_projectile_index, selected_player_projectile in pairs(player.small_projectiles) do
				if shc.check_collision(selected_projectile.x, selected_projectile.y, enemies.basic.projectiles.width, enemies.basic.projectiles.height, selected_player_projectile.x, selected_player_projectile.y, player.small_projectile_sprite:getWidth(), player.small_projectile_sprite:getHeight(), "full") then
					-- the player hit an enemy projectile with their own, remove both
					if player.form ~= "large" then
						player.projectile_timer = 0.001
					end
					spawn.explosion(selected_player_projectile.x + player.small_projectile_sprite:getWidth(), selected_player_projectile.y + (player.small_projectile_sprite:getHeight() / 2), 4, 9)
					added_points = added_points + 10
					table.remove(enemies.basic.projectiles.locations, projectile_index)
					table.remove(player.small_projectiles, projectile_index)
				end
			end
			
			for player_projectile_index, selected_player_projectile in pairs(player.large_projectiles) do
				if shc.check_collision(selected_projectile.x, selected_projectile.y, enemies.basic.projectiles.width, enemies.basic.projectiles.height, selected_player_projectile.x, selected_player_projectile.y, player.large_projectile_sprite:getWidth(), player.large_projectile_sprite:getHeight(), "full") then
					-- the player hit an enemy projectile with their own
					spawn.explosion(selected_player_projectile.x + player.large_projectile_sprite:getWidth(), selected_player_projectile.y + (player.large_projectile_sprite:getHeight() / 2), 4, 9)
					added_points = added_points + 10
					table.remove(enemies.basic.projectiles.locations, projectile_index)
				end
			end
			
			if selected_projectile.x + enemies.basic.projectiles.width < 0 then
				-- remove projectiles that go off the screen
				table.remove(enemies.basic.projectiles.locations, projectile_index)
			end
		end
		
		-- manage player projectiles
		for projectile_index, selected_projectile in pairs(player.small_projectiles) do
			if selected_projectile.x >= love.graphics.getWidth() then
				table.remove(player.small_projectiles, projectile_index)
			elseif selected_projectile.x > 0 and selected_projectile.x < love.graphics.getWidth() then
				selected_projectile.x = selected_projectile.x + (player.projectile_speed * dt)
			end
		end
		
		for projectile_index, selected_projectile in pairs(player.large_projectiles) do
			if selected_projectile.x >= love.graphics.getWidth() then
				table.remove(player.large_projectiles, projectile_index)
			elseif selected_projectile.x > 0 and selected_projectile.x < love.graphics.getWidth() then
				selected_projectile.x = selected_projectile.x + (player.slow_projectile_speed * dt)
			end
		end
		
		game_status.points = game_status.points + added_points
		
		-- manage explosions
		for explosion_index, selected_explosion in pairs(map.explosions) do
			if selected_explosion.switch == "explode" then
				selected_explosion.size = selected_explosion.size + (dt * selected_explosion.speed)
				selected_explosion.first_ring_size = selected_explosion.size + 2
				selected_explosion.second_ring_size = selected_explosion.first_ring_size + 3
				if selected_explosion.size > selected_explosion.MAX_EXPLOSION then
					selected_explosion.switch = "implode"
				end
			elseif selected_explosion.switch == "implode" then
				selected_explosion.size = selected_explosion.size - (dt * selected_explosion.speed)
				selected_explosion.first_ring_size = selected_explosion.first_ring_size + (dt * selected_explosion.speed * 0.7)
				selected_explosion.second_ring_size = selected_explosion.second_ring_size + (dt * selected_explosion.speed * 0.5)
				if selected_explosion.size <= 2 then
					table.remove(map.explosions, explosion_index)
				end
			end
		end
		
		if player.alive then
			-- move the player
			if quick_detect.up < quick_detect.down then
				player.y = player.y - (player.vertical_speed * dt)
			elseif quick_detect.down < quick_detect.up then
				player.y = player.y + (player.vertical_speed * dt)
			end
			if quick_detect.left < quick_detect.right then
				player.x = player.x - (player.horizontal_speed * dt)
			elseif quick_detect.right < quick_detect.left then
				player.x = player.x + (player.horizontal_speed * dt)
			end
			
			-- keep the player on the screen
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
			
			-- manage player hurt state
			if player.hurt then
				if player.flinch_timer > 0 then
					player.flinch_timer = player.flinch_timer - dt
				elseif player.flinch_timer <= 0 then
					player.flinch_timer = 0
					player.hurt = false
				end
			end
			
			-- manage player projectile spawning
			if player.projectile_timer > 0 then
				player.projectile_timer = player.projectile_timer - dt
			elseif player.projectile_timer <= 0 then
				player.projectile_timer = 0
			end
			
			if quick_detect.main_attack < 0 then
				if player.form == "small" or player.form == "medium" then
					spawn.player_projectile(player.x + player.width, player.y + (player.height / 2) - (player.small_projectile_sprite:getHeight() / 2))
				elseif player.form == "large" then
					spawn.player_projectile(player.x + player.width, player.y + (player.height / 2) - (player.large_projectile_sprite:getHeight() / 2))
				end
			end
			
			-- manage player health and death
			if player.health <= 0 then
				player.spawn_timer = 3
				player.alive = false
			end
		elseif not player.alive then
			-- the player is dead
			if player.lives > 0 then
				player.spawn_timer = player.spawn_timer - dt
				if player.spawn_timer <= 0 then
					player.spawn_timer = 0
					player.flinch_timer = 0
					player.lives = player.lives - 1
					spawn.player(0, 235)
				end
			elseif player.lives <= 0 then
				-- game over
				game_status.menu = "game_over"
				enemies.basic.locations = {}
				enemies.basic.projectiles.locations = {}
				enemies.spawn_timer = 7
				enemies.spawn_latch = 2.70
				enemies.attack_timer = 8.5
				enemies.attack_latch = 1.35
				enemies.weight_wait = 12
				map.explosions = {}
				game_status.points = 0
				player.small_projectiles = {}
				player.large_projectiles = {}
				player.lives = 3
				spawn.player(0, love.graphics.getHeight() / 2)
			end
		end
		
		if enemies.spawn_timer > 0 then
			enemies.spawn_timer = enemies.spawn_timer - dt
			enemies.weight_wait = enemies.weight_wait - dt
		elseif enemies.spawn_timer <= 0 then
			-- spawn a new enemy
			local rand_x = util.weighted_random(750, 950, 880)
			local rand_y = util.weighted_random(30, 470, enemies.weight_point)
			spawn.enemy("standard", 31, 31, rand_x, rand_y, "random", "random", 100, 1)
			enemies.spawn_timer = enemies.spawn_latch
			if enemies.spawn_latch > 0.4 then
				enemies.spawn_latch = enemies.spawn_latch - (dt * 4)
			end
			enemies.weight_wait = enemies.weight_wait - dt
			if enemies.weight_wait <= 0 then
				enemies.weight_point = love.math.random(30, 470)
			end
		end
		
		if enemies.attack_timer > 0 then
			enemies.attack_timer = enemies.attack_timer - dt
		elseif enemies.attack_timer <= 0 and #enemies.basic.locations > 0 then
			local rand_enemy = math.floor(love.math.random(1, #enemies.basic.locations))
			if enemies.basic.locations[rand_enemy].x > game_status.threshhold then
				-- make a random enemy attack if it's not too close to the player
				table.insert(enemies.basic.projectiles.locations, {
					x = enemies.basic.locations[rand_enemy].x - enemies.basic.projectiles.width,
					y = enemies.basic.locations[rand_enemy].y
				})
			end
			enemies.attack_timer = enemies.attack_latch
			if enemies.attack_latch > 0.175 then
				enemies.attack_latch = enemies.attack_latch - (dt * 2.75)
			end
		end
		
		-- spawn stars
		map.stars.near_stars:spawn_stars(1, 5)
		map.stars.far_stars:spawn_stars(1, 3)
		
		for type_index, selected_type in pairs(map.stars) do
			local all_stale = true
			for group_index, selected_group in pairs(selected_type.groups) do
				-- iterate over groups of stars
				for star_index, selected_star in pairs(selected_group.locations) do
					-- move the stars in this group
					selected_star.x = selected_star.x - selected_type.speed
					selected_group.sprite_batch:set(selected_star.index, selected_type.quad, selected_star.x, selected_star.y)
					if selected_group.sprite_batch:getCount() > 950 then
						-- this group is full, stop adding to it
						selected_group.stale = true
					elseif selected_group.sprite_batch:getCount() <= 950 then
						all_stale = false
					end
					
					if selected_star.x < 0 then
						-- the stars in this group are off the screen, mark it for deletion
						selected_group.alive = false
					elseif selected_star.x >= 0 then
						selected_group.alive = true
					end
				end
			end
			if all_stale then
				-- create new star groups as all existing groups are full
				selected_type:spawn_group()
			end
		end
		
		for type_index, selected_type in pairs(map.stars) do
			for group_index, selected_group in pairs(selected_type.groups) do
				if selected_group.alive == false then
					-- delete invisible star groups
					selected_type[group_index] = nil
				end
			end
		end
	end
end -- love.update


function love.draw()
	-- draw the background
	for type_index, selected_type in pairs(map.stars) do
		for group_index, selected_group in pairs(selected_type.groups) do
			love.graphics.draw(selected_group.sprite_batch)
		end
	end
	
	-- manage stun flickering
	if player.hurt then
		if player.flicker_timer <= 0 then
			player.flicker_timer = player.flicker_max
		elseif player.flicker_timer > player.flicker_max / 2 then
			player.flicker_timer = player.flicker_timer - love.timer.getDelta()
			love.graphics.setColor(255, 255, 255, 255)
		elseif player.flicker_timer <= player.flicker_max / 2 then
			-- make the player sprite invisible briefly
			player.flicker_timer = player.flicker_timer - love.timer.getDelta()
			love.graphics.setColor(255, 255, 255, 0)
		end
	end
	
	-- draw the player
	if player.form == "small" then
		love.graphics.draw(player.appearance.small_sprite, player.x, player.y)
	elseif player.form == "medium" then
		love.graphics.draw(player.appearance.medium_sprite, player.x, player.y)
	elseif player.form == "large" then
		love.graphics.draw(player.appearance.large_sprite, player.x, player.y)
	end
	love.graphics.setColor(255, 255, 255, 255)
	
	-- draw enemies
	for enemy_index, selected_enemy in pairs(enemies.basic.locations) do
		love.graphics.draw(enemies.basic.sprite, selected_enemy.x, selected_enemy.y)
	end
	
	-- draw projectiles
	for projectile_index, selected_projectile in pairs(enemies.basic.projectiles.locations) do
		love.graphics.draw(enemies.basic.projectiles.sprite, selected_projectile.x, selected_projectile.y)
	end
	
	for projectile_index, selected_projectile in pairs(player.small_projectiles) do
		love.graphics.draw(player.small_projectile_sprite, selected_projectile.x, selected_projectile.y)
	end
	
	for projectile_index, selected_projectile in pairs(player.large_projectiles) do
		love.graphics.draw(player.large_projectile_sprite, selected_projectile.x, selected_projectile.y)
	end
	
	-- show explosions
	love.graphics.setColor(4, 16, 8)
	for explosion_index, selected_explosion in pairs(map.explosions) do
		love.graphics.circle("fill", selected_explosion.x, selected_explosion.y, selected_explosion.size)
		love.graphics.circle("line", selected_explosion.x, selected_explosion.y, selected_explosion.first_ring_size)
		love.graphics.circle("line", selected_explosion.x, selected_explosion.y, selected_explosion.second_ring_size)
	end
	love.graphics.setColor(255, 255, 255)
	
	-- draw UI
	love.graphics.setFont(game_status.interface_font)
	love.graphics.setColor(32, 224, 16)
	local hearts = ""
	if player.health == 3 then
		hearts = "❤︎❤︎❤︎"
	elseif player.health == 2 then
		hearts = "❤︎❤︎  "
	elseif player.health == 1 then
		hearts = "❤︎    "
	elseif player.health == 0 then
		hearts = "      "
	end
	love.graphics.printf("HEALTH: " .. hearts .. "   LIVES: " .. tostring(player.lives), 0, 12, love.graphics.getWidth(), "center")
	love.graphics.printf("POINTS: " .. tostring(game_status.points), 0, 26, love.graphics.getWidth(), "center")
	
	love.graphics.setFont(game_status.menu_font)
	if game_status.menu == "pause" then
		-- draw pause UI
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(32, 224, 16)
		love.graphics.printf("PAUSE", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("X TO QUIT", 0, 264, love.graphics.getWidth(), "center")
	elseif game_status.menu == "quit_check" then
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(32, 224, 16)
		love.graphics.printf("REALLY QUIT?", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("X TO QUIT", 0, 264, love.graphics.getWidth(), "center")
	elseif game_status.menu == "debug" then
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(32, 224, 16)
		love.graphics.printf("DEBUG", 0, 240, love.graphics.getWidth(), "center")
		love.graphics.printf("kill Player - take Health - Give health - kill Enemies - Full health - resurrecT player - console Debug", love.graphics.getWidth() * 3/8, 264, love.graphics.getWidth() / 4, "center")
	elseif game_status.menu == "game_over" then
		-- draw pause UI
		love.graphics.setColor(4, 16, 8)
		love.graphics.rectangle("fill", love.graphics.getWidth() * 3/8, 175, love.graphics.getWidth() / 4, 150)
		love.graphics.setColor(32, 224, 16)
		love.graphics.printf("GAME OVER", 0, 240, love.graphics.getWidth(), "center")
	end
end -- love.draw

-- this code copyright 2020 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
