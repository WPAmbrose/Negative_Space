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
		print(string.format("Player spawned at: %.3f, %.3f on structure: %d", player.x, player.y, player.movement.current_structure))
		game_status.debug_text = string.format("Player spawned at: %.3f, %.3f on structure: %d", player.x, player.y, player.movement.current_structure)
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
	
	for structure_index, selected_structure in pairs(map.structures.collideables) do
		if (origin_x + width / 2 >= selected_structure.x and origin_x + width / 2 <= selected_structure.x + selected_structure.width) and (origin_y + height >= selected_structure.y - selected_structure.height and origin_y + height <= selected_structure.y + 8) then
			home_structure = structure_index
			origin_y = selected_structure.y - height
			break
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
		home_structure = home_structure,
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

function spawn.interface_fixed_data()
	-- set up interface data such as menu item names, touch region locations, and different colors
	
	-- set up commonly used menu data that will be inherited
	menu_data.template[0] = {}
	menu_data.template[0].title_color = {240, 240, 192, 255}
	menu_data.template[0].title_limit = love.graphics.getWidth()
	menu_data.template[0].title_x = 0
	menu_data.template[0].title_y = 0
	menu_data.template[0].rectangle_gap = 8
	menu_data.template[0].title_gap = 24
	menu_data.template[0].item_gap = 18
	menu_data.template[0].item_color = {240, 255, 192, 224}
	menu_data.template[0].selected_item_color = {64, 255, 128, 255}
	menu_data.template[0].item_align = "center"
	
	menu_data.pause[0] = {}
	menu_data.pause[0].rectangle_x = love.graphics.getWidth() / 4
	menu_data.pause[0].rectangle_y = 106
	menu_data.pause[0].rectangle_width = love.graphics.getWidth() / 2
	menu_data.pause[0].rectangle_height = 150
	menu_data.pause[0].title = "G A M E   P A U S E D"
	menu_data.pause[0].item_limit = love.graphics.getWidth()
	menu_data.pause[0].item_count = 6
	
	spawn.menu_procedural_data(menu_data.pause, 0, -4)
	menu_data.pause[0].title_color = {240, 240, 240, 255}
	
	menu_data.pause[1].title = "RESUME"
	menu_data.pause[1].selected_x = -5
	menu_data.pause[2].title = "CONTROLS"
	menu_data.pause[2].selected_x = -4
	menu_data.pause[3].title = "VOLUME: "
	menu_data.pause[3].selected_x = -4
	menu_data.pause[4].title = "FULL SCREEN"
	menu_data.pause[4].selected_x = -5
	menu_data.pause[5].title = "SAVE"
	menu_data.pause[5].selected_x = -4
	menu_data.pause[6].title = "QUIT"
	menu_data.pause[6].selected_x = -4
	
	menu_data.controls[0] = {}
	menu_data.controls[0].rectangle_x = love.graphics.getWidth() / 4
	menu_data.controls[0].rectangle_y = 72
	menu_data.controls[0].rectangle_width = love.graphics.getWidth() / 2
	menu_data.controls[0].rectangle_height_kb = 260
	menu_data.controls[0].rectangle_height_cnt = 278
	menu_data.controls[0].rectangle_height_tch = 278
	menu_data.controls[0].title_kb = "ASSIGN KEYBOARD CONTROLS"
	menu_data.controls[0].title_cnt = "ASSIGN CONTROLLER CONTROLS"
	menu_data.controls[0].title_tch = "MOVE TOUCH CONTROLS"
	menu_data.controls[0].item_limit = love.graphics.getWidth() / 2
	menu_data.controls[0].item_count = 13
	
	spawn.menu_procedural_data(menu_data.controls, love.graphics.getWidth() / 4 + 13, -9)
	menu_data.controls[0].item_align = "left"
	
	menu_data.controls[1].title = "Main attack: "
	menu_data.controls[2].title = "Ability: "
	menu_data.controls[3].title = "Climb: "
	menu_data.controls[4].title = "Pause: "
	menu_data.controls[5].title = "Walk left: "
	menu_data.controls[6].title = "Walk right: "
	menu_data.controls[7].title = "Ascend/Scroll up: "
	menu_data.controls[8].title = "Descend/Scroll down: "
	menu_data.controls[9].title = "Enter door: "
	menu_data.controls[10].title = "Back out: "
	menu_data.controls[11].title = "Accept selection: "
	menu_data.controls[12].controller_title = "Analog stick settings"
	
	menu_data.controls[13].x = love.graphics.getWidth() / 4
	menu_data.controls[13].edit = {}
	menu_data.controls[13].edit.title = "Press new control"
	menu_data.controls[13].edit.color = {64, 255, 128, 240}
	menu_data.controls[13].clash = {}
	menu_data.controls[13].clash.title = "That control clashes with the opposite control"
	menu_data.controls[13].clash.color = {240, 96, 32, 240}
	menu_data.controls[13].cross = {}
	menu_data.controls[13].cross.keyboard_title = "Enter here with a controller to change its controls"
	menu_data.controls[13].cross.controller_title = "Enter here with a keyboard to change its controls"
	menu_data.controls[13].cross.color = {240, 96, 32, 240}
	
	menu_data.sticks[0] = {}
	menu_data.sticks[0].rectangle_x = (love.graphics.getWidth() / 4) - (love.graphics.getWidth() / 16)
	menu_data.sticks[0].rectangle_y = 108
	menu_data.sticks[0].rectangle_width = (love.graphics.getWidth() / 2) + (love.graphics.getWidth() / 8)
	menu_data.sticks[0].rectangle_height = 128
	menu_data.sticks[0].title = "ANALOG STICK SETTINGS"
	menu_data.sticks[0].item_limit = love.graphics.getWidth()
	menu_data.sticks[0].item_count = 5
	
	spawn.menu_procedural_data(menu_data.sticks, 0, -4)
	
	menu_data.sticks[1].title = "Active analog stick: "
	menu_data.sticks[1].selected_x = -5
	menu_data.sticks[2].title = "Axis inversion: "
	menu_data.sticks[2].selected_x = -4
	menu_data.sticks[3].title = "Horizontal sensitivity: "
	menu_data.sticks[3].selected_x = -5
	menu_data.sticks[4].title = "Vertical sensitivity: "
	menu_data.sticks[4].selected_x = -4
	
	menu_data.sticks[5].sensitivity = {}
	menu_data.sticks[5].sensitivity.horizontal_title = "Hold stick at desired horizontal threshhold, then press "
	menu_data.sticks[5].sensitivity.vertical_title = "Hold stick at desired vertical threshhold, then press "
	menu_data.sticks[5].sensitivity.color = {64, 255, 128, 240}
	menu_data.sticks[5].cross = {}
	menu_data.sticks[5].cross.title = "Use a controller to change these settings"
	menu_data.sticks[5].cross.color = {240, 96, 32, 240}
	
	menu_data.save[0] = {}
	menu_data.save[0].rectangle_x = love.graphics.getWidth() / 8 * 3
	menu_data.save[0].rectangle_y = 106
	menu_data.save[0].rectangle_width = love.graphics.getWidth() / 4
	menu_data.save[0].rectangle_height = 96
	menu_data.save[0].title = "SAVE OPTIONS"
	menu_data.save[0].item_limit = love.graphics.getWidth()
	menu_data.save[0].item_count = 3
	
	spawn.menu_procedural_data(menu_data.save, 0, -4)
	
	menu_data.save[1].title = "Save game"
	menu_data.save[1].selected_x = -5
	menu_data.save[2].title = "Clear save data"
	menu_data.save[2].selected_x = -4
	menu_data.save[3].title = "Cancel"
	menu_data.save[3].selected_x = -4
	
	menu_data.quit[0] = {}
	menu_data.quit[0].rectangle_x = love.graphics.getWidth() / 8 * 3
	menu_data.quit[0].rectangle_y = 106
	menu_data.quit[0].rectangle_width = love.graphics.getWidth() / 4
	menu_data.quit[0].rectangle_height = 80
	menu_data.quit[0].title = "QUIT THE GAME?"
	menu_data.quit[0].item_limit = love.graphics.getWidth()
	menu_data.quit[0].item_count = 2
	
	spawn.menu_procedural_data(menu_data.quit, 0, -4)
	
	menu_data.quit[1].title = "Keep playing"
	menu_data.quit[1].selected_x = -5
	menu_data.quit[2].title = "End the game"
	menu_data.quit[2].selected_x = -4
	
	menu_data.touch.inactive_color = {224, 224, 224, 192}
	menu_data.touch.active_color = {224, 224, 224, 224}
end -- spawn.interface_fixed_data

function spawn.menu_procedural_data(menu, x_position, selected_x)
	-- set up menu data that is the same for each menu in the game
	for key, value in pairs(menu_data.template[0]) do
		menu[0][key] = value
	end
	menu[0].title_y = menu[0].rectangle_y + menu[0].rectangle_gap
	
	-- set up menu data that doesn't change between items in a menu
	for index = 1, menu[0].item_count do
		menu[index] = {}
		menu[index].color = menu[0].item_color
		menu[index].x = x_position
		menu[index].selected_x = selected_x
		menu[index].y = menu[0].title_y + menu[0].title_gap + (menu[0].item_gap * index) - menu[0].item_gap
	end
end

return spawn

-- this library copyright 2016-20 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
