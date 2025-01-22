local whitelist = {
	"ore",
	"diamond",
	"coal",
	"redstone",
	"appliedenergistics2",
	"turtle",
	"pearl",
	"valentines",
	"factory",
	"gravel",
	"flint",
	"quark",
	"charcoal",
}
local blacklist = { "snow", "turtle", "cable", "door", "engine", "pipe", "industrialforegoing", "disk" }
require("lib-network")
require("chunk-loader-client")

math.randomseed(os.epoch())

Day = os.day()

local import_x = 455
local import_y = 17
local import_z = 494
local minerProtocol = "miners"
-- local manager = rednet.lookup(minerProtocol)
local directions = { "+x", "+z", "-x", "-z" }
DirectionIndex = 0

local function locate()
	local x, y, z
	while true do
		x, y, z = gps.locate()
		if x == x and y == y and z == z then
			break
		end
	end
	print("gps:", x, y, z)
	return x, y, z
end

local function calibrateDirection()
	local x, y, z = locate()
	while turtle.detect() do
		turtle.turnRight()
	end
	turtle.forward()
	local new_x, new_y, new_z = locate()
	local sub_x = new_x - x
	local sub_z = new_z - z
	if sub_x > 0 then
		DirectionIndex = 1
	elseif sub_x < 0 then
		DirectionIndex = 3
	end
	if sub_z > 0 then
		DirectionIndex = 2
	elseif sub_z < 0 then
		DirectionIndex = 4
	end
	turtle.back()
end

local collected = 0
local height = 5

local function collect()
	collected = collected + 1
	if math.fmod(collected, 25) == 0 then
		print("Mined " .. collected .. " items.")
	end
end

local function turnLeft()
	turtle.turnLeft()
	DirectionIndex = DirectionIndex - 1
	if DirectionIndex <= 0 then
		DirectionIndex = 4
	end
	return true
end

local function turnRight()
	turtle.turnRight()
	DirectionIndex = DirectionIndex + 1
	if DirectionIndex >= 5 then
		DirectionIndex = 1
	end
	return true
end

local function tryDig()
	while turtle.detect() do
		local blocked = false
		local has_block, data = turtle.inspect()
		if has_block then
			for _, value in ipairs(blacklist) do
				if string.find(data.name, value) then
					blocked = true
					break
				end
			end
		end
		if not blocked then
			if turtle.dig() then
				collect()
				sleep(0.5)
			else
				return false
			end
		elseif string.find(data.name, "turtle") then
			sleep(5)
			tryDig()
		else
			rand = math.random(1, 4)
			if rand == 1 then
				turnLeft()
				tryDig()
				turtle.forward()
				turnRight()
			elseif rand == 2 then
				tryUp()
			elseif rand == 3 then
				tryDown()
			else
				turnRight()
				tryDig()
				turtle.forward()
				turnLeft()
			end
		end
	end
	return true
end

local function tryDigUp()
	while turtle.detectUp() do
		local blocked = false
		local has_block, data = turtle.inspectUp()
		for _, value in ipairs(blacklist) do
			if string.find(data.name, value) then
				blocked = true
				break
			end
		end
		if not blocked then
			if turtle.digUp() then
				collect()
				sleep(0.5)
			else
				return false
			end
		else
			if string.find(data.name, "turtle") then
				sleep(5)
				tryDigUp()
			end
		end
	end
	return true
end

local function tryDigDown()
	while turtle.detectDown() do
		local blocked = false
		local has_block, data = turtle.inspectDown()
		if has_block then
			for _, value in ipairs(blacklist) do
				if string.find(data.name, value) then
					blocked = true
					break
				end
			end
		end
		if not blocked then
			if turtle.digDown() then
				collect()
				sleep(0.5)
			else
				return false
			end
		else
			if string.find(data.name, "turtle") then
				sleep(10)
				tryDigDown()
			end
		end
	end
	return true
end

local function handleInv()
	local usedSlots = 0
	local cobblestoneMissing = false
	for i = 1, 16, 1 do
		local whitelistCounter = 0
		local itemCount = turtle.getItemCount(i)
		local item = turtle.getItemDetail(i)
		if item then
			item = item.name
			if cobblestoneMissing and string.find(item, "cobblestone") then
				turtle.select(i)
				turtle.transferTo(1)
				turtle.select(1)
				cobblestoneMissing = false
			end
			if not string.find(item, "cobblestone") and i == 1 then
				cobblestoneMissing = true
				turtle.transferTo(16 - i)
			end
			if itemCount > 0 then
				usedSlots = usedSlots + 1
				for _, value in ipairs(whitelist) do
					if string.find(item, value) or i == 1 and string.find(item, "cobblestone") then
						whitelistCounter = whitelistCounter + 1
					end
				end
			end
			if whitelistCounter == 0 then
				turtle.select(i)
				turtle.dropUp()
				turtle.select(1)
			end
		end
	end
	return usedSlots
end

local function refuel(target_fuel)
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" or turtle.getFuelLevel() > target_fuel then
		return false
	end
	for n = 1, 16 do
		if turtle.getItemCount(n) > 0 then
			turtle.select(n)
			turtle.refuel()
			turtle.select(1)
		end
	end
	turtle.select(1)
end

local function tryUp()
	while not turtle.up() do
		if turtle.detectUp() then
			if not tryDigUp() then
				return false
			end
		elseif turtle.attackUp() then
			collect()
		else
			sleep(0.5)
		end
	end
	return true
end

local function tryDown()
	while not turtle.down() do
		if turtle.detectDown() then
			if not tryDigDown() then
				return false
			end
		elseif turtle.attackDown() then
			collect()
		else
			sleep(0.5)
		end
	end
	return true
end

local function tryForward()
	HandleChunkLoader()
	while not turtle.forward() do
		if turtle.detect() then
			if not tryDig() then
				return false
			end
		elseif turtle.attack() then
			collect()
		else
			sleep(0.5)
		end
	end
	return true
end

local function handleUsername(protocol)
	if fs.exists("username") then
		local file = fs.open("username", "r")
		local result = file.readAll()
		file.close()
		return result
	end
	print("Enter username: ")
	local input = read()
	Register(input, protocol)
	local senderID, message = rednet.receive(protocol, 10)
	if message == "201" then
		print("Registered " .. input)
		local file = fs.open("username", "w")
		file.writeLine(input)
		file.close()
	else
		print("name is taken. Try again? (Y/n)")
		input2 = read()
		if input2 == "n" then
			local file = fs.open("username", "w")
			file.writeLine(input)
			file.close()
		else
			handleUsername(protocol)
		end
	end
	return input
end

local function tunnel()
	local height = 5
	turtle.placeDown()
	turnLeft()
	for i = 1, height, 1 do
		tryDig()
		if i ~= height then
			tryDigUp()
			tryUp()
		end
	end
	turnRight()
	turnRight()
	tryDig()
	for j = 1, height, 1 do
		tryDig()
		if j ~= height then
			tryDown()
		end
	end
	turnLeft()
end

local function orient(direction)
	if direction == "+x" then
		while true do
			if directions[DirectionIndex] ~= "+x" then
				turnRight()
			else
				break
			end
		end
	elseif direction == "-x" then
		while true do
			if directions[DirectionIndex] ~= "-x" then
				turnRight()
			else
				break
			end
		end
	elseif direction == "+z" then
		while true do
			if directions[DirectionIndex] ~= "+z" then
				turnRight()
			else
				break
			end
		end
	elseif direction == "-z" then
		while true do
			if directions[DirectionIndex] ~= "-z" then
				turnRight()
			else
				break
			end
		end
	end
end

local function gotoCoords(goal_x, goal_y, goal_z)
	print("goal:", goal_x, goal_y, goal_z)
	local x, y, z = locate()
	print("self:", x, y, z)
	local dist_x = goal_x - x
	local dist_y = goal_y - y
	local dist_z = goal_z - z
	print("dist:", dist_x, dist_y, dist_z)
	local dist = dist_x + dist_z
	if dist_y > 0 then
		for _ = 1, dist_y, 1 do
			tryDigUp()
			turtle.up()
		end
	elseif dist_y < 0 then
		for _ = 1, math.abs(dist_y), 1 do
			tryDigDown()
			turtle.down()
		end
	end
	if dist_x > 0 then
		orient("+x")
	elseif dist_x < 0 then
		orient("-x")
	end
	for i = 1, math.abs(dist_x), 1 do
		tryForward()
	end
	if dist_z > 0 then
		orient("+z")
	elseif dist_z < 0 then
		orient("-z")
	end
	for j = 1, math.abs(dist_z), 1 do
		tryForward()
	end
	local x, y, z = locate()
	if x == goal_x and y == goal_y and z == goal_z then
		print("at goal")
	else
		print("failed! Rebooting")
		sleep(5)
		os.reboot()
	end
end

local function dock()
	local export_x = 453
	local export_y = 17
	local export_z = 495
	local x, y, z = locate()

	local target_fuel = 10000

	if x == import_x and z == import_z then
		print("no need to go down")
		print("reason:")
		print(x, "==", import_x)
		print("or")
		print(z, "==", import_z)
	else
		gotoCoords(import_x, 13, import_z)
	end
	gotoCoords(import_x, import_y, import_z)
	orient("+z")
	while usedSlots > 0 do
		usedSlots = handleInv()
		sleep(0.05)
	end
	local x, y, z = locate()
	gotoCoords(x, y, z + 1)
	gotoCoords(export_x, export_y, export_z)
	local x, y, z = locate()
	if x == export_x and y == export_y and z == export_z then
		while turtle.getFuelLevel() < target_fuel do
			refuel(target_fuel)
			print(turtle.getFuelLevel() .. "/" .. target_fuel)
			sleep(0.05)
		end
		gotoCoords(export_x, 13, export_z)
	else
		os.reboot()
	end
end

local function test_goto()
	local x, y, z = locate()
	gotoCoords(x + 10, 13, z + 10)
	gotoCoords(x, y, z)
end

local function shouldReturn()
	local fuel = turtle.getFuelLevel()
	local x, _, z = locate()
	local dist_x = math.abs(import_x - x)
	local dist_z = math.abs(import_z - z)
	local dist = dist_x + dist_z
	if math.floor(fuel * 0.9) < dist then
		return true
	else
		return false
	end
end

local function errorHandler(err)
	print("ERROR:", err)
	sleep(10)
	os.reboot()
end

-- test_goto()
local function main()
	refuel(64)
	calibrateDirection()
	while true do
		usedSlots = handleInv()
		print("docking...")
		dock()
		usedSlots = handleInv()
		while usedSlots < 16 and not shouldReturn() do
			term.clear()
			print("id:", os.getComputerID())
			print("fuel level:", turtle.getFuelLevel())
			sleep(0.05)
			local rand = math.random(1, 4)
			orient(directions[rand])
			lenght = math.random(1, 200)
			local x, y, z = locate()
			local dist_x = math.abs(import_x - x)
			local dist_z = math.abs(import_z - z)
			local dist = dist_x + dist_z
			if dist > 200 then
				rand = math.random(1, 2)
				if rand == 1 then
					gotoCoords(x, 41, z)
				else
					gotoCoords(x, 12, z)
				end
			else
				gotoCoords(x, 12, z)
			end
			for i = 1, lenght, 1 do
				print(i .. "/" .. lenght)
				if turtle.detect() then
					local has_block, data = turtle.inspect()
					if data.name then
						if string.find(data.name, "turtle") then
							break
						end
					end
				end
				tryForward()
				local data = { name = "" }
				if turtle.detectUp() then
					local has_block, data = turtle.inspectUp()
					if data.name then
						if not string.find(data.name, "turtle") then
							local x, y, z = locate()
							if dist > 200 and rand == 1 then
								gotoCoords(x, 40, z)
							else
								gotoCoords(x, 12, z)
							end
							tunnel()
							usedSlots = handleInv()
							if usedSlots == 16 or shouldReturn() then
								break
							end
						end
					end
				end
			end

			usedSlots = handleInv()
		end

		local msg = "Mined " .. collected .. " items total."
		-- Print(msg, username, "home")
		print(msg)
		os.reboot()
	end
end
xpcall(main, errorHandler)
