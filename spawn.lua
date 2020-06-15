-- This module handles spawning objects and items in the game.

local spawn = {}

function spawn.player(x, y)
	-- spawns the player
	
	player.x = x
	player.y = y
	player.spawn_timer = 0
	player.hurt = false
	player.flinch_timer = 0
	player.health = player.max_health
	player.alive = true
	
	-- debugging help
	if game_status.debug_messages then
		print(string.format("Player spawned at: %.3f, %.3f", player.x, player.y))
		game_status.debug_text = string.format("Player spawned at: %.3f, %.3f", player.x, player.y)
	end
end -- spawn.player

function spawn.player_projectile(x, y)
	-- create player-originated projectiles
	
	if player.projectile_timer == 0 then
		for projectile_index, selected_projectile in pairs(player.projectiles) do
			-- create a new projectile
			if selected_projectile.x <= -99 then
				selected_projectile.x = x
				selected_projectile.y = y
				player.projectile_timer = 0.800
				
				-- debugging help
				if game_status.debug_messages then
					print(string.format("Player projectile spawned at: %.3f, %.3f", selected_projectile.x, selected_projectile.y))
					game_status.debug_text = string.format("Player projectile spawned at: %.3f, %.3f", selected_projectile.x, selected_projectile.y)
				end
				
				break
			end
		end
	end
end -- spawn.player_projectile

function spawn.enemy(type, width, height, origin_x, origin_y, horizontal_direction, vertical_direction, speed, starting_health)
	-- place enemies of all kinds
	
	-- type indicates the type of enemy
	-- width indicates the width of an enemy, extending right from (origin_x, origin_y)
	-- height indicates the height of an enemy, extending down from (origin_x, origin_y)
	-- origin_x and origin_y indicate the upper left corner of an enemy relative to the top left of the map
	-- direction indicates the way the enemy should move
	-- starting_health indicates how many hit points of health the enemy has to begin with
	
	local type = type
	local width = width or 31
	local height = height or 31
	local origin_x = origin_x
	local origin_y = origin_y
	local horizontal_direction = horizontal_direction or "random"
	local vertical_direction = vertical_direction or "random"
	local speed = speed or 100
	local starting_health = starting_health or 1
	
	local movement_switch = nil
	local hurt = false
	local flinch_timer = nil
	local death_timer = nil
	
	if horizontal_direction == "random" then
		-- pick a direction at random
		local pathway = love.math.random()
		if pathway <= 0.70 then
			horizontal_direction = "left"
		elseif pathway > 0.70 then
			horizontal_direction = "right"
		end
		if vertical_direction ~= "random" then
			-- randomly give this no horizontal component, provided there's a vertical component
			pathway = love.math.random()
			if pathway > 0.35 then
				horizontal_direction = "none"
			end
		end
	end
	if vertical_direction == "random" then
		-- pick a direction at random
		local pathway = love.math.random()
		if pathway <= 0.50 then
			vertical_direction = "up"
		elseif pathway > 0.50 then
			vertical_direction = "down"
		end
		if horizontal_direction ~= "none" then
			-- randomly give this no vertical component, provided there's a horizontal component
			pathway = love.math.random()
			if pathway > 0.65 then
				vertical_direction = "none"
			end
		end
	end
	
	-- set the traits of this enemy
	local traits = {
		x = origin_x,
		y = origin_y,
		width = width,
		height = height,
		facing = facing,
		horizontal_direction = horizontal_direction,
		vertical_direction = vertical_direction,
		speed = speed,
		health = starting_health,
		hurt = hurt,
		death_timer = death_timer,
		attack = {
			state = "ready",
			cooldown = 0.175
		}
	}
	
	if type == "standard" then
		table.insert(enemies.basic.locations, traits)
	end
end -- spawn.enemy

function spawn.star_group(type)
	-- create a new star group
	
	local traits = {
		sprite_batch = love.graphics.newSpriteBatch(type.image),
		alive = true,
		stale = false,
		locations = {}
	}
	table.insert(type.groups, traits)
end

function spawn.stars(type, lower, upper)
	-- spawn a number of the given type of stars ranging from lower to upper
	
	-- do some setup
	if type == "near" then
		type = map.stars.near_stars
	elseif type == "far" then
		type = map.stars.far_stars
	end
	
	-- select the active star group
	local target = nil
	for group_index, selected_group in pairs(type.groups) do
		if not stale then
			target = selected_group
		end
	end
	
	-- calculate positions
	local star_count = love.math.random(lower, upper)
	for star = 1, star_count do
		local weight = love.math.random(1, love.graphics.getHeight())
		local star_x = love.graphics.getWidth() - 1
		local star_y = util.weighted_random(1, love.graphics.getHeight(), weight)
		-- add a star
		local quad_index = target.sprite_batch:add(type.quad, star_x, star_y)
		local traits = {
			index = quad_index,
			x = star_x,
			y = star_y
		}
		table.insert(target.locations, traits)
	end
end -- spawn.stars

function spawn.explosion(x, y, starting_size, MAX)
	-- spawn an expanding explosion graphic
	
	local traits = {
		x = x,
		y = y,
		switch = "explode",
		size = starting_size,
		MAX_EXPLOSION = MAX
	}
	
	table.insert(map.explosions, traits)
end

function spawn.prepare_constant_data()
	-- set up data that will be needed throughout the game, mostly assets but also other unchanging data
	
	-- check the operating system
	game_status.OS = love.system.getOS()
	
	-- set up a dummy structure if there are no controllers connected
	if not controls.controller then
		controls.controller = {
			isGamepadDown = function ()
				return nil
			end,
			getGamepadAxis = function ()
				return 0
			end
		}
	end
	
	-- make sprites look clear and not blurry regardless of position
	love.graphics.setDefaultFilter("nearest", "nearest")
	
	-- load the UI font
	game_status.font = love.graphics.newFont("assets/DejaVuSans.ttf", 12)
	
	-- set up the background
	map.stars.near_stars.image = love.graphics.newImage("assets/near-star.png")
	map.stars.near_stars.quad = love.graphics.newQuad(0, 0, 2, 2, 2, 2)
	table.insert(map.stars.near_stars.groups, {sprite_batch = love.graphics.newSpriteBatch(map.stars.near_stars.image), stale = false, alive = true, locations = {} } )
	
	map.stars.far_stars.image = love.graphics.newImage("assets/far-star.png")
	map.stars.far_stars.quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)
	table.insert(map.stars.far_stars.groups, {sprite_batch = love.graphics.newSpriteBatch(map.stars.far_stars.image), stale = false, alive = true, locations = {} } )
	
	-- set up player sprites
	player.appearance.small_sprite = love.graphics.newImage("assets/ship-small.png")
	player.appearance.medium_sprite = love.graphics.newImage("assets/ship-medium.png")
	player.appearance.large_sprite = love.graphics.newImage("assets/ship-large.png")
	
	player.small_height = player.appearance.small_sprite:getHeight()
	player.medium_height = player.appearance.medium_sprite:getHeight()
	player.large_height = player.appearance.large_sprite:getHeight()
	
	-- set up player attacks
	player.projectile_sprite = love.graphics.newImage("assets/player-projectile.png")
	
	-- set up textures for enemies
	enemies.basic.sprite = love.graphics.newImage("assets/basic-enemy.png")
	
	-- load enemy attack sprites
	enemies.basic.projectiles.sprite = love.graphics.newImage("assets/gear.png")
end -- spawn.prepare_constant_data

return spawn

-- this library copyright 2016-20 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
