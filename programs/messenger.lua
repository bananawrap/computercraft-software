local monitor = peripheral.wrap("top")
if monitor then
	term.redirect(monitor)
	monitor.setTextScale(0.8)
end
require("lib-network")
local protocol = "network"
InitRednet(protocol)

local function errorHandler(err)
	print("ERROR:", err)
end
local function stfu(err) end

local function generateColor(str)
	if str then
		t = {}
		str:gsub(".", function(c)
			table.insert(t, c)
		end)
		local total = 0
		for _, char in ipairs(t) do
			total = total + string.byte(char)
		end
		math.randomseed(total)
		n = math.random(1, 15)
		return 2 ^ (n - 1)
	end
	return 1
end

print("setting up user...")
local username = handleUsername()
local theme = generateColor(username)

local function getDomains(username)
	Send(username, "host", "records")
	local message, sender, receiver, content = Receive(1)
	if sender == "host" then
		local domainsStr = content
		local domains = Split(content)
		return domainsStr, domains
	end
end

local domainsStr, domains
print("fetching domains...")
while not domains do
	domainsStr, domains = getDomains(username)
end

local function saveMessage(sender, message)
	fs.makeDir("chats")
	fs.makeDir("unread")
	local file = fs.open("chats/" .. sender, "a")
	file.writeLine(message)
	file.close()
	local file = fs.open("unread/" .. sender, "a")
	file.writeLine(message)
	file.close()
end

local function notif(str)
	local x, y = term.getCursorPos()
	term.setCursorPos(2, 17)
	term.setTextColor(theme)
	term.write(str)
	term.setTextColor(1)
	term.setCursorPos(x, y)
end

local function getMessages(domain)
	if domain then
		if fs.exists("chats/" .. domain) then
			local file = fs.open("chats/" .. domain, "r")
			local rawMessages = file.readAll()
			file.close()
			local messages = {}
			if rawMessages then
				messages = Split(rawMessages, "\n")
				return messages
			end
		end
	end
end

local function getUnreadMessages(domain)
	if fs.exists("unread/" .. domain) then
		file = fs.open("unread/" .. domain, "r")
		local rawUnreadMessages = file.readAll()
		file.close()
		local unreadMessages = {}
		if rawUnreadMessages then
			unreadMessages = Split(rawUnreadMessages, "\n")
			fs.delete("unread/" .. domain)
			return unreadMessages
		end
	end
end

local function checkUnread(domains)
	results = {}
	if domains then
		for i, domain in ipairs(domains) do
			if fs.exists("unread/" .. domain) then
				results[domain] = true
			end
		end

		return results
	end
end

local function drawBaseUI(width, height)
	term.clear()
	term.setCursorPos(1, 1)
	term.write("/")
	term.write(string.rep("-", width - 2))
	term.write("\\")
	for y = 2, height, 1 do
		term.setCursorPos(1, y)
		term.write("|")
		term.setCursorPos(width, y)
		term.write("|")
	end
	term.setCursorPos(1, height + 1)
	term.write("\\")
	term.write(string.rep("-", width - 2))
	term.write("/")
end

local function tui(key, domains)
	local width, height = term.getSize()
	height = height - 1
	if key then
		if key == "17" then -- W
			Nav = Nav - 1
		end
		if key == "31" then -- S
			Nav = Nav + 1
		end
		if key == "200" then -- up
			Nav = Nav - 1
		end
		if key == "208" then -- down
			Nav = Nav + 1
		end
		if key == "37" then -- k
			if Mode == "list" then
				Nav = Nav - 1
			else
				ChatNav = ChatNav - 1
			end
		end
		if key == "36" then -- j
			if Mode == "list" then
				Nav = Nav + 1
			else
				ChatNav = ChatNav + 1
			end
		end
		if key == "28" then -- enter
			if Mode == "chat" then
				Mode = "type"
			end
		end
		if key == "32" then -- D
			Mode = "chat"
		end
		if key == "205" then -- right
			Mode = "chat"
		end
		if key == "38" then -- l
			Mode = "chat"
		end
		if key == "30" then -- A
			Mode = "list"
		end
		if key == "35" then -- h
			Mode = "list"
		end
		if key == "203" then -- left
			Mode = "list"
		end
	end
	drawBaseUI(width, height)
	if Mode == "list" and domains then
		if Nav <= 0 then
			Nav = #domains
		elseif Nav > #domains then
			Nav = 1
		end

		local unread = checkUnread(domains)
		pages = { domains }
		if #domains > height then
			while #domains > height do
				table.unpack(domains, 1, height)
			end
		end
		term.setCursorPos(math.floor(width / 2), 2)
		term.write(tostring(math.floor(Nav / height) + 1) .. "/" .. #pages)

		if #pages > 1 then
		end
		term.setTextColor(256)
		for i, page in ipairs(pages) do
			for y, domain in ipairs(page) do
				term.setCursorPos(2, y + 2)
				if Nav == y then
					term.write("< ")
				else
					term.write("<")
				end
				if unread[domain] then
					term.setTextColor(8192)
				end
				if Nav == y then
					term.setTextColor(theme)
				end
				term.write(domain)
				term.setTextColor(256)
				if Nav == y then
					term.write(" >")
				else
					term.write(">")
				end
			end
		end
		term.setTextColor(1)
	elseif Mode == "chat" or Mode == "type" then
		term.setCursorPos(math.floor(width / 2), 1)
		term.setTextColor(generateColor(domains[Nav]))
		term.write(domains[Nav])
		term.setTextColor(1)
		local messages = getMessages(domains[Nav])
		local unreadMessages = getUnreadMessages(domains[Nav])
		if messages then
			if unreadMessages then
				ChatNav = #messages - 5
			end
			if ChatNav <= 0 then
				ChatNav = #messages
			elseif ChatNav > #messages then
				ChatNav = 1
			end
			term.setCursorPos(2, 0)
			for i = ChatNav, #messages, 1 do
				local message = messages[i]
				local sender, _, content = ParseMessage(message)
				local x, y = term.getCursorPos()
				term.setCursorPos(2, y + 2)
				term.setTextColor(generateColor(sender))
				term.write(sender)
				term.setTextColor(1)
				term.setCursorPos(2, y + 3)
				term.write(content)
				if i == ChatNav + 5 then
					break
				end
			end
		end

		term.setCursorPos(2, height - 2)
		term.write(string.rep("-", width - 2))
		term.setCursorPos(2, height - 1)
		if Mode == "type" then
			local input = read()
			if input ~= "" then
				local msg = Send(username, domains[Nav], input)
				notif(msg)
				local message, sender, receiver, content = Receive(2)
				saveMessage(domains[Nav], msg)
				if message then
					saveMessage(sender, message)
				end
				Mode = "chat"
			end
		end
		Mode = "chat"
	end
end
Nav = 1
ChatNav = 1
Mode = "list"
while true do
	parallel.waitForAny(function()
		local event, scancode = os.pullEvent("key")
		local key = tostring(scancode)
		tui(key, domains)
	end, function()
		local message, sender, receiver, content = Receive(10)
		if message then
			saveMessage(sender, message)
			notif(sender .. ": " .. message)
		end
		if not domains then
			domains = getDomains(username)
		end
		tui("", domains)
	end)
end
