require("lib-network")
InitRednet(protocol)
local username = handleUsername()
local state = false
while true do
	parallel.waitForAny(function()
		local message, sender, receiver, content = Receive(2)
	end, function()
		os.pullEvent("redstone")
	end)
	if message then
		if content == "open" then
			state = false
			redstone.setOutput("left", false)
			redstone.setOutput("right", false)
		else
			state = true
			redstone.setOutput("left", true)
			redstone.setOutput("right", true)
		end
	elseif redstone.getInput("front") then
		state = false
		redstone.setOutput("left", false)
		redstone.setOutput("right", false)
	elseif not state then
		state = true
		redstone.setOutput("left", true)
		redstone.setOutput("right", true)
	end
end
