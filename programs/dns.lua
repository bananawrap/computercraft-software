require("lib-network")
local monitor = peripheral.find("monitor")
term.redirect(monitor)
monitor.setTextScale(0.5)
local function errorHandler(err)
	print("ERROR:", err)
end
peripheral.find("modem", rednet.open)
if rednet.isOpen() then
	print("connected to rednet")
else
	print("couldn't connect to rednet")
end

local function registerHost()
	local file = fs.open("dns-records/host", "w")
	file.writeLine(tostring(os.getComputerID()))
	file.close()
	return "host"
end

local protocol = "network"
local hostname = "network-pc"
local host = registerHost()
rednet.host(protocol, hostname)
fs.makeDir("dns-records")

local function lookup(domain)
	if domain then
		if fs.exists("dns-records/" .. domain) then
			local file = fs.open("dns-records/" .. domain, "r")
			local address = file.readAll()
			file.close()
			return address
		else
			return false
		end
	end
end

local function list()
	return fs.list("dns-records/")
end

local function main()
	local senderID, message = rednet.receive(protocol, 10)
	if message then
		print("")
		local sender, domain, content = ParseMessage(message)
		print(senderID .. "@" .. message)
		if string.find(sender, "register") and domain then
			sleep(2)
			if not fs.exists("dns-records/" .. domain) then
				local file = fs.open("dns-records/" .. domain, "w")
				file.writeLine(tostring(senderID))
				file.close()
				rednet.send(senderID, "201", protocol)
				print(domain .. " registered")
			else
				rednet.send(senderID, "403", protocol)
			end
		elseif string.find(content, "records") and (not domain or domain == "host") then
			local records = list()
			local result = ""
			for _, record in pairs(records) do
				result = result .. record .. " "
			end
			Send(host, sender, result)
		else
			local userId = lookup(sender)
			if userId then
				userId = userId:gsub("%s+", "")
				if tonumber(senderID) == tonumber(userId) then
					local address = lookup(domain)
					if address then
						rednet.send(tonumber(address), message, protocol)
					else
						rednet.send(senderID, "404", protocol)
						print("not found")
					end
				else
					rednet.send(senderID, "403", protocol)
					print("not the domain owner " .. senderID .. " != " .. userId)
				end
			else
				print("user not found")
			end
		end
	end
end

Register("host", protocol)
while true do
	xpcall(main, errorHandler)
end
