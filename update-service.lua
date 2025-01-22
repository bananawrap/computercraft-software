local monitor = peripheral.find("monitor")
term.redirect(monitor)
monitor.setTextScale(0.5)

local function table2string(t)
	if t then
		local res = ""
		for _, str in pairs(t) do
			res = res .. str .. " "
		end
		return res
	end
end

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

function InitRednet(protocol)
	peripheral.find("modem", rednet.open)
	if rednet.isOpen() then
		print("connected to rednet")
	else
		print("couldn't connect to rednet!")
	end
end

function serve(filename, senderID)
	if filename and senderID then
		local programsPath = "programs/" .. filename
		local clientsPath = "clients/" .. senderID
		if fs.exists(programsPath) then
			local file = fs.open(programsPath, "r")
			local data = file.readAll()
			file.close()
			sleep(0.2)
			rednet.send(senderID, data, protocol)
			print("sent", senderID, filename)
			local senderID2, message, packetProtocol = rednet.receive(protocol, 1)
			if senderID == senderID2 and message == filename then
				print(senderID, "confirmed")
				if fs.exists(clientsPath) then
					local file = fs.open(clientsPath, "r")
					local clientData = file.readAll()
					file.close()
					if string.find(clientData, filename) then
						return true
					else
						local file = fs.open(clientsPath, "a")
						file.writeLine(filename)
						file.close()
						return true
					end
				else
					local file = fs.open(clientsPath, "w")
					file.writeLine(filename)
					file.close()
					return true
				end
			else
				print(senderID, "didn't confirm the transfer")
				return false
			end
			sleep(0.2)
			rednet.send(senderID2, "404", protocol)
			return false
		end
	end
	return false
end

function scan()
	local programsPath = "programs/"
	local sizesPath = "program-sizes/"
	local clientsPath = "clients/"
	local programs = fs.list(programsPath)
	local clients = fs.list(clientsPath)

	for _, program in ipairs(programs) do
		local sizePath = sizesPath .. program
		local programPath = programsPath .. program
		if fs.exists(sizePath) then
			local file = fs.open(sizePath, "r")
			local size = tonumber(file.readLine())
			file.close()
			if fs.getSize(programPath) ~= size then
				print("Detected change in", program)
				for _, client in ipairs(clients) do
					if not fs.exists(clientsPath .. client) then
						break
					end
					local file = fs.open(clientsPath .. client, "r")
					local clientPrograms = file.readAll()
					file.close()
					if string.find(clientPrograms, program) then
						print("notifying", client)
						for i = 1, 1, 1 do
							rednet.send(tonumber(client), "update", protocol)
							local senderID, message, packetProtocol = rednet.receive(protocol, 1)
							if tonumber(senderID) == tonumber(client) and message == "rebooting" then
								break
							else
								i = i + 1
							end
						end
					end
				end
			end
		end
		local file = fs.open(sizePath, "w")
		file.writeLine(fs.getSize(programPath))
		file.close()
	end
end

protocol = "software"
hostname = "software-host"

print("starting up...")
InitRednet(protocol)
rednet.host(protocol, hostname)
fs.makeDir("programs")
fs.makeDir("program-sizes")
fs.makeDir("clients")

while true do
	parallel.waitForAny(function()
		local senderID, filename, packetProtocol = rednet.receive()
		if filename and packetProtocol == protocol then
			print("serving:", senderID)
			print("file:", filename)
			serve(filename, senderID)
		end
	end, function()
		sleep(5)
		scan()
	end)
end
