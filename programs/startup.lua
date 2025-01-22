function errorHandle(err)
	error(err)
	sleep(2)
	shell.run("reboot")
end

function InitRednet(protocol)
	peripheral.find("modem", rednet.open)
end
InitRednet(protocol)

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

local function get(program)
	print("downloading", program, "...")
	local updateHost
	while not updateHost do
		updateHost = rednet.lookup("software")
	end
	for i = 1, 10, 1 do
		rednet.send(updateHost, program, "software")
		local senderID, data = rednet.receive("software", 3)
		if senderID == updateHost then
			sleep(0.2)
			rednet.send(updateHost, program, "software")
			print("installing", program, "...")
			local file = fs.open(program, "w")
			file.write(data)
			file.close()
			return true
		end
	end
end

local function table2string(t)
	local res = ""
	for _, str in pairs(t) do
		res = res .. str .. " "
	end
	return res
end

print("id:", os.getComputerID())
if fs.exists("programs") then
	local file = fs.open("programs", "r")
	local programsRaw = file.readAll()
	file.close()
	local programs = Split(programsRaw, "\n")
	for _, program in ipairs(programs) do
		get(program)
	end
else
	local file = fs.open("programs", "w")
	file.writeLine("startup.lua")
	file.close()
	shell.run("reboot")
end
if fs.exists("boot") then
	local file = fs.open("boot", "r")
	local startup = file.readLine()
	file.close()
	while true do
		shell.run(startup)
	end
else
	print("download network library? (Y/n)")
	local userinput = read()
	if userinput ~= n then
		local file = fs.open("programs", "a")
		file.writeLine("lib-network.lua")
		file.close()
	end
	print("startup command:")
	local userinput = read()
	local file = fs.open("boot", "w")
	file.write(userinput)
	file.close()
	print("add as an program? (Y/n)")
	local userinput2 = read()
	if userinput2 ~= "n" then
		local file = fs.open("programs", "a")
		file.writeLine(userinput)
		file.close()
	end
	os.reboot()
end
