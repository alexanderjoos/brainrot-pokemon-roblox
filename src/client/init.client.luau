local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BattleRequest: RemoteEvent = RemotesFolder:WaitForChild("BattleRequest") :: RemoteEvent
local BattleUpdate: RemoteEvent = RemotesFolder:WaitForChild("BattleUpdate") :: RemoteEvent
local GetTrainerData: RemoteFunction = RemotesFolder:WaitForChild("GetTrainerData") :: RemoteFunction
local BattleAnimation: RemoteEvent = RemotesFolder:WaitForChild("BattleAnimation") :: RemoteEvent
local HealComplete: RemoteEvent = RemotesFolder:WaitForChild("HealComplete") :: RemoteEvent

local BrainrotModelsFolder = ReplicatedStorage:WaitForChild("BrainrotModels")

local function createBattleGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotBattleGui"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -40, 0, 220)
	frame.Position = UDim2.new(0, 20, 1, -240)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	frame.BackgroundTransparency = 0.2
	frame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = frame

	local enemyLabel = Instance.new("TextLabel")
	enemyLabel.Name = "EnemyLabel"
	enemyLabel.Size = UDim2.new(1, -20, 0, 30)
	enemyLabel.Position = UDim2.new(0, 10, 0, 10)
	enemyLabel.BackgroundTransparency = 1
	enemyLabel.Font = Enum.Font.GothamBold
	enemyLabel.TextSize = 20
	enemyLabel.TextXAlignment = Enum.TextXAlignment.Left
	enemyLabel.TextColor3 = Color3.new(1, 1, 1)
	enemyLabel.Parent = frame

	local playerLabel = Instance.new("TextLabel")
	playerLabel.Name = "PlayerLabel"
	playerLabel.Size = UDim2.new(1, -20, 0, 30)
	playerLabel.Position = UDim2.new(0, 10, 0, 45)
	playerLabel.BackgroundTransparency = 1
	playerLabel.Font = Enum.Font.GothamBold
	playerLabel.TextSize = 20
	playerLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerLabel.TextColor3 = Color3.new(1, 1, 1)
	playerLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, -20, 0, 50)
	messageLabel.Position = UDim2.new(0, 10, 0, 80)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextSize = 18
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.Parent = frame

	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -20, 0, 60)
	buttonContainer.Position = UDim2.new(0, 10, 1, -70)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = frame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.Parent = buttonContainer

	local function createButton(name: string, text: string)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(0, 140, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = text
		button.AutoButtonColor = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		button.Parent = buttonContainer
		return button
	end

	local move1Button = createButton("Move1Button", "Move 1")
	local move2Button = createButton("Move2Button", "Move 2")
	local captureButton = createButton("CaptureButton", "Capture")
	local runButton = createButton("RunButton", "Run")

	move1Button.MouseButton1Click:Connect(function()
		BattleRequest:FireServer("move", "banana_bonk")
	end)

	move2Button.MouseButton1Click:Connect(function()
		BattleRequest:FireServer("move", "chimp_screech")
	end)

	captureButton.MouseButton1Click:Connect(function()
		BattleRequest:FireServer("capture")
	end)

	runButton.MouseButton1Click:Connect(function()
		BattleRequest:FireServer("run")
	end)

	screenGui.Parent = PlayerGui
	return screenGui
end

local battleGui: ScreenGui? = nil
local battleArenaModel: Model? = nil
local battlePlayerModel: Model? = nil
local battleEnemyModel: Model? = nil

local function ensureBattleGui()
	if battleGui and battleGui.Parent then
		return battleGui
	end
	battleGui = createBattleGui()
	return battleGui
end

local function formatHPLabel(brainrot)
	return string.format("%s Lv.%d - HP %d/%d", brainrot.displayName, brainrot.level, brainrot.hp, brainrot.maxHP)
end

BattleUpdate.OnClientEvent:Connect(function(battleState, message: string)
	local gui = ensureBattleGui()
	local frame = gui:FindFirstChild("Frame") :: Frame
	if not frame then
		return
	end

	local enemyLabel = frame:FindFirstChild("EnemyLabel") :: TextLabel
	local playerLabel = frame:FindFirstChild("PlayerLabel") :: TextLabel
	local messageLabel = frame:FindFirstChild("MessageLabel") :: TextLabel

	if enemyLabel and battleState.enemyBrainrot then
		enemyLabel.Text = "Wild: " .. formatHPLabel(battleState.enemyBrainrot)
	end
	if playerLabel and battleState.playerBrainrot then
		playerLabel.Text = "You: " .. formatHPLabel(battleState.playerBrainrot)
	end
	if messageLabel then
		messageLabel.Text = message or ""
	end

	if battleState.state ~= "ongoing" then
		task.delay(3, function()
			if battleGui then
				battleGui:Destroy()
				battleGui = nil
			end
		end)
	end
end)

local function cleanupBattleScene()
	if battleArenaModel then
		battleArenaModel:Destroy()
		battleArenaModel = nil
	end
	battlePlayerModel = nil
	battleEnemyModel = nil
end

local function createSimpleBattleArena(originPos: Vector3)
	cleanupBattleScene()

	battleArenaModel = Instance.new("Model")
	battleArenaModel.Name = "BrainrotBattleScene"
	battleArenaModel.Parent = Workspace

	local arenaFloor = Instance.new("Part")
	arenaFloor.Name = "ArenaFloor"
	arenaFloor.Size = Vector3.new(30, 1, 20)
	arenaFloor.Anchored = true
	arenaFloor.CanCollide = true
	arenaFloor.Material = Enum.Material.Grass
	arenaFloor.Color = Color3.fromRGB(40, 120, 50)
	arenaFloor.Position = originPos
	arenaFloor.Parent = battleArenaModel

	return originPos
end

local function spawnBrainrotModel(brainrotId: string, position: Vector3, facing: CFrame)
	local template = BrainrotModelsFolder:FindFirstChild(brainrotId)
	local model: Model
	if template and template:IsA("Model") then
		model = template:Clone()
	else
		model = Instance.new("Model")
		model.Name = brainrotId
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2, 3, 2)
		body.Anchored = true
		body.Material = Enum.Material.SmoothPlastic
		body.Color = Color3.fromRGB(200, 200, 200)
		body.Parent = model
	end

	model.Parent = battleArenaModel

	local primaryPart = model:FindFirstChildWhichIsA("BasePart") :: BasePart
	if primaryPart then
		model:PivotTo(CFrame.new(position) * facing)
	end

	return model
end

local function playCaptureBallAnimation()
	if not battleArenaModel or not battleEnemyModel then
		return
	end

	local enemyPart = battleEnemyModel:FindFirstChildWhichIsA("BasePart") :: BasePart
	if not enemyPart then
		return
	end
	local character = LocalPlayer.Character
	local hrp = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart)
	if not hrp then
		return
	end

	local startPos = hrp.Position + Vector3.new(0, 3, 0)
	local endPos = enemyPart.Position + Vector3.new(0, 2, 0)

	local ball = Instance.new("Part")
	ball.Name = "CaptureBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.2, 1.2, 1.2)
	ball.Anchored = true
	ball.CanCollide = false
	ball.Color = Color3.fromRGB(255, 0, 0)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Position = startPos
	ball.Parent = battleArenaModel

	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(ball, tweenInfo, { Position = endPos })
	tween:Play()

	task.delay(0.7, function()
		if ball then
			ball:Destroy()
		end
	end)
end

local function showCaughtPopup(brainrotId: string, displayName: string?)
	local existing = PlayerGui:FindFirstChild("BrainrotCaughtPopup") :: ScreenGui?
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotCaughtPopup"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Name = "PopupFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0.28, 0, 0.32, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 32)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Brainrot caught!"
	title.Parent = frame

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Icon"
	viewport.Size = UDim2.new(0, 120, 0, 120)
	viewport.Position = UDim2.new(0, 10, 0, 50)
	viewport.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
	viewport.BorderSizePixel = 0
	viewport.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.Size = UDim2.new(1, -140, 0, 60)
	label.Position = UDim2.new(0, 140, 0, 70)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Text = displayName or brainrotId
	label.Parent = frame

	local template = BrainrotModelsFolder:FindFirstChild(brainrotId)
	if template and template:IsA("Model") then
		local model = template:Clone()
		model.Parent = viewport

		local primaryPart = model:FindFirstChildWhichIsA("BasePart") :: BasePart
		if primaryPart then
			local camera = Instance.new("Camera")
			camera.Parent = viewport
			viewport.CurrentCamera = camera

			local cf = primaryPart.CFrame
			local offset = cf.Position + Vector3.new(0, 0, 8)
			camera.CFrame = CFrame.new(offset, cf.Position)
		end
	end

	task.delay(2, function()
		if gui then
			gui:Destroy()
		end
	end)
end

local function showHealNotification()
	local existing = PlayerGui:FindFirstChild("BrainrotHealPopup") :: ScreenGui?
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHealPopup"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui

	local label = Instance.new("TextLabel")
	label.Name = "HealLabel"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.1, 0)
	label.Size = UDim2.new(0.5, 0, 0, 40)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(10, 40, 10)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 20
	label.Text = "Your brainrots were fully healed!"
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	task.delay(2, function()
		if gui then
			gui:Destroy()
		end
	end)
end

BattleAnimation.OnClientEvent:Connect(function(action: string, payload: any?)
	if action == "start" and payload then
		local originPos = payload.arenaOrigin or Vector3.new(0, 120, 0)
		local arenaOrigin = createSimpleBattleArena(originPos)

		local playerPos = arenaOrigin + Vector3.new(-8, 2, 0)
		local enemyPos = arenaOrigin + Vector3.new(8, 2, 0)

		battlePlayerModel = spawnBrainrotModel(payload.playerBrainrotId, playerPos, CFrame.Angles(0, math.rad(45), 0))
		battleEnemyModel = spawnBrainrotModel(payload.enemyBrainrotId, enemyPos, CFrame.Angles(0, math.rad(-135), 0))
	elseif action == "captureAttempt" then
		playCaptureBallAnimation()
	elseif action == "caughtPopup" and payload then
		showCaughtPopup(payload.brainrotId, payload.displayName)
	elseif action == "end" then
		cleanupBattleScene()
	end
end)

HealComplete.OnClientEvent:Connect(function()
	showHealNotification()
end)

local function createMenuGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotMenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = PlayerGui

	local menuButton = Instance.new("TextButton")
	menuButton.Name = "MenuButton"
	menuButton.Size = UDim2.new(0, 100, 0, 32)
	menuButton.AnchorPoint = Vector2.new(0.5, 0)
	menuButton.Position = UDim2.new(0.5, 0, 0, 20)
	menuButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.Font = Enum.Font.GothamBold
	menuButton.TextSize = 16
	menuButton.Text = "MENU"
	menuButton.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = menuButton

	local menuFrame = Instance.new("Frame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(0.75, 0, 0.75, 0)
	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	menuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	menuFrame.Visible = false
	menuFrame.Parent = screenGui

	local menuCorner = Instance.new("UICorner")
	menuCorner.CornerRadius = UDim.new(0, 10)
	menuCorner.Parent = menuFrame

	local tabsFrame = Instance.new("Frame")
	tabsFrame.Name = "Tabs"
	tabsFrame.Size = UDim2.new(0, 110, 1, -20)
	tabsFrame.Position = UDim2.new(0, 10, 0, 10)
	tabsFrame.BackgroundTransparency = 1
	tabsFrame.Parent = menuFrame

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Vertical
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	uiListLayout.Padding = UDim.new(0, 6)
	uiListLayout.Parent = tabsFrame

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -130, 1, -20)
	contentFrame.Position = UDim2.new(0, 120, 0, 10)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = menuFrame

	local function createTabButton(name: string, label: string)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(1, 0, 0, 32)
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Text = "  " .. label

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = button

		button.Parent = tabsFrame
		return button
	end

	local bagButton = createTabButton("BagButton", "Bag")
	local trainerButton = createTabButton("TrainerButton", "Trainer Card")
	local dexButton = createTabButton("DexButton", "Troppi-dex")
	local settingsButton = createTabButton("SettingsButton", "Settings")
	local brainrotsButton = createTabButton("BrainrotsButton", "Brainrots")

	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "ContentLabel"
	contentLabel.Size = UDim2.new(1, 0, 0, 24)
	contentLabel.Position = UDim2.new(0, 0, 0, 0)
	contentLabel.BackgroundTransparency = 1
	contentLabel.TextColor3 = Color3.new(1, 1, 1)
	contentLabel.Font = Enum.Font.GothamBold
	contentLabel.TextSize = 18
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.Parent = contentFrame

	local contentBody = Instance.new("Frame")
	contentBody.Name = "Body"
	contentBody.Size = UDim2.new(1, 0, 1, -30)
	contentBody.Position = UDim2.new(0, 0, 0, 28)
	contentBody.BackgroundTransparency = 1
	contentBody.Parent = contentFrame

	local bagList = Instance.new("ScrollingFrame")
	bagList.Name = "BagList"
	bagList.Size = UDim2.new(1, 0, 1, 0)
	bagList.CanvasSize = UDim2.new(0, 0, 0, 0)
	bagList.BackgroundTransparency = 1
	bagList.ScrollBarThickness = 4
	bagList.Visible = false
	bagList.Parent = contentBody

	local bagLayout = Instance.new("UIListLayout")
	bagLayout.FillDirection = Enum.FillDirection.Vertical
	bagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bagLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	bagLayout.Padding = UDim.new(0, 4)
	bagLayout.Parent = bagList

	local trainerFrame = Instance.new("Frame")
	trainerFrame.Name = "TrainerFrame"
	trainerFrame.Size = UDim2.new(1, 0, 1, 0)
	trainerFrame.BackgroundTransparency = 1
	trainerFrame.Visible = false
	trainerFrame.Parent = contentBody

	local trainerNameLabel = Instance.new("TextLabel")
	trainerNameLabel.Name = "TrainerName"
	trainerNameLabel.Size = UDim2.new(1, 0, 0, 24)
	trainerNameLabel.Position = UDim2.new(0, 0, 0, 0)
	trainerNameLabel.BackgroundTransparency = 1
	trainerNameLabel.TextColor3 = Color3.new(1, 1, 1)
	trainerNameLabel.Font = Enum.Font.GothamBold
	trainerNameLabel.TextSize = 18
	trainerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	trainerNameLabel.Parent = trainerFrame

	local trainerStatsLabel = Instance.new("TextLabel")
	trainerStatsLabel.Name = "TrainerStats"
	trainerStatsLabel.Size = UDim2.new(1, 0, 0, 60)
	trainerStatsLabel.Position = UDim2.new(0, 0, 0, 28)
	trainerStatsLabel.BackgroundTransparency = 1
	trainerStatsLabel.TextColor3 = Color3.new(1, 1, 1)
	trainerStatsLabel.Font = Enum.Font.Gotham
	trainerStatsLabel.TextSize = 16
	trainerStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
	trainerStatsLabel.TextYAlignment = Enum.TextYAlignment.Top
	trainerStatsLabel.TextWrapped = true
	trainerStatsLabel.Parent = trainerFrame

	local dexList = Instance.new("ScrollingFrame")
	dexList.Name = "DexList"
	dexList.Size = UDim2.new(1, 0, 1, 0)
	dexList.CanvasSize = UDim2.new(0, 0, 0, 0)
	dexList.BackgroundTransparency = 1
	dexList.ScrollBarThickness = 4
	dexList.Visible = false
	dexList.Parent = contentBody

	local dexLayout = Instance.new("UIListLayout")
	dexLayout.FillDirection = Enum.FillDirection.Vertical
	dexLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	dexLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	dexLayout.Padding = UDim.new(0, 4)
	dexLayout.Parent = dexList

	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Size = UDim2.new(1, 0, 1, 0)
	settingsFrame.BackgroundTransparency = 1
	settingsFrame.Visible = false
	settingsFrame.Parent = contentBody

	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Name = "SettingsLabel"
	settingsLabel.Size = UDim2.new(1, 0, 0, 24)
	settingsLabel.Position = UDim2.new(0, 0, 0, 0)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.TextColor3 = Color3.new(1, 1, 1)
	settingsLabel.Font = Enum.Font.Gotham
	settingsLabel.TextSize = 16
	settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
	settingsLabel.Text = "Settings coming soon."
	settingsLabel.Parent = settingsFrame

	local brainrotsFrame = Instance.new("Frame")
	brainrotsFrame.Name = "BrainrotsFrame"
	brainrotsFrame.Size = UDim2.new(1, 0, 1, 0)
	brainrotsFrame.BackgroundTransparency = 1
	brainrotsFrame.Visible = false
	brainrotsFrame.Parent = contentBody

	local partyList = Instance.new("Frame")
	partyList.Name = "PartyList"
	partyList.Size = UDim2.new(0.45, 0, 1, 0)
	partyList.BackgroundTransparency = 1
	partyList.Parent = brainrotsFrame

	local partyLayout = Instance.new("UIListLayout")
	partyLayout.FillDirection = Enum.FillDirection.Vertical
	partyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	partyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	partyLayout.Padding = UDim.new(0, 4)
	partyLayout.Parent = partyList

	local brainrotDetail = Instance.new("TextLabel")
	brainrotDetail.Name = "BrainrotDetail"
	brainrotDetail.Size = UDim2.new(0.5, 0, 1, 0)
	brainrotDetail.Position = UDim2.new(0.48, 0, 0, 0)
	brainrotDetail.BackgroundTransparency = 1
	brainrotDetail.TextColor3 = Color3.new(1, 1, 1)
	brainrotDetail.Font = Enum.Font.Gotham
	brainrotDetail.TextSize = 16
	brainrotDetail.TextXAlignment = Enum.TextXAlignment.Left
	brainrotDetail.TextYAlignment = Enum.TextYAlignment.Top
	brainrotDetail.TextWrapped = true
	brainrotDetail.Parent = brainrotsFrame

	local function hideAllContent()
		bagList.Visible = false
		trainerFrame.Visible = false
		dexList.Visible = false
		settingsFrame.Visible = false
		brainrotsFrame.Visible = false
	end

	local function refreshTrainerData()
		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		local function clearChildren(parent: Instance)
			for _, child in ipairs(parent:GetChildren()) do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
		end

		local function rebuildBag()
			clearChildren(bagList)
			bagLayout.Parent = bagList

			for _, entry in ipairs(data.bag or {}) do
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -4, 0, 20)
				label.BackgroundTransparency = 1
				label.TextColor3 = Color3.new(1, 1, 1)
				label.Font = Enum.Font.Gotham
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Text = string.format("%s x%d", entry.displayName, entry.quantity)
				label.Parent = bagList
			end

			bagList.CanvasSize = UDim2.new(0, 0, 0, #(data.bag or {}) * 24)
		end

		local function rebuildTrainerCard()
			trainerNameLabel.Text = "Trainer: " .. (data.trainerName or LocalPlayer.Name)
			local stats = data.stats or {}
			trainerStatsLabel.Text = string.format(
				"Caught: %d\nBattles Won: %d\nBattles Lost: %d",
				stats.totalCaught or 0,
				stats.battlesWon or 0,
				stats.battlesLost or 0
			)
		end

		local function rebuildDex()
			clearChildren(dexList)
			dexLayout.Parent = dexList

			local seen = data.dexSeen or {}
			local caught = data.dexCaught or {}

			for id, _ in pairs(seen) do
				local status = caught[id] and "Caught" or "Seen"
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -4, 0, 20)
				label.BackgroundTransparency = 1
				label.TextColor3 = Color3.new(1, 1, 1)
				label.Font = Enum.Font.Gotham
				label.TextSize = 14
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Text = string.format("%s - %s", id, status)
				label.Parent = dexList
			end
		end

		local function setupBrainrotIcon(viewport: ViewportFrame, monId: string)
			for _, child in ipairs(viewport:GetChildren()) do
				child:Destroy()
			end

			local template = BrainrotModelsFolder:FindFirstChild(monId)
			if not template or not template:IsA("Model") then
				return
			end

			local model = template:Clone()
			model.Parent = viewport

			local primaryPart = model:FindFirstChildWhichIsA("BasePart") :: BasePart
			if not primaryPart then
				return
			end

			local camera = Instance.new("Camera")
			camera.Parent = viewport
			viewport.CurrentCamera = camera

			local cf = primaryPart.CFrame
			local offset = cf.Position + Vector3.new(0, 0, 6)
			camera.CFrame = CFrame.new(offset, cf.Position)
		end

		local function rebuildBrainrots()
			clearChildren(partyList)
			partyLayout.Parent = partyList

			local party = data.party or {}
			for index, mon in ipairs(party) do
				local slot = Instance.new("TextButton")
				slot.Size = UDim2.new(1, 0, 0, 60)
				slot.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
				slot.Text = ""
				slot.AutoButtonColor = true

				local slotCorner = Instance.new("UICorner")
				slotCorner.CornerRadius = UDim.new(0, 8)
				slotCorner.Parent = slot

				slot.Parent = partyList

				local icon = Instance.new("ViewportFrame")
				icon.Name = "Icon"
				icon.Size = UDim2.new(0, 56, 1, -8)
				icon.Position = UDim2.new(0, 6, 0, 4)
				icon.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
				icon.BorderSizePixel = 0
				icon.Parent = slot

				setupBrainrotIcon(icon, mon.id)

				local infoFrame = Instance.new("Frame")
				infoFrame.Name = "Info"
				infoFrame.Size = UDim2.new(1, -76, 1, -8)
				infoFrame.Position = UDim2.new(0, 68, 0, 4)
				infoFrame.BackgroundTransparency = 1
				infoFrame.Parent = slot

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.Size = UDim2.new(1, 0, 0, 24)
				nameLabel.Position = UDim2.new(0, 0, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 16
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Text = string.format("%s  Lv.%d", mon.displayName, mon.level)
				nameLabel.Parent = infoFrame

				local hpLabel = Instance.new("TextLabel")
				hpLabel.Name = "HPLabel"
				hpLabel.Size = UDim2.new(1, 0, 0, 20)
				hpLabel.Position = UDim2.new(0, 0, 0, 26)
				hpLabel.BackgroundTransparency = 1
				hpLabel.TextColor3 = Color3.fromRGB(160, 240, 160)
				hpLabel.Font = Enum.Font.Gotham
				hpLabel.TextSize = 14
				hpLabel.TextXAlignment = Enum.TextXAlignment.Left
				hpLabel.Text = string.format("HP %d/%d", mon.hp, mon.maxHP)
				hpLabel.Parent = infoFrame

				slot.MouseButton1Click:Connect(function()
					local movesText = ""
					for _, move in ipairs(mon.moves or {}) do
						movesText ..= string.format("- %s (Pwr %d)\n", move.name, move.power or 0)
					end

					brainrotDetail.Text = string.format(
						"%s Lv.%d\nHP: %d/%d\nATK: %d  DEF: %d  SPD: %d\n\nMoves:\n%s",
						mon.displayName,
						mon.level,
						mon.hp,
						mon.maxHP,
						mon.attack,
						mon.defense,
						mon.speed,
						movesText
					)
				end)
			end

			if #party > 0 then
				local first = party[1]
				local movesText = ""
				for _, move in ipairs(first.moves or {}) do
					movesText ..= string.format("- %s (Pwr %d)\n", move.name, move.power or 0)
				end
				brainrotDetail.Text = string.format(
					"%s Lv.%d\nHP: %d/%d\nATK: %d  DEF: %d  SPD: %d\n\nMoves:\n%s",
					first.displayName,
					first.level,
					first.hp,
					first.maxHP,
					first.attack,
					first.defense,
					first.speed,
					movesText
				)
			else
				brainrotDetail.Text = "No brainrots in your party yet."
			end
		end

		rebuildBag()
		rebuildTrainerCard()
		rebuildDex()
		rebuildBrainrots()
	end

	local function openSection(section: string)
		hideAllContent()
		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		if section == "bag" then
			contentLabel.Text = "Bag"
			bagList.Visible = true
		elseif section == "trainer" then
			contentLabel.Text = "Trainer Card"
			trainerFrame.Visible = true
		elseif section == "dex" then
			contentLabel.Text = "Troppi-dex"
			dexList.Visible = true
		elseif section == "settings" then
			contentLabel.Text = "Settings"
			settingsFrame.Visible = true
		elseif section == "brainrots" then
			contentLabel.Text = "Brainrots"
			brainrotsFrame.Visible = true
		end

		refreshTrainerData()
	end

	menuButton.MouseButton1Click:Connect(function()
		menuFrame.Visible = not menuFrame.Visible
	end)

	bagButton.MouseButton1Click:Connect(function()
		openSection("bag")
	end)

	trainerButton.MouseButton1Click:Connect(function()
		openSection("trainer")
	end)

	dexButton.MouseButton1Click:Connect(function()
		openSection("dex")
	end)

	settingsButton.MouseButton1Click:Connect(function()
		openSection("settings")
	end)

	brainrotsButton.MouseButton1Click:Connect(function()
		openSection("brainrots")
	end)
end

createMenuGui()

