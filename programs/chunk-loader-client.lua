peripheral.find("modem", rednet.open)
chunkloader_host = rednet.lookup("chunkloader")

Load_range = (16 * 2) - 1
Day = os.day()
local Cl_x, _, Cl_z = gps.locate()
rednet.send(chunkloader_host, Cl_x .. " " .. Cl_z, "chunkloader")

function HandleChunkLoader()
	local current_x, _, current_z = gps.locate()
	local x_dist = current_x - Cl_x
	if x_dist < 0 then
		x_dist = x_dist * -1
	end
	local z_dist = current_z - Cl_z
	if z_dist < 0 then
		z_dist = z_dist * -1
	end
	if x_dist >= Load_range or z_dist >= Load_range then
		rednet.send(chunkloader_host, current_x .. " " .. current_z, "chunkloader")
		Cl_x = current_x
		Cl_z = current_z
	elseif Day < os.day() then
		rednet.send(chunkloader_host, current_x .. " " .. current_z, "chunkloader")
		Cl_x = current_x
		Cl_z = current_z
	end
	return false
end
