---- Small Hadron Collider ----
-- This module does simple axis-aligned bounding box collision detection and axial alignment checks.
-- It is designed for LOVE (love2d), but should work in any Lua environment.
-- Tests have plotted this as running about 7 figures less time per second than rendering.

shc = {}

function shc.check_collision(x1,y1,w1,h1, x2,y2,w2,h2, type)
	-- does a collision or alignment check for two objects using variations on an AABB model
	
	-- x1,y1,w1,h1 are the x and y coordinates and the width and height of the first object
	-- x2,y2,w2,h2 are the same traits (location and size) of the second object
	-- type is the type of collision or alignment to check for
	
	-- if the leading edge of an object passes through another object between directed collision checks,
	-- or if an entire object passes through another between any collision checks, the collision will be missed
	
	-- checks for collision along one direction use the same number of operations as "full" collision checks,
	-- and they catch 1-pixel overlaps while full collision detection fails to catch them
	-- making full collision catch everything correctly is projected to take 50-100% more operations to calculate
	
	local collision = false
	local positional_difference = 0
	
	if type == "left" then
		-- check for a collision from the left (of the first object)
		positional_difference = (x2 + w2) - x1
		if (positional_difference >= 0) and (positional_difference <= w2) and (y1 < y2 + h2) and (y2 < y1 + h1) then
			collision = true
		end
	elseif type == "right" then
		-- check for a collision from the right
		positional_difference = (x1 + w1) - x2
		if (positional_difference >= 0) and (positional_difference <= w1) and (y1 < y2 + h2) and (y2 < y1 + h1) then
			collision = true
		end
	elseif type == "top" or type == "up" then
		-- check for a collision from the top
		positional_difference = (y2 + h2) - y1
		if (positional_difference >= 0) and (positional_difference <= h2) and (x1 < x2 + w2) and (x2 < x1 + w1) then
			collision = true
		end
	elseif type == "bottom" or type == "down" then
		-- check for a collision from the bottom
		positional_difference = (y1 + h1) - y2
		if (positional_difference >= 0) and (positional_difference <= h1) and (x1 < x2 + w2) and (x2 < x1 + w1) then
			collision = true
		end
	elseif type == "vertical" then
		-- check for vertical alignment (objects stacked vertically)
		collision = (x1 <= x2 + w2) and (x2 <= x1 + w1)
	elseif type == "horizontal" then
		-- check for horizontal alignment
		collision = (y1 <= y2 + h2) and (y2 <= y1 + h1)
	elseif type == "full" then
		-- check for a collision of any type
		collision = (x1 < x2 + w2) and (x2 < x1 + w1) and (y1 < y2 + h2) and (y2 < y1 + h1)
	else
		-- erroneous call
		print("SHC: Invalid collision type: " .. tostring(type))
		print(debug.traceback())
	end
	
	return collision
end

return shc

-- this library copyright 2016-19 by GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
