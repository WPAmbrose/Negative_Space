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

function util.table_copy(existing_table)
	-- create a copy of a table, including all subtables
	-- this creates a second set of data, with nothing linking the tables
	
	local new_table = {}
	
	for key, value in pairs(existing_table) do
		if type(value) ~= "table" then
			new_table[key] = value
		elseif type(value) == "table" then
			new_table[key] = util.table_copy(value)
		end
	end
	
	return new_table
end

function util.easy_reset(main_table)
	-- use the current values in the supplied table to enable easy resetting of values in it
	-- setting a value to nil will reset it to its value before this function was called
	
	main_table._defaults = {}
	for key, value in pairs(main_table) do
		main_table._defaults[key] = value
	end
	
	setmetatable(main_table, main_table._defaults)
	
	main_table._defaults.__index = function (table, key)
		return main_table._defaults[key]
	end
	
	for key, value in pairs(main_table) do
		if type(value) == "table" and tostring(key) ~= "_defaults" then
			util.easy_reset(main_table[key])
		end
	end
end

return util
