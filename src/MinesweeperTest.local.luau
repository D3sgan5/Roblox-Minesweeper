local Main = script.Parent
local CellMain = Main.CellMain
local Layout = CellMain.UIGridLayout
local Cell = Main.Cell
local GameoverFrame = Main.GameoverFrame
local StartButton = Main.Start

local GridSize = 10
local BombAmount = 15
local Revealed = 0

local cells = {}
local flags = {}
local connections = {}

local directions = {
	Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(0,1),Vector2.new(0,-1),
	Vector2.new(1,1),Vector2.new(1,-1),Vector2.new(-1,1),Vector2.new(-1,-1)
}

local NumberClr = {
	Color3.fromRGB(14, 66, 255),Color3.fromRGB(23, 129, 18),Color3.fromRGB(189, 0, 0),Color3.fromRGB(0, 9, 90),Color3.fromRGB(65, 3, 3)
}


local function SetupBombs()
	local Installed = 0
	
	repeat
		local x = math.random(1,GridSize)
		local y = math.random(1,GridSize)
		local current = cells[x][y]
		local IsBomb = current:GetAttribute("Mine")
		local NoMine = current:GetAttribute("NoMine")
		
		if not IsBomb and not NoMine then
			cells[x][y]:SetAttribute("Mine",true)
			Installed += 1
		end
	until Installed == BombAmount
end

local function IsGrid(x,y)
	return x >= 1 and x <= GridSize and y >= 1 and y <= GridSize
end

local function CountNumber(x:number,y:number)
	local count = 0
	for _,dir in directions do
		local nx,ny = x+dir.X,y+dir.Y
		if IsGrid(nx,ny) and cells[nx][ny]:GetAttribute("Mine") then
			count += 1
		end
	end
	
	return count
end

local function SetFlag(x:number,y:number)
	local CurrentCell = cells[x][y]
	local State = CurrentCell:GetAttribute("State")
	
	if not flags[x] then
		flags[x] = {}
	end
	
	if State == 3 then
		flags[x][y]:Destroy()
		CurrentCell:SetAttribute("State",1)
	else
		local Clone:TextButton = CurrentCell:Clone()
		Clone.Size = UDim2.fromScale(1,1)
		Clone.Interactable = false
		Clone.Position = UDim2.fromScale(CurrentCell.Position.X.Scale,CurrentCell.Position.Y.Scale)
		Clone.BackgroundTransparency = 1
		Clone.Visible = true
		Clone.Parent = CurrentCell
		Clone.Text = "🚩"
		CurrentCell:SetAttribute("State",3)
		flags[x][y] = Clone
	end
end

local function UpdateCell(x:number,y:number)
	local current = cells[x][y]
	local MinesAround = current:GetAttribute("Action")
	local IsMine = current:GetAttribute("Mine")
	local State = current:GetAttribute("State")
	
	if State == 3 then
		SetFlag(x,y)
	end
	
	current.BackgroundColor3 = Color3.fromRGB(125,125,125)
	current:SetAttribute("State",2)
	
	if IsMine then
		current.Text = "💣"
	elseif MinesAround > 0 then
		if MinesAround < 6 then
			current.TextColor3 = NumberClr[MinesAround]
		end
		current.Text = MinesAround
	end
end

local function GameOver()
	print("GameOver")
	GameoverFrame.Visible = true
	
	for i = 1,math.pow(GridSize,2) do
		local y = math.ceil(i/GridSize)
		local x = i - (y-1)*GridSize
		
		cells[x][y].Interactable = false
	end
end

local function Victory()
	GameoverFrame.Visible = true
	GameoverFrame.Text = "You win"
	GameoverFrame.TextColor3 = Color3.fromRGB(9, 154, 7)

	for i = 1,math.pow(GridSize,2) do
		local y = math.ceil(i/GridSize)
		local x = i - (y-1)*GridSize

		cells[x][y].Interactable = false
	end
end

local function FirstCell(x,y)
	local CurrentCell = cells[x][y]
	if Revealed == 0 then
		CurrentCell:SetAttribute("Action",0)
		CurrentCell:SetAttribute("NoMine",true)
		for _,dir in directions do
			local nx,ny = x+dir.X,y+dir.Y
			if IsGrid(nx,ny) then
				cells[nx][ny]:SetAttribute("NoMine",true)
			end
		end
		
		SetupBombs()

		for i = 1,math.pow(GridSize,2) do
			local y = math.ceil(i/GridSize)
			local x = i - (y-1)*GridSize
			local cell = cells[x][y]

			if not cell:GetAttribute("Action") then
				local BombAround = CountNumber(x,y)
				cell:SetAttribute("Action",BombAround)
			end
		end
	end
end

local function RevealCell(x,y)
	local CurrentCell:TextButton = cells[x][y]
	if CurrentCell:GetAttribute("State") == 2 then return end
	FirstCell(x,y)
	local MinesAround = CurrentCell:GetAttribute("Action")
	
	UpdateCell(x,y)
	if CurrentCell:GetAttribute("Mine") then
		GameOver()
		script.Explosion:Play()
		return
	else
		Revealed += 1
		if Revealed == GridSize*GridSize-BombAmount then
			Victory()
			return
		end
	end
	
	local sound = script.Click
	sound:Play()
	
	if MinesAround == 0 then
		for _,dir in directions do
			local nx,ny = x+dir.X,y+dir.Y
			if IsGrid(nx,ny) then
				RevealCell(nx,ny)
			end
		end
	end
end

local function SetupGrid()
	local Padding = (1/GridSize) / 30
	local CellSize = 1/GridSize - Padding
	Layout.CellSize = UDim2.fromScale(CellSize,CellSize)
	Layout.CellPadding = UDim2.fromScale(Padding,Padding)
	
	for i = 1,math.pow(GridSize,2) do
		local Clone = Cell:Clone()
		Clone.Parent = CellMain
		Clone.Name = i
		Clone.Visible = true
		
		local y = math.ceil(i/GridSize)
		local x = i - (y-1)*GridSize
		if not cells[x] then
			cells[x] = {}
		end
		cells[x][y] = Clone
		
		local con,con2
		con = Clone.MouseButton1Click:Connect(function()
			if Clone:GetAttribute("State") == 3 then return end
			RevealCell(x,y)
			con:Disconnect()
			con2:Disconnect()
			con = nil
			con2 = nil
		end)
		
		con2 = Clone.MouseButton2Click:Connect(function()
			SetFlag(x,y)
		end)
	end
end

StartButton.Activated:Connect(function()
	SetupGrid()
	StartButton.Visible = false
	StartButton.Interactable = false
end)