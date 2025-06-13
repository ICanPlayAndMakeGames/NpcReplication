local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')

local players = game.Players

local Packet = require(script.Packet)

local CreatePig = Packet("CreatePig",Packet.Any)--{TimeAlive = Packet.NumberF16,Position = Packet.Vector2S16,Name = Packet.String})
local UpdatePig = Packet("UpdatePig",{TimeAlive = Packet.NumberF16,Position = Packet.Vector2S16,Name = Packet.NumberU32}) --Packet("UpdatePig",Packet.Any) --
local RemovePig = Packet("RemovePig",Packet.NumberU32)


local PigObject = require(script.PigObject)

local PigCount = 0

local PigsStuff:{[number]: typeof(PigObject.new())} = {
	
}

local function ShiftDown(startingindex)

	for i =startingindex,#PigsStuff do
		PigsStuff[i].Name -= 1
		PigsStuff[i-1] = PigsStuff[i]
		PigsStuff[i] = nil
	end

end

if RunService:IsServer() then
	
	local PlayerPigs = {}
	
	local function NewPig(player)
		
		PigCount += 1
		
		local obj = PigObject.new()
		
		obj.Name = PigCount
		
		PigsStuff[obj.Name] = obj
		
		table.insert(PlayerPigs[player],obj)
		
		CreatePig:Fire(obj)
		
	end

	local function TakeOutPig(pig:typeof(PigObject.new()))
		PigCount -= 1
		
		PigsStuff[pig.Name] = nil
		
		ShiftDown(pig.Name+1)
		RemovePig:Fire(pig.Name)
		
		pig:CleanUp()
		
	end
	
	
	--NewPig()
	
	local PerSecond = 10
	local Delay = 1/PerSecond

	local currentTime = 0
	
	RunService.Heartbeat:Connect(function(dt) -- Main loop

		if currentTime >= Delay then
			for i,v in PigsStuff do
				if v.CanMove == true then
					if v.Position then
					
						v.TimeAlive += dt
						--v.Position += Vector3.one * math.random(110,150) / 100
						
						local ToSend = v:GetEncodedData()
						UpdatePig:Fire(ToSend)
						
						v:MoveTo(ToSend.Position)
						
					end
				end
			end

			currentTime = 0
		end

		currentTime += dt
	end)
	
	
	players.PlayerAdded:Connect(function(player)
		
		PlayerPigs[player] = {}
		
		for _,pig in PigsStuff do
			print(pig,PigsStuff)
			CreatePig:FireClient(player,pig)
			
		end
		
		for i = 1,10 do 
			
			NewPig(player)
			
		end
		
		
	end)
	
	players.PlayerRemoving:Connect(function(player)
		
		for i,v in PlayerPigs[player] do
			TakeOutPig(v)
			PlayerPigs[player][i] = nil
		end
		
		PlayerPigs[player] = nil
		
	end)
	
	
elseif RunService:IsClient() then
	
	
	
	CreatePig.OnClientEvent:Connect(function(data)
		
		PigsStuff[data.Name] = PigObject.new(data)
		
	end)
	
	UpdatePig.OnClientEvent:Connect(function(data)
		--print(data)
		
		if PigsStuff[data.Name] then
			PigsStuff[data.Name]:SetData(data)
		end
		
	end)
	
	RemovePig.OnClientEvent:Connect(function(index)
		
		if PigsStuff[index] then
			PigsStuff[index] = nil
			ShiftDown(index + 1)
			PigsStuff[index]:CleanUp()
		end
	end)
	
end


local PigHandler = {}

return PigHandler
