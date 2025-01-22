require("lib-network")
InitRednet(protocol)
Register(username, protocol)

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

print("Tunnelling...")

for n = 1, length do
	turtle.placeDown()
	tryDigUp()
	turtle.turnLeft()
	tryDig()
	tryUp()
	tryDig()
	tryDigUp()
	tryUp()
	tryDig()
	turtle.turnRight()
	turtle.turnRight()
	tryDig()
	tryDown()
	tryDig()
	tryDown()
	tryDig()
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

	if n < length then
		tryDig()
		if not tryForward() then
			print("Aborting Tunnel.")
			break
		end
	else
		print("Tunnel complete.")
	end
end

-- print("Returning to start...")

-- Return to where we started
-- turtle.up()
-- turtle.turnLeft()
-- turtle.turnLeft()
-- for i = 1, length, 1 do
-- 	refuel()
-- 	if turtle.forward() then
-- 	else
-- 		turtle.dig()
-- 	end
-- end
-- turtle.turnRight()
-- turtle.turnRight()
-- turtle.down()

local msg1 = "Tunnel complete."
local msg2 = "Mined " .. collected .. " items total."
print(msg1)
Send(username, "home", msg1, protocol)
print(msg2)
Send(username, "home", msg2, protocol)
