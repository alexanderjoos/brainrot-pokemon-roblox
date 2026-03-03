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
local SetHeldItem: RemoteEvent = RemotesFolder:WaitForChild("SetHeldItem") :: RemoteEvent
local SetLeader: RemoteEvent = RemotesFolder:WaitForChild("SetLeader") :: RemoteEvent
local ReleaseBrainrot: RemoteEvent = RemotesFolder:WaitForChild("ReleaseBrainrot") :: RemoteEvent

local BrainrotModelsFolder = ReplicatedStorage:WaitForChild("BrainrotModels")

local function createBattleGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotBattleGui"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -40, 0, 260)
	frame.Position = UDim2.new(0, 20, 1, -280)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	frame.BackgroundTransparency = 0.2
	frame.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = frame

	local playerPanel = Instance.new("Frame")
	playerPanel.Name = "PlayerPanel"
	playerPanel.Size = UDim2.new(0.48, -5, 0, 80)
	playerPanel.Position = UDim2.new(0, 10, 0, 10)
	playerPanel.BackgroundTransparency = 1
	playerPanel.Parent = frame

	local enemyPanel = Instance.new("Frame")
	enemyPanel.Name = "EnemyPanel"
	enemyPanel.Size = UDim2.new(0.48, -5, 0, 80)
	enemyPanel.Position = UDim2.new(0.52, 0, 0, 10)
	enemyPanel.BackgroundTransparency = 1
	enemyPanel.Parent = frame

	local function createDiagLabels(parent: Frame, prefix: string)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = prefix .. "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 22)
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 18
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Parent = parent

		local hpLabel = Instance.new("TextLabel")
		hpLabel.Name = prefix .. "HPLabel"
		hpLabel.Size = UDim2.new(1, 0, 0, 20)
		hpLabel.Position = UDim2.new(0, 0, 0, 22)
		hpLabel.BackgroundTransparency = 1
		hpLabel.Font = Enum.Font.Gotham
		hpLabel.TextSize = 14
		hpLabel.TextXAlignment = Enum.TextXAlignment.Left
		hpLabel.TextColor3 = Color3.fromRGB(160, 240, 160)
		hpLabel.Parent = parent

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = prefix .. "StatusLabel"
		statusLabel.Size = UDim2.new(1, 0, 0, 18)
		statusLabel.Position = UDim2.new(0, 0, 0, 42)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.TextSize = 14
		statusLabel.TextXAlignment = Enum.TextXAlignment.Left
		statusLabel.TextColor3 = Color3.new(0.8, 0.8, 1)
		statusLabel.Parent = parent
	end

	createDiagLabels(playerPanel, "Player")
	createDiagLabels(enemyPanel, "Enemy")

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(1, -20, 0, 40)
	messageLabel.Position = UDim2.new(0, 10, 0, 95)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextSize = 18
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.Parent = frame

	local interactFrame = Instance.new("Frame")
	interactFrame.Name = "InteractFrame"
	interactFrame.Size = UDim2.new(1, -20, 0, 80)
	interactFrame.Position = UDim2.new(0, 10, 1, -90)
	interactFrame.BackgroundTransparency = 1
	interactFrame.Parent = frame

	local mainButtonsFrame = Instance.new("Frame")
	mainButtonsFrame.Name = "MainButtons"
	mainButtonsFrame.Size = UDim2.new(1, 0, 1, 0)
	mainButtonsFrame.BackgroundTransparency = 1
	mainButtonsFrame.Parent = interactFrame

	local mainLayout = Instance.new("UIGridLayout")
	mainLayout.CellSize = UDim2.new(0.24, 0, 0.9, 0)
	mainLayout.CellPadding = UDim2.new(0.02, 0, 0, 0)
	mainLayout.FillDirectionMaxCells = 4
	mainLayout.Parent = mainButtonsFrame

	local function createMainButton(name: string, text: string)
		local button = Instance.new("TextButton")
		button.Name = name
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 16
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = text
		button.AutoButtonColor = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		button.Parent = mainButtonsFrame
		return button
	end

	local fightMainButton = createMainButton("FightButton", "Fight")
	local bagMainButton = createMainButton("BagButton", "Bag")
	local brainrotsMainButton = createMainButton("BrainrotsButton", "Brainrots")
	local runMainButton = createMainButton("RunButton", "Run")

	local fightFrame = Instance.new("Frame")
	fightFrame.Name = "FightFrame"
	fightFrame.Size = UDim2.new(1, -10, 1, -10)
	fightFrame.Position = UDim2.new(0, 5, 0, 5)
	fightFrame.BackgroundTransparency = 1
	fightFrame.Visible = false
	fightFrame.Parent = interactFrame

	local bagFrame = Instance.new("Frame")
	bagFrame.Name = "BattleBagFrame"
	bagFrame.Size = fightFrame.Size
	bagFrame.Position = fightFrame.Position
	bagFrame.BackgroundTransparency = 1
	bagFrame.Visible = false
	bagFrame.Parent = interactFrame

	local switchFrame = Instance.new("Frame")
	switchFrame.Name = "SwitchFrame"
	switchFrame.Size = fightFrame.Size
	switchFrame.Position = fightFrame.Position
	switchFrame.BackgroundTransparency = 1
	switchFrame.Visible = false
	switchFrame.Parent = interactFrame

	local function createSubBackButton(parent: Frame)
		local back = Instance.new("TextButton")
		back.Name = "BackButton"
		back.Size = UDim2.new(0, 80, 0, 24)
		back.Position = UDim2.new(0, 0, 0, 0)
		back.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		back.TextColor3 = Color3.new(1, 1, 1)
		back.Font = Enum.Font.GothamBold
		back.TextSize = 14
		back.Text = "< Back"

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = back

		back.Parent = parent
		return back
	end

	local fightBack = createSubBackButton(fightFrame)
	local movesList = Instance.new("Frame")
	movesList.Name = "MovesList"
	movesList.Size = UDim2.new(1, 0, 1, -28)
	movesList.Position = UDim2.new(0, 0, 0, 28)
	movesList.BackgroundTransparency = 1
	movesList.Parent = fightFrame

	local movesLayout = Instance.new("UIListLayout")
	movesLayout.FillDirection = Enum.FillDirection.Vertical
	movesLayout.Padding = UDim.new(0, 4)
	movesLayout.Parent = movesList

	local bagBack = createSubBackButton(bagFrame)
	local bagListFrame = Instance.new("Frame")
	bagListFrame.Name = "BagItems"
	bagListFrame.Size = UDim2.new(0.5, -4, 1, -28)
	bagListFrame.Position = UDim2.new(0, 0, 0, 28)
	bagListFrame.BackgroundTransparency = 1
	bagListFrame.Parent = bagFrame

	local bagListLayout = Instance.new("UIListLayout")
	bagListLayout.FillDirection = Enum.FillDirection.Vertical
	bagListLayout.Padding = UDim.new(0, 4)
	bagListLayout.Parent = bagListFrame

	local bagDetail = Instance.new("TextLabel")
	bagDetail.Name = "BagDetail"
	bagDetail.Size = UDim2.new(0.5, -4, 1, -28)
	bagDetail.Position = UDim2.new(0.5, 4, 0, 28)
	bagDetail.BackgroundTransparency = 1
	bagDetail.TextColor3 = Color3.new(1, 1, 1)
	bagDetail.Font = Enum.Font.Gotham
	bagDetail.TextSize = 14
	bagDetail.TextWrapped = true
	bagDetail.TextXAlignment = Enum.TextXAlignment.Left
	bagDetail.TextYAlignment = Enum.TextYAlignment.Top
	bagDetail.Parent = bagFrame

	local switchBack = createSubBackButton(switchFrame)
	local switchListFrame = Instance.new("Frame")
	switchListFrame.Name = "SwitchList"
	switchListFrame.Size = UDim2.new(1, 0, 1, -28)
	switchListFrame.Position = UDim2.new(0, 0, 0, 28)
	switchListFrame.BackgroundTransparency = 1
	switchListFrame.Parent = switchFrame

	local switchLayout = Instance.new("UIListLayout")
	switchLayout.FillDirection = Enum.FillDirection.Vertical
	switchLayout.Padding = UDim.new(0, 4)
	switchLayout.Parent = switchListFrame

	local function showMain()
		mainButtonsFrame.Visible = true
		fightFrame.Visible = false
		bagFrame.Visible = false
		switchFrame.Visible = false
	end

	fightBack.MouseButton1Click:Connect(showMain)
	bagBack.MouseButton1Click:Connect(showMain)
	switchBack.MouseButton1Click:Connect(showMain)

	fightMainButton.MouseButton1Click:Connect(function()
		mainButtonsFrame.Visible = false
		fightFrame.Visible = true
	end)

	bagMainButton.MouseButton1Click:Connect(function()
		mainButtonsFrame.Visible = false
		bagFrame.Visible = true

		for _, child in ipairs(bagListFrame:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		bagListLayout.Parent = bagListFrame
		bagDetail.Text = ""

		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		for _, entry in ipairs(data.bag or {}) do
			if not entry.usableInBattle then
				continue
			end
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 24)
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.Gotham
			b.TextSize = 14
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Text = string.format(" %s x%d", entry.displayName, entry.quantity or 1)
			b.Parent = bagListFrame

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = b

			b.MouseButton1Click:Connect(function()
				bagDetail.Text = string.format(
					"%s\n\nQty: %d\n\nUsable in battle.",
					entry.displayName,
					entry.quantity or 1
				)
				if entry.id == "troppi_ball" then
					BattleRequest:FireServer("capture")
				else
					BattleRequest:FireServer("useItem", entry.id)
				end
			end)
		end
	end)

	brainrotsMainButton.MouseButton1Click:Connect(function()
		mainButtonsFrame.Visible = false
		switchFrame.Visible = true

		for _, child in ipairs(switchListFrame:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		switchLayout.Parent = switchListFrame

		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		local party = data.party or {}
		local leaderIndex = data.leaderIndex or 1
		for index, mon in ipairs(party) do
			local slot = Instance.new("TextLabel")
			slot.Size = UDim2.new(1, 0, 0, 40)
			if mon.hp <= 0 then
				slot.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
			else
				slot.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
			end
			slot.TextColor3 = Color3.new(1, 1, 1)
			slot.Font = Enum.Font.Gotham
			slot.TextSize = 14
			slot.TextXAlignment = Enum.TextXAlignment.Left

			local leaderMark = (index == leaderIndex) and " ★" or ""
			slot.Text = string.format(
				" %s Lv.%d%s  HP %d/%d",
				mon.displayName,
				mon.level,
				leaderMark,
				mon.hp,
				mon.maxHP
			)
			slot.Parent = switchListFrame

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = slot
		end
	end)

	runMainButton.MouseButton1Click:Connect(function()
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

local function formatDiag(brainrot)
	if not brainrot then
		return "None", ""
	end
	local name = string.format("%s  Lv.%d", brainrot.displayName, brainrot.level)
	local hpText = string.format("HP %d/%d", brainrot.hp, brainrot.maxHP)
	return name, hpText
end

BattleUpdate.OnClientEvent:Connect(function(battleState, message: string)
	local gui = ensureBattleGui()
	local frame = gui:FindFirstChild("Frame") :: Frame
	if not frame then
		return
	end

	local playerPanel = frame:FindFirstChild("PlayerPanel") :: Frame
	local enemyPanel = frame:FindFirstChild("EnemyPanel") :: Frame
	local messageLabel = frame:FindFirstChild("MessageLabel") :: TextLabel
	local interactFrame = frame:FindFirstChild("InteractFrame") :: Frame
	local fightFrame = interactFrame and (interactFrame:FindFirstChild("FightFrame") :: Frame)

	if playerPanel and battleState.playerBrainrot then
		local nameLabel = playerPanel:FindFirstChild("PlayerNameLabel") :: TextLabel
		local hpLabel = playerPanel:FindFirstChild("PlayerHPLabel") :: TextLabel
		local statusLabel = playerPanel:FindFirstChild("PlayerStatusLabel") :: TextLabel
		local name, hpText = formatDiag(battleState.playerBrainrot)
		if nameLabel then
			nameLabel.Text = "You: " .. name
		end
		if hpLabel then
			hpLabel.Text = hpText
		end
		if statusLabel then
			statusLabel.Text = ""
		end
	end

	if enemyPanel and battleState.enemyBrainrot then
		local nameLabel = enemyPanel:FindFirstChild("EnemyNameLabel") :: TextLabel
		local hpLabel = enemyPanel:FindFirstChild("EnemyHPLabel") :: TextLabel
		local statusLabel = enemyPanel:FindFirstChild("EnemyStatusLabel") :: TextLabel
		local name, hpText = formatDiag(battleState.enemyBrainrot)
		if nameLabel then
			nameLabel.Text = "Wild: " .. name
		end
		if hpLabel then
			hpLabel.Text = hpText
		end
		if statusLabel then
			statusLabel.Text = ""
		end
	end

	if messageLabel then
		messageLabel.Text = message or ""
	end

	if fightFrame and battleState.playerBrainrot then
		local movesList = fightFrame:FindFirstChild("MovesList") :: Frame
		if movesList then
			for _, child in ipairs(movesList:GetChildren()) do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			local layout = movesList:FindFirstChildOfClass("UIListLayout")
			if not layout then
				layout = Instance.new("UIListLayout")
				layout.FillDirection = Enum.FillDirection.Vertical
				layout.Padding = UDim.new(0, 4)
				layout.Parent = movesList
			end

			for _, move in ipairs(battleState.playerBrainrot.moves or {}) do
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 24)
				b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.Gotham
				b.TextSize = 14
				b.TextXAlignment = Enum.TextXAlignment.Left
				local acc = math.floor(((move.accuracy or 1) * 100) + 0.5)
				b.Text = string.format(" %s  (Pow %d, Acc %d%%)", move.name or "Move", move.power or 0, acc)
				b.Parent = movesList

				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0, 6)
				c.Parent = b

				local moveId = move.id
				b.MouseButton1Click:Connect(function()
					if moveId then
						BattleRequest:FireServer("move", moveId)
					end
				end)
			end
		end
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
	brainrotDetail.Size = UDim2.new(0.5, 0, 1, -40)
	brainrotDetail.Position = UDim2.new(0.48, 0, 0, 40)
	brainrotDetail.BackgroundTransparency = 1
	brainrotDetail.TextColor3 = Color3.new(1, 1, 1)
	brainrotDetail.Font = Enum.Font.Gotham
	brainrotDetail.TextSize = 16
	brainrotDetail.TextXAlignment = Enum.TextXAlignment.Left
	brainrotDetail.TextYAlignment = Enum.TextYAlignment.Top
	brainrotDetail.TextWrapped = true
	brainrotDetail.Parent = brainrotsFrame

	local heldItemLabel = Instance.new("TextLabel")
	heldItemLabel.Name = "HeldItemLabel"
	heldItemLabel.Size = UDim2.new(0.3, 0, 0, 24)
	heldItemLabel.Position = UDim2.new(0.48, 0, 0, 4)
	heldItemLabel.BackgroundTransparency = 1
	heldItemLabel.TextColor3 = Color3.new(1, 1, 1)
	heldItemLabel.Font = Enum.Font.GothamBold
	heldItemLabel.TextSize = 16
	heldItemLabel.TextXAlignment = Enum.TextXAlignment.Left
	heldItemLabel.Text = "Held: (none)"
	heldItemLabel.Parent = brainrotsFrame

	local setHeldButton = Instance.new("TextButton")
	setHeldButton.Name = "SetHeldButton"
	setHeldButton.Size = UDim2.new(0, 120, 0, 24)
	setHeldButton.Position = UDim2.new(0.8, -120, 0, 4)
	setHeldButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	setHeldButton.TextColor3 = Color3.new(1, 1, 1)
	setHeldButton.Font = Enum.Font.GothamBold
	setHeldButton.TextSize = 14
	setHeldButton.Text = "Set held item"
	setHeldButton.Parent = brainrotsFrame

	local setHeldCorner = Instance.new("UICorner")
	setHeldCorner.CornerRadius = UDim.new(0, 6)
	setHeldCorner.Parent = setHeldButton

	local setLeaderButton = Instance.new("TextButton")
	setLeaderButton.Name = "SetLeaderButton"
	setLeaderButton.Size = UDim2.new(0, 100, 0, 24)
	setLeaderButton.Position = UDim2.new(0.48, 0, 0, 32)
	setLeaderButton.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	setLeaderButton.TextColor3 = Color3.new(1, 1, 1)
	setLeaderButton.Font = Enum.Font.GothamBold
	setLeaderButton.TextSize = 14
	setLeaderButton.TextXAlignment = Enum.TextXAlignment.Left
	setLeaderButton.Text = "Set leader"
	setLeaderButton.Parent = brainrotsFrame

	local setLeaderCorner = Instance.new("UICorner")
	setLeaderCorner.CornerRadius = UDim.new(0, 6)
	setLeaderCorner.Parent = setLeaderButton

	local releaseButton = Instance.new("TextButton")
	releaseButton.Name = "ReleaseButton"
	releaseButton.Size = UDim2.new(0, 100, 0, 24)
	releaseButton.Position = UDim2.new(0.48, 0, 0, 60)
	releaseButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	releaseButton.TextColor3 = Color3.new(1, 1, 1)
	releaseButton.Font = Enum.Font.GothamBold
	releaseButton.TextSize = 14
	releaseButton.TextXAlignment = Enum.TextXAlignment.Left
	releaseButton.Text = "Release"
	releaseButton.Parent = brainrotsFrame

	local releaseCorner = Instance.new("UICorner")
	releaseCorner.CornerRadius = UDim.new(0, 6)
	releaseCorner.Parent = releaseButton

	local function hideAllContent()
		bagList.Visible = false
		trainerFrame.Visible = false
		dexList.Visible = false
		settingsFrame.Visible = false
		brainrotsFrame.Visible = false
	end

	local currentSelectedPartyIndex: number? = nil

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
			local leaderIndex = data.leaderIndex or 1
			for index, mon in ipairs(party) do
				local slot = Instance.new("TextButton")
				slot.Size = UDim2.new(1, 0, 0, 60)
				if mon.hp <= 0 then
					slot.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
				else
					slot.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
				end
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
				local leaderMark = (index == leaderIndex) and " ★" or ""
				nameLabel.Text = string.format("%s  Lv.%d%s", mon.displayName, mon.level, leaderMark)
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

					currentSelectedPartyIndex = index
					local heldText = mon.heldItemId and ("Held: " .. tostring(mon.heldItemId)) or "Held: (none)"
					heldItemLabel.Text = heldText

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
				currentSelectedPartyIndex = 1
				local heldText = first.heldItemId and ("Held: " .. tostring(first.heldItemId)) or "Held: (none)"
				heldItemLabel.Text = heldText
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
				currentSelectedPartyIndex = nil
				heldItemLabel.Text = "Held: (none)"
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

	setHeldButton.MouseButton1Click:Connect(function()
		local data = GetTrainerData:InvokeServer()
		if not data or not currentSelectedPartyIndex then
			return
		end

		local holdableEntries = {}
		for _, entry in ipairs(data.bag or {}) do
			if entry.holdable then
				table.insert(holdableEntries, entry)
			end
		end

		if #holdableEntries == 0 then
			return
		end

		local overlay = Instance.new("ScreenGui")
		overlay.Name = "HeldItemChooser"
		overlay.ResetOnSpawn = false
		overlay.IgnoreGuiInset = true
		overlay.Parent = PlayerGui

		local panel = Instance.new("Frame")
		panel.Size = UDim2.new(0, 220, 0, 30 + #holdableEntries * 24)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		panel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
		panel.Parent = overlay

		local panelCorner = Instance.new("UICorner")
		panelCorner.CornerRadius = UDim.new(0, 8)
		panelCorner.Parent = panel

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -10, 0, 24)
		title.Position = UDim2.new(0, 5, 0, 3)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.Text = "Choose held item"
		title.Parent = panel

		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(1, -10, 1, -30)
		listFrame.Position = UDim2.new(0, 5, 0, 28)
		listFrame.BackgroundTransparency = 1
		listFrame.Parent = panel

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.Padding = UDim.new(0, 4)
		listLayout.Parent = listFrame

		for _, entry in ipairs(holdableEntries) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 22)
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.Gotham
			b.TextSize = 14
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Text = string.format(" %s x%d", entry.displayName, entry.quantity or 1)
			b.Parent = listFrame

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = b

			b.MouseButton1Click:Connect(function()
				SetHeldItem:FireServer(currentSelectedPartyIndex, entry.id)
				overlay:Destroy()
				refreshTrainerData()
			end)
		end
	end)

	setLeaderButton.MouseButton1Click:Connect(function()
		if not currentSelectedPartyIndex then
			return
		end
		SetLeader:FireServer(currentSelectedPartyIndex)
		refreshTrainerData()
	end)

	releaseButton.MouseButton1Click:Connect(function()
		if not currentSelectedPartyIndex then
			return
		end
		ReleaseBrainrot:FireServer(currentSelectedPartyIndex)
		currentSelectedPartyIndex = nil
		refreshTrainerData()
	end)
end

createMenuGui()

