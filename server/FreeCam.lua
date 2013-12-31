
class("FreeCamManager")

function FreeCamManager:__init()	
	local file = io.open("trajectories.txt","a")
	io.close(file)
	Network:Subscribe("FreeCam", self, self.SetPlayerPos)
	Network:Subscribe("FreeCamStore", self, self.StoreTrajectory)
end

function FreeCamManager:SetPlayerPos(args, client)
	if client:InVehicle() then
		client:GetVehicle():SetPosition(args.pos)
		client:GetVehicle():SetPosition(args.angle)
	else
		client:SetPosition(args.pos)
		client:SetAngle(args.angle)
	end
end

function FreeCamManager:StoreTrajectory(args, client)
	if args.type == nil or args.name == nil then
		client:SendChatMessage(string.format("%s Usage: /freecam <save/load/delete> <trajectory_name>",
								Config.name, args.name), Config.color)
		return
	end
	if args.type == "save" then
		if args.trajectory == nil then
			client:SendChatMessage(string.format("%s No trajectory found!", Config.name), Config.colorError)
			return
		end
		print(string.format("Received trajectory %s with %d waypoints by %s",
							args.name, #args.trajectory, client:GetName()))
		for line in io.lines("trajectories.txt") do
			local exists = string.find(line, "NAME%(" .. args.name .. "%)")
			if exists then
				client:SendChatMessage(string.format("%s Trajectory with this name already exists!",
								Config.name), Config.colorError)
				return
			end
		end
		file = io.open("trajectories.txt", "a")
		file:write(string.format("NAME(%s)", args.name))
		for k, v in ipairs(args.trajectory) do
			file:write(string.format("W%f,%f,%f %f,%f,%f",
														v.pos.x,
														v.pos.y,
														v.pos.z,
														v.angle.yaw,
														v.angle.pitch,
														v.angle.roll))
		end
		file:write("\n")
		file:close()
		client:SendChatMessage(string.format("%s Saved trajectory %s with %d waypoints",
								Config.name, args.name, #args.trajectory), Config.color)
	elseif args.type == "load" then
		print(string.format("%s requested to load trajectory %s",
							client:GetName(), args.name))
		
		local found = false
		for line in io.lines("trajectories.txt") do
			local exists = string.find(line, "NAME%(" .. args.name .. "%)")
			if exists then
				local trajectory = {}
				line = string.gsub(line, "NAME%(%a+%)", "")
				line = line:split("W")
				table.remove(line, 1)
				for i, v in ipairs(line) do
					-- Waypoint
					local waypoint = v:split(" ")
					local pos = waypoint[1]:split(",")
					local angle = waypoint[2]:split(",")
					pos = Vector3(tonumber(pos[1]), tonumber(pos[2]), tonumber(pos[3]))
					angle = Angle(tonumber(angle[1]), tonumber(angle[2]), tonumber(angle[3]))
					print("pos: " .. tostring(pos) .. " angle: " .. tostring(angle))
					table.insert(trajectory, {["pos"] = pos,
											  ["angle"] = angle})
				end

				Network:Send(client, "FreeCamStore", {["type"] = "load",
													  ["name"] = args.name,
													  ["trajectory"] = trajectory})
				found = true
			end
		end

		if not found then
			client:SendChatMessage(string.format("%s Error: Trajectory %s not found",
									Config.name, args.name), Config.colorError)
		end
	elseif args.type == "delete" then
		print(string.format("%s requested to delete trajectory %s",
							client:GetName(), args.name))
		
		local content = {}
		local found = false
		for line in io.lines("trajectories.txt") do
			local remove = string.find(line, "NAME%(" .. args.name .. "%)")
			if not remove then
				content[#content+1] = line
			else
				found = true
			end
		end

		local file = io.open("trajectories.txt", "w+")
		for i, v in ipairs(content) do
			print(v)
			file:write(v .. "\n")
		end
		file:close()

		if found then			
			client:SendChatMessage(string.format("%s Removed trajectory %s",
				Config.name, args.name), Config.color)
		else
			client:SendChatMessage(string.format("%s Error: Trajectory %s not found",
				Config.name, args.name), Config.colorError)
		end
	else
		print(args.type)
	end

end

freeCamManager = FreeCamManager()