peripheral.find("modem", rednet.open)
local monitor = peripheral.find("monitor")
if monitor then
	term.redirect(monitor)
	monitor.setTextScale(0.8)
end
local protocol = "chunkloader"
print("hosting", protocol .. "...")
rednet.host("chunkloader", "chunkloader-pc")

function Split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

local function addChunkloaders(x, z, sender)
	print(sender, "requested chunkloader to", x, "0", z)
	local chunkloaderPath = "chunkloaders/" .. sender
	local age = 3
	if x and z and sender then
		if fs.exists(chunkloaderPath) then
			local file = fs.open(chunkloaderPath, "r")
			local x2, z2, age = unpack(Split(file.readAll()))
			file.close()
			commands.exec("setblock " .. x2 .. " 0 " .. z2 .. " minecraft:bedrock")
			print("set bedrock to", x2, "0", z2)
		end

		local file = fs.open(chunkloaderPath, "w")
		file.write(x .. " " .. z .. " " .. age)
		file.close()
		commands.exec("setblock " .. x .. " 0 " .. z .. " railcraft:worldspike")
		print("set worldspike to", x, "0", z)
	end
end

local function cleanup()
	print("cleanup...")
	local chunkloaders = fs.list("chunkloaders")
	for _, client in ipairs(chunkloaders) do
		local file = fs.open("chunkloaders/" .. client, "r")
		local x, z, age = unpack(Split(file.readAll()))
		file.close()
		if tonumber(age) <= 0 then
			commands.exec("setblock " .. x .. " 0 " .. z .. " minecraft:bedrock")
			fs.delete("chunkloaders/" .. client)
			print(client .. "'s", "chunkloader expired")
			print("set bedrock to", x, "0", z)
		else
			age = age - 1
			local file = fs.open("chunkloaders/" .. client, "w")
			file.write(x .. " " .. z .. " " .. age)
			file.close()
			print("dropped", client .. "'s", "chunkloader's age to", age)
		end
	end
end

local day = os.day()
fs.makeDir("chunkloaders")
while true do
	if day < os.day() then
		day = os.day()
		cleanup()
	end
	local senderID, message = rednet.receive(protocol, 3)
	local rebootButton = redstone.getInput("left")
	if rebootButton then
		commands.exec("playsound minecraft:entity.tnt.primed hostile @p")
		os.reboot()
	end
	if message then
		local x, z = unpack(Split(message))
		x = tonumber(math.floor(x))
		z = tonumber(math.floor(z))
		addChunkloaders(x, z, senderID)
	end
end
