-- This module handles spawning objects and items in the game.

local spawn = {}

function spawn.player(x, y)
	-- spawns the player
	
	-- set or reset various traits
	player.x = x
	player.y = y
	
	game_status.scroll_x = scroll_x
	game_status.scroll_y = scroll_y
	
	-- make the player alive
	player.spawn_timer = 3
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

function spawn.enemy(type, width, height, origin_x, origin_y, direction, speed, starting_health)
	-- place enemies of all kinds
	
	-- type indicates the type of enemy
	-- width indicates the width of an enemy, extending right from (origin_x, origin_y)
	-- height indicates the height of an enemy, extending down from (origin_x, origin_y)
	-- origin_x and origin_y indicate the upper left corner of an enemy relative to the top left of the map
	-- direction indicates the way the enemy should move
	-- starting_health indicates how many hit points of health the enemy has to begin with
	
	local type = type
	local width = width or 20
	local height = height or 48
	local origin_x = origin_x or 0
	local origin_y = origin_y or 0
	local starting_health = starting_health or 3
	local direction = direction or "random"
	local speed = speed
	
	local home_structure = nil
	local facing = nil
	local movement_switch = nil
	local hurt = false
	local flinch_timer = nil
	local death_timer = nil
	
	if direction == "random" then
		-- pick left or right at random
		if love.math.random() > 0.5 then
			direction = "left"
			facing = "left"
		else
			direction = "right"
			facing = "right"
		end
	end
	
	-- set the traits of this enemy
	local traits = {
		left_sprite = left_sprite,
		right_sprite = right_sprite,
		left_dead_sprite = left_dead_sprite,
		right_dead_sprite = right_dead_sprite,
		x = origin_x,
		y = origin_y,
		width = width,
		height = height,
		facing = facing,
		direction = direction,
		speed = speed,
		movement_switch = movement_switch,
		health = starting_health,
		hurt = hurt,
		flinch_timer = flinch_timer,
		death_timer = death_timer,
		attack = {
			state = "ready",
			duration = 0.070,
			cooldown = 0.175,
			hitbox = {
				x = 0,
				y = 0,
				width = map.enemies[type].left_attack_sprite:getWidth(),
				height = map.enemies[type].left_attack_sprite:getHeight()
			}
		}
	}
end -- spawn.enemy

function spawn.health(target, origin_x, origin_y, type)
	-- spawns an item the player can pick up to regain health
	
	-- target refers to the table to put the health pickup in
	-- origin_x and origin_y refer to the location the health pickup will spawn at
	-- type refers to how much health the pickup restores
	
	-- specifying a sprite for the health pickup is not supported because it should always be clear
	-- whether or not an item is a health pickup and which type of health pickup it is
	
	target = target or map.health_pickups.locations
	origin_x = origin_x
	origin_y = origin_y
	type = type or "single"
	local sprite = nil
	local amount = nil
	
	if type == "single" then
		-- spawn a pickup that restores 1 hit point
		sprite = map.health_pickups.single_health_sprite
		amount = 1
	elseif type == "double" then
		-- spawn a pickup that restores 2 hit points
		sprite = map.health_pickups.double_health_sprite
		amount = 2
	elseif type == "quadruple" then
		-- spawn a pickup that restores 4 hit points
		sprite = map.health_pickups.quad_health_sprite
		amount = 4
	end
	
	local traits = {
		x = origin_x,
		y = origin_y,
		width = sprite:getWidth(),
		height = sprite:getHeight(),
		type = type,
		sprite = sprite,
		amount = amount
	}
	
	table.insert(target, traits)
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
	
	-- load up and section out user interface graphics
	
	-- set up the sprite batch and texture atlas used for solid structures
	
	-- set up player sprites
	player.appearance.small_sprite = love.graphics.newImage("assets/ship-small.png")
	
	-- set up player attacks
	
	-- set up textures for enemies
	
	-- set up powerups
	
	-- set up the sprites for health items
	
	-- load the sprite for the level exit
	
end -- spawn.asset_prepare

return spawn

-- this library copyright 2016-20 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
