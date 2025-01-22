local whitelist = { "ore", "diamond", "coal", "redstone", "appliedenergistics2", "torch" }
require("lib-network")
local height = 5

if not turtle then
	printError("Requires a Turtle")
	return
end

local tArgs = { ... }
if #tArgs ~= 1 then
	print("Usage: tunnel <length>")
	return
end

-- Mine in a quarry pattern until we hit something we can't dig
local length = tonumber(tArgs[1])
if length < 1 then
	print("Tunnel length must be positive")
	return
end
local collected = 0

local function collect()
	collected = collected + 1
	if math.fmod(collected, 25) == 0 then
		print("Mined " .. collected .. " items.")
	end
end

local function tryDig()
	while turtle.detect() do
		if turtle.dig() then
			collect()
			sleep(0.5)
		else
			return false
		end
	end
	return true
end

local function tryDigUp()
	while turtle.detectUp() do
		if turtle.digUp() then
			collect()
			sleep(0.5)
		else
			return false
		end
	end
	return true
end

local function tryDigDown()
	while turtle.detectDown() do
		if turtle.digDown() then
			collect()
			sleep(0.5)
		else
			return false
		end
	end
	return true
end

local function dumpTrash()
	for i = 2, 16, 1 do
		local counter = 0
		for _, value in ipairs(whitelist) do
			if turtle.getItemCount(i) > 0 then
				local item = turtle.getItemDetail(i).name
				if string.find(item, value) then
					counter = counter + 1
				end
			end
		end
		if counter == 0 then
			turtle.select(i)
			turtle.dropUp()
			turtle.select(1)
		end
	end
end

local function refuel()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" or fuelLevel > 0 then
		return
	end

	local function tryRefuel()
		for n = 1, 16 do
			if turtle.getItemCount(n) > 0 then
				turtle.select(n)
				if turtle.refuel(1) then
					turtle.select(1)
					return true
				end
			end
		end
		turtle.select(1)
		return false
	end

	if not tryRefuel() then
		print("Add more fuel to continue.")
		Send(username, "home", "Add more fuel to continue.")
		while not tryRefuel() do
			os.pullEvent("turtle_inventory")
		end
		print("Resuming Tunnel.")
	end
end

local function tryUp()
	refuel()
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
	refuel()
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
	refuel()
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
		input = read()
		if input == "n" then
			local file = fs.open("username", "w")
			file.writeLine(input)
			file.close()
		else
			handleUsername(protocol)
		end
	end
	return input
end

local protocol = "network"
InitRednet(protocol)
local username = handleUsername(protocol)
Register(username, protocol)

Print("Tunnelling...", username, "home")

for n = 1, length do
	turtle.placeDown()
	turtle.turnLeft()
	for i = 1, height, 1 do
		tryDigUp()
		tryDig()
		if i ~= height then
			tryUp()
		end
	end
	turtle.turnRight()
	turtle.turnRight()
	tryDig()
	for j = 1, height, 1 do
		tryDig()
		if j ~= height then
			tryDown()
		end
	end
	if n % 5 == 0 then
		turtle.turnRight()
		turtle.select(2)
		turtle.place()
		turtle.select(1)
		turtle.turnRight()
		turtle.turnRight()
	else
		turtle.turnLeft()
	end
	dumpTrash()

	if n < length then
		tryDig()
		if not tryForward() then
			Print("Aborting Tunnel.", username, "home")
			break
		end
	else
		Print("Tunnel complete.", username, "home")
	end

	if math.fmod(n, length / 4) == 0 then
		Print(n .. "/" .. length .. " done", username, "home")
	end
end

Print("Returning to start...", username, "home")

-- Return to where we started
turtle.up()
turtle.turnLeft()
turtle.turnLeft()
for i = 1, length, 1 do
	refuel()
	if turtle.forward() then
	else
		turtle.dig()
	end
end
turtle.turnRight()
turtle.turnRight()
turtle.down()

local msg = "Mined " .. collected .. " items total."
Print(msg, username, "home")
