require("lib-network")

local function errorHandler(err)
	print("ERROR:", err)
end
local function stfu(err) end

local networkProtocol = "network"
local minerProtocol = "miners"
rednet.host(minerProtocol, "manager-pc")
InitRednet(networkProtocol)
handleUsername(networkProtocol)

while true do
	local senderID, message,  = rednet.receive(nil, 10)
  if 
end
