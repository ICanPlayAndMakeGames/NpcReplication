local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Include
--RayParams.FilterDescendantsInstances = {workspace.Farms}

local Maid = require(script.Maid)

local Pig = {}
Pig.__index = Pig

local IsClient = RunService:IsClient()

local BasePig = script.BasePig

local function Vector2ToVector3(vector:Vector2):Vector3
	
	if not vector then
		return nil
	end
	
	if typeof(vector) == "Vector3" then
		return vector
	end
	
	return Vector3.new(vector.X,0,vector.Y)
end

local function Vector3ToVector2(vector:Vector3):Vector2
	
	if not vector then
		return nil
	end
	
	if typeof(vector) == "Vector2" then
		return vector
	end
	
	return Vector2.new(vector.X,vector.Z)
end

function Pig.new(Table,StartingPosition)
	
	
	
	local self = Table or {}
	setmetatable(self,Pig)
	
	self._Maid = Maid.new()
	
	
	if Table and IsClient then
		
		self.Model = script.BasePig:Clone()
		self.PrimaryPart = self.Model.PrimaryPart
		self.Position = self.Position + (Vector3.new(0,self.Model.PrimaryPart.Size.Y / 2,0))
		self.Model:PivotTo(CFrame.new(self.Position))
		self.Model.Parent = workspace
		
		self.Walk = self.Model.AnimationController.Animator:LoadAnimation(script.Walk)
		
		self._Maid:GiveTask(self.Model)
		
		return self
	end
	
	self.Speed = 16
	
	self.OriginalPosition = StartingPosition or Vector3.zero
	self.Name = nil
	self.TimeAlive = 0
	self.Position = Vector3.zero
	--self.Name =  Name or HttpService:GenerateGUID(false)
	self.CanMove = true
	self.TransmitData = self:GetEncodedData()
	
	return self
end


function Pig:MoveTo(endPosition)
	
	if not endPosition then
		return
	end
	
	
	
	if IsClient then
	
		

		local startPos = self.Position

		local Pos = endPosition
		
		Pos = Vector3.new(Pos.X,self.PrimaryPart.Position.Y,Pos.Z)

		if Pos == startPos then
			return
		end

		local distance = (Pos - startPos).Magnitude
		local dir = (Pos - startPos).Unit

		local currentDir = self.CurrentDir

		if not currentDir then
			currentDir = dir
			self.CurrentDir = dir
		end

		currentDir = self.PrimaryPart.CFrame.LookVector

		local duration = distance / self.Speed
		local defaultSpeed = 1 / duration


		if not (-math.huge < defaultSpeed) then
			return
		end

		local start = tick()

		if self._Maid.MovingConnection and self._Maid.MovingConnection.Connected then
			self._Maid.MovingConnection = nil
		end

		self.Walk:Play()

		self._Maid.MovingConnection = RunService.Heartbeat:Connect(function(dt)
			local elapsed = tick() - start

			if elapsed >= duration then

				elapsed = duration
				self.Position = Pos
				self.PrimaryPart.CFrame = CFrame.new(Pos,Pos + dir)

				self.Walk:Stop()
				self._Maid.MovingConnection = nil
			end

			local ratio = (defaultSpeed * elapsed)
			local pos = startPos:Lerp(Pos,ratio)

			local cf = CFrame.new(pos, pos + currentDir:Lerp(dir,math.min(elapsed * 10,1)))

			self.Position = pos
			self.PrimaryPart.CFrame = cf

		end)
	else
		
		local startPos = self.Position

		local Pos = Vector2ToVector3(endPosition)
		
		if Pos == startPos then
			return
		end
		
		self.CanMove = false
		
		local distance = (Pos - startPos).Magnitude
		local duration = distance / self.Speed
		
		self._Maid:GiveTask(task.delay(duration,function()
			self.Position = Pos
			
			local Pause = math.random(10,30) / 10
			task.wait(Pause)
			self.CanMove = true
		end))
		
	end
end

function Pig:GetNewPosition(retries)
	
	if not IsClient then
		local Position = self.Position

		if (Position - self.OriginalPosition).Magnitude >= 50 then
			local Direction = self.OriginalPosition - Position 

			return Direction
		end

		if not retries then
			retries = 0
		elseif retries >= 5 then

			local Direction = self.OriginalPosition - Position

			return Direction

		end


		local Length = math.random(10,50)
		local Direction = Vector3.new(math.random(-100,100) / 100,0,math.random(-100,100) / 100)
		local RayCast = workspace:Raycast(Position, Direction * Length,RayParams)

		

		if RayCast then
			
			local Dir =  (RayCast.Position - Direction * 10) - Position

			if Dir.Magnitude <= 5 then
				return self:GetRandomDirection(retries + 1)
			end

			if ((Position + Dir) - self.OriginalPosition).Magnitude >= 50 then

				local Direction = self.OriginalPosition - Position 

				return Direction
			end

			return Dir
		end

		if ((Position + (Direction * Length)) - self.OriginalPosition).Magnitude >= 50 then
			local Direction = self.OriginalPosition - Position 

			return Direction
		end

		return Direction * Length

	else
		warn("Can only be called on server")
	end
end

function Pig:GetEncodedData()
	return{
		
		TimeAlive = self.TimeAlive,
		Position = Vector3ToVector2(self:GetNewPosition(0)),
		Name = self.Name
		
	}
end

function Pig:SetData(data)
	
	local ConvertedPos = Vector3.new(data.Position.X,self.Model.PrimaryPart.Size.Y / 2,data.Position.Y)
	
	
	self:MoveTo(ConvertedPos)
	self.TimeAlive = data.TimeAlive
	
end

function Pig:CleanUp()
	
	self._Maid:Destroy()
	
	for i,v in self do 
		self[i] = nil
	end
	
end

return Pig
