local speaker = peripheral.find("speaker")
local protocol = "network"

function Print(str, username, domain)
	print(str)
	if username and domain then
		Send(username, domain, str)
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

function ParseMessage(message)
	if message then
		local metadata, content = unpack(Split(message, "::"))
		local sender, domain = unpack(Split(metadata, ">"))
		sender = sender:gsub("%s+", "")
		if domain then
			domain = domain:gsub("%s+", "")
			-- if string.find(domain, "&") then
			-- 	domain = Split(domain, "&")
			-- end
		end
		return sender, domain, content
	end
end

function InitRednet(protocol)
	if protocol == nil then
		protocol = "network"
	end
	peripheral.find("modem", rednet.open)
	if rednet.isOpen() then
		print("connected to rednet")
		print("searching for host...")
		while true do
			Host = rednet.lookup(protocol)
			if Host then
				break
			end
		end
		if Host then
			print("found host at " .. Host)
		else
			print("no network host found!")
		end
	end
end

function Register(username, protocol)
	print("registering as", username)
	if protocol == nil then
		protocol = "network"
	end
	if Host == nil then
		Host = os.getComputerID()
	end
	if rednet.isOpen() then
		rednet.send(Host, "register>" .. username .. "::", protocol)
		local senderID, message = rednet.receive(protocol, 2)
		if senderID == host then
			return message
		end
	else
		print("not connected to rednet")
	end
	return false
end

function Send(username, domain, message, protocol)
	if protocol == nil then
		protocol = "network"
	end
	if Host == nil then
		Host = os.getComputerID()
	end
	if domain ~= nil then
		message = tostring(message)
		if rednet.isOpen() then
			-- print(username .. " > " .. Host .. " > " .. domain .. "::" .. message)
			local msg = username .. ">" .. domain .. "::" .. message
			rednet.send(Host, msg, protocol)
			return msg
		else
			print("not connected to rednet")
		end
	end
	return ""
end

function Receive(timeout, protocol)
	if timeout == nil then
		timeout = 10
	end
	if protocol == nil then
		protocol = "network"
	end
	local senderID, message = rednet.receive(protocol, 1)
	local sender, domain, content = ParseMessage(message)
	if speaker and message then
		speaker.playNote("pling", 0.1, 20)
	end

	return message, sender, domain, content
end

function handleUsername(protocol)
	if fs.exists("username") then
		local file = fs.open("username", "r")
		local result = file.readAll()
		file.close()
		Register(result, protocol)
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
