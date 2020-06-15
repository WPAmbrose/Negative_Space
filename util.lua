-- This is a general utility module, including things such as math and table functions.

local util = {}

function util.round(number_in, place)
	-- round a floating point number with optional place value to round to, biased away from zero
	
	if place then
		return math.floor(number_in / place + 0.5) * place
	else
		return math.floor(number_in + 0.5)
	end
end

function util.weighted_random(bottom, top, weight)
	-- this function generates a random number that's weighted towards a specified point
	
	-- bottom and top indicate the range the random number can possibly be in
	-- weight indicates the point to weight the output towards; this should be between bottom and top
	
	local full_random = 0
	local constrained_random = 0
	
	full_random = love.math.random(bottom, top)
	
	if full_random > weight then
		constrained_random = love.math.random(full_random, weight)
	elseif full_random < weight then
		constrained_random = love.math.random(weight, full_random)
	elseif full_random == weight then
		constrained_random = full_random
	end
	
	return constrained_random
end

return util

-- this library copyright 2019-20 GV (WPA) and licensed only under Apache License Version 2.0
-- cf https://www.apache.org/licenses/LICENSE-2.0
