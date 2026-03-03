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
local MoveBrainrotBetweenPartyAndCollection: RemoteFunction =
	RemotesFolder:WaitForChild("MoveBrainrotBetweenPartyAndCollection") :: RemoteFunction
local ReleaseFromCollection: RemoteFunction =
	RemotesFolder:WaitForChild("ReleaseFromCollection") :: RemoteFunction
local OpenPC: RemoteEvent = RemotesFolder:WaitForChild("OpenPC") :: RemoteEvent
local BattleInvite: RemoteEvent = RemotesFolder:FindFirstChild("BattleInvite") or RemotesFolder:WaitForChild("BattleInvite") :: RemoteEvent
local BattleInviteResponse: RemoteEvent = RemotesFolder:FindFirstChild("BattleInviteResponse") or RemotesFolder:WaitForChild("BattleInviteResponse") :: RemoteEvent
local SetSettings: RemoteEvent = RemotesFolder:FindFirstChild("SetSettings") or RemotesFolder:WaitForChild("SetSettings") :: RemoteEvent
local UseItemOutsideBattle: RemoteFunction = RemotesFolder:FindFirstChild("UseItemOutsideBattle") or RemotesFolder:WaitForChild("UseItemOutsideBattle") :: RemoteFunction
local ItemAcquired: RemoteEvent = RemotesFolder:FindFirstChild("ItemAcquired") or RemotesFolder:WaitForChild("ItemAcquired") :: RemoteEvent

local BrainrotModelsFolder = ReplicatedStorage:FindFirstChild("BrainrotList") or ReplicatedStorage:FindFirstChild("BrainrotModels") or ReplicatedStorage:WaitForChild("BrainrotModels")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Items = require(Shared:WaitForChild("Items"))

local function getModelLookupName(brainrotId: string): string
	local def = Brainrots.getById(brainrotId)
	return (def and def.modelName) or brainrotId
end

local function createBattleGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BrainrotBattleGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50

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

		local statusIcon = Instance.new("Frame")
		statusIcon.Name = prefix .. "StatusIcon"
		statusIcon.Size = UDim2.new(0, 16, 0, 16)
		statusIcon.Position = UDim2.new(0, 0, 0, 42)
		statusIcon.BackgroundTransparency = 1
		statusIcon.Visible = false
		statusIcon.Parent = parent

		local statusIconCorner = Instance.new("UICorner")
		statusIconCorner.CornerRadius = UDim.new(0, 4)
		statusIconCorner.Parent = statusIcon

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = prefix .. "StatusLabel"
		statusLabel.Size = UDim2.new(1, -22, 0, 18)
		statusLabel.Position = UDim2.new(0, 20, 0, 42)
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
				local ballIds = { ["troppi_ball"] = true, ["super_ball"] = true, ["ultra_ball"] = true }
				if ballIds[entry.id] then
					BattleRequest:FireServer("capture", entry.id)
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
			local slot = Instance.new("TextButton")
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
			slot.AutoButtonColor = true

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

			slot.MouseButton1Click:Connect(function()
				if mon.hp > 0 then
					BattleRequest:FireServer("switch", index)
					showMain()
				end
			end)
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
local battlePlayerHealthbarFill: Frame? = nil
local battleEnemyHealthbarFill: Frame? = nil

local STATUS_ICON_COLORS: { [string]: Color3 } = {
	poison = Color3.fromRGB(160, 80, 200),
	burn = Color3.fromRGB(240, 120, 40),
	paralyze = Color3.fromRGB(240, 220, 60),
	sleep = Color3.fromRGB(80, 120, 200),
}

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

	-- Update or create healthbars above battle models
	if battlePlayerModel and battleState.playerBrainrot then
		local mon = battleState.playerBrainrot
		if not battlePlayerHealthbarFill or not battlePlayerHealthbarFill.Parent then
			local _, fill = attachHealthbarToModel(battlePlayerModel, mon.maxHP, mon.hp)
			battlePlayerHealthbarFill = fill
		end
		if battlePlayerHealthbarFill then
			battlePlayerHealthbarFill.Size = UDim2.new(math.clamp(mon.hp / math.max(mon.maxHP, 1), 0, 1), 0, 1, 0)
			battlePlayerHealthbarFill.BackgroundColor3 = mon.hp <= 0 and Color3.fromRGB(100, 100, 100)
				or (mon.hp < mon.maxHP / 4 and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(80, 200, 80))
		end
	end
	if battleEnemyModel and battleState.enemyBrainrot then
		local mon = battleState.enemyBrainrot
		if not battleEnemyHealthbarFill or not battleEnemyHealthbarFill.Parent then
			local _, fill = attachHealthbarToModel(battleEnemyModel, mon.maxHP, mon.hp)
			battleEnemyHealthbarFill = fill
		end
		if battleEnemyHealthbarFill then
			battleEnemyHealthbarFill.Size = UDim2.new(math.clamp(mon.hp / math.max(mon.maxHP, 1), 0, 1), 0, 1, 0)
			battleEnemyHealthbarFill.BackgroundColor3 = mon.hp <= 0 and Color3.fromRGB(100, 100, 100)
				or (mon.hp < mon.maxHP / 4 and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(80, 200, 80))
		end
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
			local status = (battleState.playerBrainrot :: any).statusEffect
			statusLabel.Text = status and (status:sub(1, 1):upper() .. status:sub(2)) or ""
		end
		local statusIcon = playerPanel:FindFirstChild("PlayerStatusIcon") :: Frame?
		if statusIcon then
			local status = (battleState.playerBrainrot :: any).statusEffect
			if status and STATUS_ICON_COLORS[status] then
				statusIcon.Visible = true
				statusIcon.BackgroundColor3 = STATUS_ICON_COLORS[status]
				statusIcon.BackgroundTransparency = 0
			else
				statusIcon.Visible = false
				statusIcon.BackgroundTransparency = 1
			end
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
			local status = (battleState.enemyBrainrot :: any).statusEffect
			statusLabel.Text = status and (status:sub(1, 1):upper() .. status:sub(2)) or ""
		end
		local statusIcon = enemyPanel:FindFirstChild("EnemyStatusIcon") :: Frame?
		if statusIcon then
			local status = (battleState.enemyBrainrot :: any).statusEffect
			if status and STATUS_ICON_COLORS[status] then
				statusIcon.Visible = true
				statusIcon.BackgroundColor3 = STATUS_ICON_COLORS[status]
				statusIcon.BackgroundTransparency = 0
			else
				statusIcon.Visible = false
				statusIcon.BackgroundTransparency = 1
			end
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
	battlePlayerHealthbarFill = nil
	battleEnemyHealthbarFill = nil
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

local function attachHealthbarToModel(model: Model, maxHP: number, currentHP: number): (BillboardGui, Frame)
	local attachPart = model:FindFirstChildWhichIsA("BasePart") :: BasePart
	if not attachPart then
		return nil, nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Healthbar"
	billboard.Size = UDim2.new(0, 80, 0, 12)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = attachPart

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 2)
	bgCorner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(math.clamp(currentHP / math.max(maxHP, 1), 0, 1), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = fill

	return billboard, fill
end

local function spawnBrainrotModel(brainrotId: string, position: Vector3, facing: CFrame)
	local lookupName = getModelLookupName(brainrotId)
	local template = BrainrotModelsFolder:FindFirstChild(lookupName)
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

	-- Ensure all parts are anchored and non-colliding in battle arena
	for _, desc in ipairs(model:GetDescendants()) do
		local part = desc :: any
		if typeof(part) == "Instance" and part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
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

	local lookupName = getModelLookupName(brainrotId)
	local template = BrainrotModelsFolder:FindFirstChild(lookupName)
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

local function showLevelUpPopup(displayName: string, newLevel: number)
	local existing = PlayerGui:FindFirstChild("BrainrotLevelUpPopup") :: ScreenGui?
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotLevelUpPopup"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Name = "PopupFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0.28, 0, 0.2, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	frame.BackgroundTransparency = 0.1
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(180, 220, 255)
	title.Text = "Level Up!"
	title.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "LevelLabel"
	label.Size = UDim2.new(1, -20, 0, 40)
	label.Position = UDim2.new(0, 10, 0, 42)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = 16
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextWrapped = true
	label.Text = string.format("%s reached level %d!", displayName or "Brainrot", newLevel or 1)
	label.Parent = frame

	local function dismiss()
		if gui and gui.Parent then
			gui:Destroy()
		end
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)

	task.delay(3, dismiss)
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
	elseif action == "levelUp" and payload then
		showLevelUpPopup(payload.displayName or payload.brainrotId, payload.newLevel or 1)
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
	screenGui.DisplayOrder = 100
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
	local friendsButton = createTabButton("FriendsButton", "Friends")
	local brainrotsButton = createTabButton("BrainrotsButton", "Brainrots")
	local pcButton = createTabButton("PCButton", "PC / Boxes")

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

	local bagFrame = Instance.new("Frame")
	bagFrame.Name = "BagFrame"
	bagFrame.Size = UDim2.new(1, 0, 1, 0)
	bagFrame.BackgroundTransparency = 1
	bagFrame.Visible = false
	bagFrame.Parent = contentBody

	local bagList = Instance.new("ScrollingFrame")
	bagList.Name = "BagList"
	bagList.Size = UDim2.new(0.45, -4, 1, 0)
	bagList.Position = UDim2.new(0, 0, 0, 0)
	bagList.CanvasSize = UDim2.new(0, 0, 0, 0)
	bagList.BackgroundTransparency = 1
	bagList.ScrollBarThickness = 4
	bagList.Parent = bagFrame

	local bagLayout = Instance.new("UIListLayout")
	bagLayout.FillDirection = Enum.FillDirection.Vertical
	bagLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bagLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	bagLayout.Padding = UDim.new(0, 4)
	bagLayout.Parent = bagList

	local bagDetail = Instance.new("Frame")
	bagDetail.Name = "BagDetail"
	bagDetail.Size = UDim2.new(0.55, -4, 1, 0)
	bagDetail.Position = UDim2.new(0.45, 4, 0, 0)
	bagDetail.BackgroundTransparency = 1
	bagDetail.Parent = bagFrame

	local bagDetailLabel = Instance.new("TextLabel")
	bagDetailLabel.Name = "BagDetailLabel"
	bagDetailLabel.Size = UDim2.new(1, -8, 1, -60)
	bagDetailLabel.Position = UDim2.new(0, 0, 0, 0)
	bagDetailLabel.BackgroundTransparency = 1
	bagDetailLabel.TextColor3 = Color3.new(1, 1, 1)
	bagDetailLabel.Font = Enum.Font.Gotham
	bagDetailLabel.TextSize = 14
	bagDetailLabel.TextWrapped = true
	bagDetailLabel.TextXAlignment = Enum.TextXAlignment.Left
	bagDetailLabel.TextYAlignment = Enum.TextYAlignment.Top
	bagDetailLabel.Text = "Select an item to view details."
	bagDetailLabel.Parent = bagDetail

	local bagUseButton = Instance.new("TextButton")
	bagUseButton.Name = "BagUseButton"
	bagUseButton.Size = UDim2.new(1, 0, 0, 32)
	bagUseButton.Position = UDim2.new(0, 0, 1, -40)
	bagUseButton.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	bagUseButton.TextColor3 = Color3.new(1, 1, 1)
	bagUseButton.Font = Enum.Font.GothamBold
	bagUseButton.TextSize = 14
	bagUseButton.Text = "Use"
	bagUseButton.Visible = false
	bagUseButton.Parent = bagDetail

	local bagUseCorner = Instance.new("UICorner")
	bagUseCorner.CornerRadius = UDim.new(0, 6)
	bagUseCorner.Parent = bagUseButton

	local bagPartyDropdown = Instance.new("TextButton")
	bagPartyDropdown.Name = "BagPartyDropdown"
	bagPartyDropdown.Size = UDim2.new(1, 0, 0, 20)
	bagPartyDropdown.Position = UDim2.new(0, 0, 1, -76)
	bagPartyDropdown.BackgroundTransparency = 1
	bagPartyDropdown.TextColor3 = Color3.fromRGB(200, 200, 220)
	bagPartyDropdown.Font = Enum.Font.Gotham
	bagPartyDropdown.TextSize = 12
	bagPartyDropdown.TextXAlignment = Enum.TextXAlignment.Left
	bagPartyDropdown.Text = ""
	bagPartyDropdown.Visible = false
	bagPartyDropdown.Parent = bagDetail

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

	local trainerDiagnosticsLabel = Instance.new("TextLabel")
	trainerDiagnosticsLabel.Name = "TrainerDiagnostics"
	trainerDiagnosticsLabel.Size = UDim2.new(1, 0, 0, 40)
	trainerDiagnosticsLabel.Position = UDim2.new(0, 0, 0, 96)
	trainerDiagnosticsLabel.BackgroundTransparency = 1
	trainerDiagnosticsLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	trainerDiagnosticsLabel.Font = Enum.Font.Gotham
	trainerDiagnosticsLabel.TextSize = 14
	trainerDiagnosticsLabel.TextXAlignment = Enum.TextXAlignment.Left
	trainerDiagnosticsLabel.TextYAlignment = Enum.TextYAlignment.Top
	trainerDiagnosticsLabel.TextWrapped = true
	trainerDiagnosticsLabel.Text = ""
	trainerDiagnosticsLabel.Parent = trainerFrame

	local trainerImage = Instance.new("ImageLabel")
	trainerImage.Name = "TrainerImage"
	trainerImage.Size = UDim2.new(0, 160, 0, 160)
	trainerImage.AnchorPoint = Vector2.new(0.5, 0)
	trainerImage.Position = UDim2.new(0.5, 0, 0, 140)
	trainerImage.BackgroundTransparency = 1
	trainerImage.ScaleType = Enum.ScaleType.Fit
	trainerImage.Parent = trainerFrame

	local trainerImageStroke = Instance.new("UIStroke")
	trainerImageStroke.Thickness = 3
	trainerImageStroke.Color = Color3.fromRGB(120, 80, 40)
	trainerImageStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trainerImageStroke.Parent = trainerImage

	local trainerLevelLabel = Instance.new("TextLabel")
	trainerLevelLabel.Name = "TrainerLevel"
	trainerLevelLabel.Size = UDim2.new(1, 0, 0, 24)
	trainerLevelLabel.Position = UDim2.new(0, 0, 0, 308)
	trainerLevelLabel.BackgroundTransparency = 1
	trainerLevelLabel.TextColor3 = Color3.new(1, 1, 1)
	trainerLevelLabel.Font = Enum.Font.GothamBold
	trainerLevelLabel.TextSize = 16
	trainerLevelLabel.TextXAlignment = Enum.TextXAlignment.Center
	trainerLevelLabel.Text = ""
	trainerLevelLabel.Parent = trainerFrame

	local badgesFrame = Instance.new("Frame")
	badgesFrame.Name = "BadgesFrame"
	badgesFrame.Size = UDim2.new(1, -20, 0, 40)
	badgesFrame.Position = UDim2.new(0, 10, 1, -50)
	badgesFrame.BackgroundTransparency = 1
	badgesFrame.Parent = trainerFrame

	local badgesLabel = Instance.new("TextLabel")
	badgesLabel.Name = "BadgesLabel"
	badgesLabel.Size = UDim2.new(0, 80, 1, 0)
	badgesLabel.Position = UDim2.new(0, 0, 0, 0)
	badgesLabel.BackgroundTransparency = 1
	badgesLabel.TextColor3 = Color3.new(1, 1, 1)
	badgesLabel.Font = Enum.Font.GothamBold
	badgesLabel.TextSize = 14
	badgesLabel.TextXAlignment = Enum.TextXAlignment.Left
	badgesLabel.Text = "Badges:"
	badgesLabel.Parent = badgesFrame

	local badgesList = Instance.new("Frame")
	badgesList.Name = "BadgesList"
	badgesList.Size = UDim2.new(1, -90, 1, 0)
	badgesList.Position = UDim2.new(0, 90, 0, 0)
	badgesList.BackgroundTransparency = 1
	badgesList.Parent = badgesFrame

	local badgesLayout = Instance.new("UIListLayout")
	badgesLayout.FillDirection = Enum.FillDirection.Horizontal
	badgesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	badgesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgesLayout.Padding = UDim.new(0, 6)
	badgesLayout.Parent = badgesList

	for i = 1, 8 do
		local socket = Instance.new("Frame")
		socket.Name = "BadgeSocket" .. i
		socket.Size = UDim2.new(0, 32, 0, 32)
		socket.BackgroundTransparency = 1
		socket.Parent = badgesList

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(140, 140, 200)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = socket
	end

	local dexFrame = Instance.new("Frame")
	dexFrame.Name = "DexFrame"
	dexFrame.Size = UDim2.new(1, 0, 1, 0)
	dexFrame.BackgroundTransparency = 1
	dexFrame.Visible = false
	dexFrame.Parent = contentBody

	local dexList = Instance.new("ScrollingFrame")
	dexList.Name = "DexList"
	dexList.Size = UDim2.new(0.45, 0, 1, 0)
	dexList.CanvasSize = UDim2.new(0, 0, 0, 0)
	dexList.BackgroundTransparency = 1
	dexList.ScrollBarThickness = 4
	dexList.Parent = dexFrame

	local dexLayout = Instance.new("UIListLayout")
	dexLayout.FillDirection = Enum.FillDirection.Vertical
	dexLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	dexLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	dexLayout.Padding = UDim.new(0, 4)
	dexLayout.Parent = dexList

	local dexDetail = Instance.new("TextLabel")
	dexDetail.Name = "DexDetail"
	dexDetail.Size = UDim2.new(0.52, 0, 1, 0)
	dexDetail.Position = UDim2.new(0.48, 0, 0, 0)
	dexDetail.BackgroundTransparency = 1
	dexDetail.TextColor3 = Color3.new(1, 1, 1)
	dexDetail.Font = Enum.Font.Gotham
	dexDetail.TextSize = 16
	dexDetail.TextXAlignment = Enum.TextXAlignment.Left
	dexDetail.TextYAlignment = Enum.TextYAlignment.Top
	dexDetail.TextWrapped = true
	dexDetail.Text = "Select a brainrot to view details."
	dexDetail.Parent = dexFrame

	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Size = UDim2.new(1, 0, 1, 0)
	settingsFrame.BackgroundTransparency = 1
	settingsFrame.Visible = false
	settingsFrame.Parent = contentBody

	local friendsFrame = Instance.new("Frame")
	friendsFrame.Name = "FriendsFrame"
	friendsFrame.Size = UDim2.new(1, 0, 1, 0)
	friendsFrame.BackgroundTransparency = 1
	friendsFrame.Visible = false
	friendsFrame.Parent = contentBody

	local friendsStatusLabel = Instance.new("TextLabel")
	friendsStatusLabel.Name = "FriendsStatus"
	friendsStatusLabel.Size = UDim2.new(1, 0, 0, 24)
	friendsStatusLabel.Position = UDim2.new(0, 0, 0, 0)
	friendsStatusLabel.BackgroundTransparency = 1
	friendsStatusLabel.TextColor3 = Color3.fromRGB(160, 220, 160)
	friendsStatusLabel.Font = Enum.Font.Gotham
	friendsStatusLabel.TextSize = 14
	friendsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	friendsStatusLabel.Text = ""
	friendsStatusLabel.Visible = false
	friendsStatusLabel.Parent = friendsFrame

	local friendsList = Instance.new("ScrollingFrame")
	friendsList.Name = "FriendsList"
	friendsList.Size = UDim2.new(1, 0, 1, -28)
	friendsList.Position = UDim2.new(0, 0, 0, 28)
	friendsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	friendsList.BackgroundTransparency = 1
	friendsList.ScrollBarThickness = 4
	friendsList.Parent = friendsFrame

	local friendsLayout = Instance.new("UIListLayout")
	friendsLayout.FillDirection = Enum.FillDirection.Vertical
	friendsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	friendsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	friendsLayout.Padding = UDim.new(0, 4)
	friendsLayout.Parent = friendsList

	local settingsLabel = Instance.new("TextLabel")
	settingsLabel.Name = "SettingsLabel"
	settingsLabel.Size = UDim2.new(1, 0, 0, 24)
	settingsLabel.Position = UDim2.new(0, 0, 0, 0)
	settingsLabel.BackgroundTransparency = 1
	settingsLabel.TextColor3 = Color3.new(1, 1, 1)
	settingsLabel.Font = Enum.Font.GothamBold
	settingsLabel.TextSize = 18
	settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
	settingsLabel.Text = "Settings"
	settingsLabel.Parent = settingsFrame

	local SoundService = game:GetService("SoundService")
	local musicGroup = SoundService:FindFirstChild("MenuMusic") or Instance.new("SoundGroup")
	musicGroup.Name = "MenuMusic"
	musicGroup.Volume = 1
	musicGroup.Parent = SoundService

	local sfxGroup = SoundService:FindFirstChild("MenuSFX") or Instance.new("SoundGroup")
	sfxGroup.Name = "MenuSFX"
	sfxGroup.Volume = 1
	sfxGroup.Parent = SoundService

	local function createSettingsToggle(parent: Frame, name: string, label: string, yOffset: number, getValue: () -> boolean, setValue: (v: boolean) -> ())
		local row = Instance.new("Frame")
		row.Name = name
		row.Size = UDim2.new(1, 0, 0, 32)
		row.Position = UDim2.new(0, 0, 0, yOffset)
		row.BackgroundTransparency = 1
		row.Parent = parent

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.6, 0, 1, 0)
		lbl.Position = UDim2.new(0, 0, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 16
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = label
		lbl.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 80, 0, 24)
		btn.Position = UDim2.new(0.65, 0, 0.5, -12)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = row

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		local function update()
			local v = getValue()
			btn.Text = v and "On" or "Off"
		end
		update()

		btn.MouseButton1Click:Connect(function()
			setValue(not getValue())
			update()
		end)
		return row, update
	end

	local musicToggleRow, refreshMusic = createSettingsToggle(settingsFrame, "MusicToggle", "Music", 32, function()
		return musicGroup.Volume > 0.5
	end, function(v)
		musicGroup.Volume = v and 1 or 0
		SetSettings:FireServer(v, nil, nil)
	end)

	local _, refreshSFX = createSettingsToggle(settingsFrame, "SFXToggle", "Sound Effects", 68, function()
		return sfxGroup.Volume > 0.5
	end, function(v)
		sfxGroup.Volume = v and 1 or 0
		SetSettings:FireServer(nil, v, nil)
	end)

	local refreshSettingsToggles = function()
		if refreshMusic then refreshMusic() end
		if refreshSFX then refreshSFX() end
	end

	local cameraRow = Instance.new("Frame")
	cameraRow.Name = "CameraSensitivity"
	cameraRow.Size = UDim2.new(1, 0, 0, 40)
	cameraRow.Position = UDim2.new(0, 0, 0, 108)
	cameraRow.BackgroundTransparency = 1
	cameraRow.Parent = settingsFrame

	local cameraLabel = Instance.new("TextLabel")
	cameraLabel.Size = UDim2.new(1, 0, 0, 20)
	cameraLabel.Position = UDim2.new(0, 0, 0, 0)
	cameraLabel.BackgroundTransparency = 1
	cameraLabel.TextColor3 = Color3.new(1, 1, 1)
	cameraLabel.Font = Enum.Font.Gotham
	cameraLabel.TextSize = 16
	cameraLabel.TextXAlignment = Enum.TextXAlignment.Left
	cameraLabel.Text = "Camera Sensitivity"
	cameraLabel.Parent = cameraRow

	local cameraSlider = Instance.new("TextButton")
	cameraSlider.Size = UDim2.new(1, 0, 0, 20)
	cameraSlider.Position = UDim2.new(0, 0, 0, 22)
	cameraSlider.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
	cameraSlider.TextColor3 = Color3.new(1, 1, 1)
	cameraSlider.Font = Enum.Font.Gotham
	cameraSlider.TextSize = 14
	cameraSlider.Text = "1.0"
	cameraSlider.Parent = cameraRow

	local cameraCorner = Instance.new("UICorner")
	cameraCorner.CornerRadius = UDim.new(0, 6)
	cameraCorner.Parent = cameraSlider

	local cameraSensitivity = 1.0
	cameraSlider.MouseButton1Click:Connect(function()
		cameraSensitivity = cameraSensitivity + 0.25
		if cameraSensitivity > 2 then
			cameraSensitivity = 0.5
		end
		cameraSlider.Text = string.format("%.1f", cameraSensitivity)
		SetSettings:FireServer(nil, nil, cameraSensitivity)
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraSubject = cam.CameraSubject
		end
	end)

	local brainrotsFrame = Instance.new("Frame")
	brainrotsFrame.Name = "BrainrotsFrame"
	brainrotsFrame.Size = UDim2.new(1, 0, 1, 0)
	brainrotsFrame.BackgroundTransparency = 1
	brainrotsFrame.Visible = false
	brainrotsFrame.Parent = contentBody

	local brainrotsFilterFrame = Instance.new("Frame")
	brainrotsFilterFrame.Name = "BrainrotsFilter"
	brainrotsFilterFrame.Size = UDim2.new(0.45, 0, 0, 40)
	brainrotsFilterFrame.Position = UDim2.new(0, 0, 0, 0)
	brainrotsFilterFrame.BackgroundTransparency = 1
	brainrotsFilterFrame.Parent = brainrotsFrame

	local brainrotsFilterLayout = Instance.new("UIListLayout")
	brainrotsFilterLayout.FillDirection = Enum.FillDirection.Horizontal
	brainrotsFilterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	brainrotsFilterLayout.Padding = UDim.new(0, 6)
	brainrotsFilterLayout.Parent = brainrotsFilterFrame

	local brainrotsFilterMode = "all"
	local brainrotsSortMode = "level"

	local function createFilterButton(name: string, label: string)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 70, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.Text = label
		btn.Parent = brainrotsFilterFrame
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn
		return btn
	end

	local filterAllBtn = createFilterButton("FilterAll", "All")
	local filterAliveBtn = createFilterButton("FilterAlive", "Alive")
	local filterFaintedBtn = createFilterButton("FilterFainted", "Fainted")

	local sortDropdown = Instance.new("TextButton")
	sortDropdown.Name = "SortDropdown"
	sortDropdown.Size = UDim2.new(0, 100, 0, 28)
	sortDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	sortDropdown.TextColor3 = Color3.new(1, 1, 1)
	sortDropdown.Font = Enum.Font.Gotham
	sortDropdown.TextSize = 12
	sortDropdown.Text = "Sort: Level"
	sortDropdown.Parent = brainrotsFilterFrame
	local sortCorner = Instance.new("UICorner")
	sortCorner.CornerRadius = UDim.new(0, 6)
	sortCorner.Parent = sortDropdown

	local partyList = Instance.new("Frame")
	partyList.Name = "PartyList"
	partyList.Size = UDim2.new(0.45, 0, 1, -44)
	partyList.Position = UDim2.new(0, 0, 0, 44)
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
	brainrotDetail.Size = UDim2.new(0.5, 0, 1, -90)
	brainrotDetail.Position = UDim2.new(0.48, 0, 0, 90)
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

	local sendToPCButton = Instance.new("TextButton")
	sendToPCButton.Name = "SendToPCButton"
	sendToPCButton.Size = UDim2.new(0, 120, 0, 24)
	sendToPCButton.Position = UDim2.new(0.48, 0, 0, 88)
	sendToPCButton.BackgroundColor3 = Color3.fromRGB(40, 60, 80)
	sendToPCButton.TextColor3 = Color3.new(1, 1, 1)
	sendToPCButton.Font = Enum.Font.GothamBold
	sendToPCButton.TextSize = 14
	sendToPCButton.TextXAlignment = Enum.TextXAlignment.Left
	sendToPCButton.Text = "Send to PC"
	sendToPCButton.Parent = brainrotsFrame

	local sendToPCCorner = Instance.new("UICorner")
	sendToPCCorner.CornerRadius = UDim.new(0, 6)
	sendToPCCorner.Parent = sendToPCButton

	local pcFrame = Instance.new("Frame")
	pcFrame.Name = "PCFrame"
	pcFrame.Size = UDim2.new(1, 0, 1, 0)
	pcFrame.BackgroundTransparency = 1
	pcFrame.Visible = false
	pcFrame.Parent = contentBody

	local pcHeader = Instance.new("TextLabel")
	pcHeader.Name = "PCHeader"
	pcHeader.Size = UDim2.new(1, 0, 0, 24)
	pcHeader.Position = UDim2.new(0, 0, 0, 0)
	pcHeader.BackgroundTransparency = 1
	pcHeader.TextColor3 = Color3.new(1, 1, 1)
	pcHeader.Font = Enum.Font.GothamBold
	pcHeader.TextSize = 18
	pcHeader.TextXAlignment = Enum.TextXAlignment.Left
	pcHeader.Text = "PC Storage"
	pcHeader.Parent = pcFrame

	local pcPageLabel = Instance.new("TextLabel")
	pcPageLabel.Name = "PCPageLabel"
	pcPageLabel.Size = UDim2.new(0, 160, 0, 22)
	pcPageLabel.Position = UDim2.new(0, 0, 0, 26)
	pcPageLabel.BackgroundTransparency = 1
	pcPageLabel.TextColor3 = Color3.new(1, 1, 1)
	pcPageLabel.Font = Enum.Font.Gotham
	pcPageLabel.TextSize = 14
	pcPageLabel.TextXAlignment = Enum.TextXAlignment.Left
	pcPageLabel.Text = "Box 1 / 1"
	pcPageLabel.Parent = pcFrame

	local pcPrevButton = Instance.new("TextButton")
	pcPrevButton.Name = "PCPrevButton"
	pcPrevButton.Size = UDim2.new(0, 28, 0, 22)
	pcPrevButton.Position = UDim2.new(0, 170, 0, 26)
	pcPrevButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	pcPrevButton.TextColor3 = Color3.new(1, 1, 1)
	pcPrevButton.Font = Enum.Font.GothamBold
	pcPrevButton.TextSize = 14
	pcPrevButton.Text = "<"
	pcPrevButton.Parent = pcFrame

	local pcNextButton = Instance.new("TextButton")
	pcNextButton.Name = "PCNextButton"
	pcNextButton.Size = UDim2.new(0, 28, 0, 22)
	pcNextButton.Position = UDim2.new(0, 204, 0, 26)
	pcNextButton.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	pcNextButton.TextColor3 = Color3.new(1, 1, 1)
	pcNextButton.Font = Enum.Font.GothamBold
	pcNextButton.TextSize = 14
	pcNextButton.Text = ">"
	pcNextButton.Parent = pcFrame

	local pcList = Instance.new("Frame")
	pcList.Name = "PCList"
	pcList.Size = UDim2.new(0.52, 0, 1, -54)
	pcList.Position = UDim2.new(0, 0, 0, 54)
	pcList.BackgroundTransparency = 1
	pcList.Parent = pcFrame

	local pcLayout = Instance.new("UIGridLayout")
	pcLayout.CellSize = UDim2.new(0, 110, 0, 60)
	pcLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	pcLayout.FillDirection = Enum.FillDirection.Horizontal
	pcLayout.FillDirectionMaxCells = 5
	pcLayout.Parent = pcList

	local pcDetail = Instance.new("TextLabel")
	pcDetail.Name = "PCDetail"
	pcDetail.Size = UDim2.new(0.46, 0, 1, -90)
	pcDetail.Position = UDim2.new(0.54, 0, 0, 54)
	pcDetail.BackgroundTransparency = 1
	pcDetail.TextColor3 = Color3.new(1, 1, 1)
	pcDetail.Font = Enum.Font.Gotham
	pcDetail.TextSize = 16
	pcDetail.TextXAlignment = Enum.TextXAlignment.Left
	pcDetail.TextYAlignment = Enum.TextYAlignment.Top
	pcDetail.TextWrapped = true
	pcDetail.Text = "Select a brainrot on the left to see details."
	pcDetail.Parent = pcFrame

	local pcErrorLabel = Instance.new("TextLabel")
	pcErrorLabel.Name = "PCError"
	pcErrorLabel.Size = UDim2.new(0.46, 0, 0, 24)
	pcErrorLabel.Position = UDim2.new(0.54, 0, 1, -30)
	pcErrorLabel.BackgroundTransparency = 1
	pcErrorLabel.TextColor3 = Color3.fromRGB(255, 160, 160)
	pcErrorLabel.Font = Enum.Font.Gotham
	pcErrorLabel.TextSize = 14
	pcErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
	pcErrorLabel.Text = ""
	pcErrorLabel.Parent = pcFrame

	local pcButtonsFrame = Instance.new("Frame")
	pcButtonsFrame.Name = "PCButtons"
	pcButtonsFrame.Size = UDim2.new(0.46, 0, 0, 26)
	pcButtonsFrame.Position = UDim2.new(0.54, 0, 0, 28)
	pcButtonsFrame.BackgroundTransparency = 1
	pcButtonsFrame.Parent = pcFrame

	local pcButtonsLayout = Instance.new("UIListLayout")
	pcButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
	pcButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	pcButtonsLayout.Padding = UDim.new(0, 6)
	pcButtonsLayout.Parent = pcButtonsFrame

	local function createPCActionButton(name: string, label: string)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(0, 110, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.Text = label

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = button

		button.Parent = pcButtonsFrame
		return button
	end

	local pcAddToPartyButton = createPCActionButton("AddToPartyButton", "Add to Party")
	local pcSwapWithPartyButton = createPCActionButton("SwapWithPartyButton", "Swap with Party")
	local pcReleaseButton = createPCActionButton("PCReleaseButton", "Release")

	local function hideAllContent()
		bagFrame.Visible = false
		trainerFrame.Visible = false
		dexFrame.Visible = false
		settingsFrame.Visible = false
		friendsFrame.Visible = false
		brainrotsFrame.Visible = false
		pcFrame.Visible = false
	end

	local currentSelectedPartyIndex: number? = nil
	local pcSelectedCollectionIndex: number? = nil
	local PC_SLOTS_PER_PAGE = 30
	local pcCurrentPage = 1

	local bagState = { selectedItem = nil, selectedPartyIndex = 1 }

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
			bagState.selectedItem = nil
			bagDetailLabel.Text = "Select an item to view details."
			bagUseButton.Visible = false
			bagPartyDropdown.Visible = false

			for _, entry in ipairs(data.bag or {}) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -4, 0, 24)
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
				btn.BackgroundTransparency = 0.5
				btn.TextColor3 = Color3.new(1, 1, 1)
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Text = string.format("%s x%d", entry.displayName, entry.quantity)
				btn.Parent = bagList

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 4)
				corner.Parent = btn

				btn.MouseButton1Click:Connect(function()
					bagState.selectedItem = entry
					bagState.selectedPartyIndex = data.leaderIndex or 1
					local itemDef = Items.getById(entry.id)
					local desc = itemDef and (itemDef.description or "") or ""
					local ability = itemDef and (itemDef :: any).ability or ""
					bagDetailLabel.Text = string.format("%s x%d\n\n%s", entry.displayName, entry.quantity, desc)
					if ability and ability ~= "" then
						bagDetailLabel.Text ..= "\n\n" .. ability
					end

					local effect = itemDef and itemDef.effect
					local usableOutside = effect and (effect.heal or effect.revive)
					bagUseButton.Visible = usableOutside
					if usableOutside then
						local party = data.party or {}
						local names = {}
						for i, mon in ipairs(party) do
							local status = mon.hp <= 0 and " (fainted)" or (" HP " .. mon.hp .. "/" .. mon.maxHP)
							table.insert(names, i .. ": " .. (mon.displayName or "?") .. status)
						end
						bagPartyDropdown.Text = "Use on: " .. (names[bagState.selectedPartyIndex] or "—")
						bagPartyDropdown.Visible = #party > 0
					else
						bagPartyDropdown.Visible = false
					end
				end)
			end

			bagList.CanvasSize = UDim2.new(0, 0, 0, math.max(1, #(data.bag or {})) * 28)
		end

		local function rebuildTrainerCard()
			trainerNameLabel.Text = "Trainer: " .. (data.trainerName or LocalPlayer.Name)

			local stats = data.stats or {}
			trainerStatsLabel.Text = string.format(
				"Total Brainrots Caught: %d\nBattles Won: %d\nBattles Lost: %d",
				stats.totalCaught or 0,
				stats.battlesWon or 0,
				stats.battlesLost or 0
			)

			local wins = stats.battlesWon or 0
			local trainerLevelTitle
			if wins < 10 then
				trainerLevelTitle = "Low-level zero rebirth brainrotter"
			elseif wins < 30 then
				trainerLevelTitle = "Mid-tier meme wrangler"
			elseif wins < 60 then
				trainerLevelTitle = "High-level sigma strategist"
			else
				trainerLevelTitle = "Ascended giga-brainrot overlord"
			end
			trainerLevelLabel.Text = trainerLevelTitle

			local dexSeen = data.dexSeen or {}
			local dexCaught = data.dexCaught or {}

			local uniqueSeen = 0
			for _id, _ in pairs(dexSeen) do
				uniqueSeen += 1
			end

			local uniqueCaught = 0
			for _id, _ in pairs(dexCaught) do
				uniqueCaught += 1
			end

			trainerDiagnosticsLabel.Text = string.format(
				"Brainrots caught: %d\nUnique brainrots seen: %d",
				uniqueCaught,
				uniqueSeen
			)

			if trainerImage.Image == "" then
				local success, thumb = pcall(function()
					return Players:GetUserThumbnailAsync(
						LocalPlayer.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size420x420
					)
				end)
				if success and thumb then
					trainerImage.Image = thumb
				end
			end
		end

		local function setupBrainrotIcon(viewport: ViewportFrame, monId: string)
			for _, child in ipairs(viewport:GetChildren()) do
				child:Destroy()
			end

			local lookupName = getModelLookupName(monId)
			local template = BrainrotModelsFolder:FindFirstChild(lookupName)
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

		local function rebuildDex()
			clearChildren(dexList)
			dexLayout.Parent = dexList

			local seen = data.dexSeen or {}
			local caught = data.dexCaught or {}
			local ids = {}
			for id, _ in pairs(seen) do
				table.insert(ids, id)
			end
			table.sort(ids)

			for _, id in ipairs(ids) do
				local status = caught[id] and "Caught" or "Seen"
				local def = Brainrots.getById(id)
				local displayName = def and def.displayName or id

				local row = Instance.new("TextButton")
				row.Size = UDim2.new(1, -4, 0, 56)
				row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
				row.Text = ""
				row.AutoButtonColor = true
				row.Parent = dexList

				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 6)
				rowCorner.Parent = row

				local icon = Instance.new("ViewportFrame")
				icon.Name = "Icon"
				icon.Size = UDim2.new(0, 48, 0, 48)
				icon.Position = UDim2.new(0, 4, 0.5, -24)
				icon.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
				icon.BorderSizePixel = 0
				icon.Parent = row

				setupBrainrotIcon(icon, id)

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Size = UDim2.new(1, -60, 0, 24)
				nameLabel.Position = UDim2.new(0, 56, 0, 4)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextSize = 14
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Text = displayName
				nameLabel.Parent = row

				local statusLabel = Instance.new("TextLabel")
				statusLabel.Size = UDim2.new(1, -60, 0, 20)
				statusLabel.Position = UDim2.new(0, 56, 0, 28)
				statusLabel.BackgroundTransparency = 1
				statusLabel.TextColor3 = caught[id] and Color3.fromRGB(160, 220, 160) or Color3.fromRGB(180, 180, 200)
				statusLabel.Font = Enum.Font.Gotham
				statusLabel.TextSize = 12
				statusLabel.TextXAlignment = Enum.TextXAlignment.Left
				statusLabel.Text = status
				statusLabel.Parent = row

				row.MouseButton1Click:Connect(function()
					local desc = def and def.description or "No description."
					local stats = def and def.baseStats or {}
					local brainrotType = def and (def :: any).type or "Neutral"
					local movesText = ""
					if def and def.moves then
						for _, move in ipairs(def.moves) do
							movesText ..= string.format("- %s (Pwr %d)\n", move.name, move.power or 0)
						end
					end
					local eff = Brainrots.getTypeEffectivenessInfo(brainrotType)
					local weakStr = #eff.weakTo > 0 and table.concat(eff.weakTo, ", ") or "None"
					local strongStr = #eff.strongAgainst > 0 and table.concat(eff.strongAgainst, ", ") or "None"
					local resistStr = #eff.resistantTo > 0 and table.concat(eff.resistantTo, ", ") or "None"
					local typeInfo = string.format(
						"Type: %s\nWeak to: %s\nStrong against: %s\nResistant to: %s",
						brainrotType,
						weakStr,
						strongStr,
						resistStr
					)
					dexDetail.Text = string.format(
						"%s [%s]\n%s\n\n%s\n\nBase Stats:\nHP: %d  ATK: %d  DEF: %d  SPD: %d\n\nMoves:\n%s",
						displayName,
						brainrotType,
						desc,
						typeInfo,
						stats.maxHP or 30,
						stats.attack or 8,
						stats.defense or 8,
						stats.speed or 8,
						movesText ~= "" and movesText or "None"
					)
				end)
			end

			dexList.CanvasSize = UDim2.new(0, 0, 0, #ids * 60)
		end

		local function rebuildFriends()
			clearChildren(friendsList)
			friendsLayout.Parent = friendsList

			local loadingLabel = Instance.new("TextLabel")
			loadingLabel.Size = UDim2.new(1, -4, 0, 20)
			loadingLabel.BackgroundTransparency = 1
			loadingLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
			loadingLabel.Font = Enum.Font.Gotham
			loadingLabel.TextSize = 14
			loadingLabel.TextXAlignment = Enum.TextXAlignment.Left
			loadingLabel.Text = "Loading friends..."
			loadingLabel.Parent = friendsList

			task.spawn(function()
				local friendRows = {}
				local ok, pages = pcall(function()
					return Players:GetFriendsAsync(LocalPlayer.UserId)
				end)
				if not ok or not pages then
					local err = Instance.new("TextLabel")
					err.Size = UDim2.new(1, -4, 0, 20)
					err.BackgroundTransparency = 1
					err.TextColor3 = Color3.fromRGB(255, 160, 160)
					err.Font = Enum.Font.Gotham
					err.TextSize = 14
					err.TextXAlignment = Enum.TextXAlignment.Left
					err.Text = "Could not load friends."
					err.Parent = friendsList
					friendsList.CanvasSize = UDim2.new(0, 0, 0, 24)
					return
				end

				repeat
					for _, friend in ipairs(pages:GetCurrentPage()) do
						table.insert(friendRows, friend)
					end
					if pages.IsFinished then
						break
					end
					local ok = pcall(function()
						pages:AdvanceToNextPageAsync()
					end)
					if not ok then
						break
					end
				until false

				clearChildren(friendsList)
				friendsLayout.Parent = friendsList

				if #friendRows == 0 then
					local empty = Instance.new("TextLabel")
					empty.Size = UDim2.new(1, -4, 0, 20)
					empty.BackgroundTransparency = 1
					empty.TextColor3 = Color3.fromRGB(180, 180, 200)
					empty.Font = Enum.Font.Gotham
					empty.TextSize = 14
					empty.TextXAlignment = Enum.TextXAlignment.Left
					empty.Text = "No friends yet."
					empty.Parent = friendsList
					friendsList.CanvasSize = UDim2.new(0, 0, 0, 24)
					return
				end

				for _, friend in ipairs(friendRows) do
					local row = Instance.new("Frame")
					row.Size = UDim2.new(1, -4, 0, 36)
					row.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
					row.Parent = friendsList

					local rowCorner = Instance.new("UICorner")
					rowCorner.CornerRadius = UDim.new(0, 6)
					rowCorner.Parent = row

					local statusColor = friend.IsOnline and Color3.fromRGB(80, 220, 80) or Color3.fromRGB(120, 120, 120)
					local statusLabel = Instance.new("TextLabel")
					statusLabel.Size = UDim2.new(0, 12, 0, 12)
					statusLabel.Position = UDim2.new(0, 8, 0.5, -6)
					statusLabel.BackgroundColor3 = statusColor
					statusLabel.BorderSizePixel = 0
					statusLabel.Parent = row

					local statusCorner = Instance.new("UICorner")
					statusCorner.CornerRadius = UDim.new(1, 0)
					statusCorner.Parent = statusLabel

					local nameLabel = Instance.new("TextLabel")
					nameLabel.Size = UDim2.new(1, -140, 1, 0)
					nameLabel.Position = UDim2.new(0, 24, 0, 0)
					nameLabel.BackgroundTransparency = 1
					nameLabel.TextColor3 = Color3.new(1, 1, 1)
					nameLabel.Font = Enum.Font.Gotham
					nameLabel.TextSize = 14
					nameLabel.TextXAlignment = Enum.TextXAlignment.Left
					nameLabel.Text = friend.Username .. (friend.IsOnline and " (online)" or " (offline)")
					nameLabel.Parent = row

					local inviteBtn = Instance.new("TextButton")
					inviteBtn.Size = UDim2.new(0, 80, 0, 24)
					inviteBtn.Position = UDim2.new(1, -88, 0.5, -12)
					inviteBtn.BackgroundColor3 = Color3.fromRGB(50, 70, 50)
					inviteBtn.TextColor3 = Color3.new(1, 1, 1)
					inviteBtn.Font = Enum.Font.GothamBold
					inviteBtn.TextSize = 12
					inviteBtn.Text = "Invite"
					inviteBtn.Parent = row

					local inviteCorner = Instance.new("UICorner")
					inviteCorner.CornerRadius = UDim.new(0, 6)
					inviteCorner.Parent = inviteBtn

					inviteBtn.MouseButton1Click:Connect(function()
						if friend.IsOnline then
							BattleInvite:FireServer(friend.Id)
						end
					end)
				end

				friendsList.CanvasSize = UDim2.new(0, 0, 0, #friendRows * 40)
			end)
		end

		local function rebuildBrainrots()
			clearChildren(partyList)
			partyLayout.Parent = partyList

			local party = data.party or {}
			local leaderIndex = data.leaderIndex or 1

			local filtered = {}
			for index, mon in ipairs(party) do
				if brainrotsFilterMode == "all" then
					table.insert(filtered, { mon = mon, index = index })
				elseif brainrotsFilterMode == "alive" and mon.hp > 0 then
					table.insert(filtered, { mon = mon, index = index })
				elseif brainrotsFilterMode == "fainted" and mon.hp <= 0 then
					table.insert(filtered, { mon = mon, index = index })
				end
			end

			table.sort(filtered, function(a, b)
				if brainrotsSortMode == "level" then
					return (a.mon.level or 1) > (b.mon.level or 1)
				elseif brainrotsSortMode == "name" then
					return (a.mon.displayName or "") < (b.mon.displayName or "")
				elseif brainrotsSortMode == "hp" then
					return (a.mon.hp or 0) > (b.mon.hp or 0)
				end
				return false
			end)

			for _, entry in ipairs(filtered) do
				local mon = entry.mon
				local index = entry.index
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

			if #filtered > 0 then
				local first = filtered[1].mon
				local firstIndex = filtered[1].index
				local movesText = ""
				for _, move in ipairs(first.moves or {}) do
					movesText ..= string.format("- %s (Pwr %d)\n", move.name, move.power or 0)
				end
				currentSelectedPartyIndex = firstIndex
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

		local function rebuildPC()
			clearChildren(pcList)
			pcLayout.Parent = pcList

			local collection = data.collection or {}
			local total = #collection
			if total == 0 then
				pcCurrentPage = 1
				pcPageLabel.Text = "Box 1 / 1"
				pcDetail.Text = "No brainrots in storage yet."
				pcErrorLabel.Text = ""
				pcSelectedCollectionIndex = nil
				return
			end

			local totalPages = math.max(1, math.ceil(total / PC_SLOTS_PER_PAGE))
			if pcCurrentPage > totalPages then
				pcCurrentPage = totalPages
			end

			pcPageLabel.Text = string.format("Box %d / %d", pcCurrentPage, totalPages)
			pcErrorLabel.Text = ""

			local startIndex = (pcCurrentPage - 1) * PC_SLOTS_PER_PAGE + 1
			local endIndex = math.min(startIndex + PC_SLOTS_PER_PAGE - 1, total)

			for globalIndex = startIndex, endIndex do
				local entry = collection[globalIndex]
				if entry then
					local slot = Instance.new("TextButton")
					slot.Size = UDim2.new(0, 110, 0, 60)
					slot.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
					slot.TextColor3 = Color3.new(1, 1, 1)
					slot.Font = Enum.Font.Gotham
					slot.TextSize = 14
					slot.TextWrapped = true

					local labelText = string.format("%s\nLv.%d", entry.displayName or entry.id, entry.level or 1)
					if entry.isInParty and entry.partyIndex then
						labelText ..= string.format("\n(In party %d)", entry.partyIndex)
					end
					slot.Text = labelText
					slot.Parent = pcList

					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 6)
					corner.Parent = slot

					slot.MouseButton1Click:Connect(function()
						pcSelectedCollectionIndex = globalIndex

						local detailText = string.format(
							"%s Lv.%d\nHP: %d/%d",
							entry.displayName or entry.id,
							entry.level or 1,
							entry.hp or 0,
							entry.maxHP or 0
						)

						local def = Brainrots.getById(entry.id)
						if def and def.moves then
							detailText ..= "\n\nMoves:\n"
							for _, move in ipairs(def.moves) do
								detailText ..= string.format("- %s (Pwr %d)\n", move.name, move.power or 0)
							end
						end

						if entry.isInParty and entry.partyIndex then
							detailText ..= string.format("\nCurrently in party slot %d.", entry.partyIndex)
						end

						pcDetail.Text = detailText
					end)
				end
			end

			if not pcSelectedCollectionIndex or pcSelectedCollectionIndex < 1 or pcSelectedCollectionIndex > total then
				pcSelectedCollectionIndex = nil
				pcDetail.Text = "Select a brainrot on the left to see details."
			end
		end

		rebuildBag()
		rebuildTrainerCard()
		rebuildDex()
		rebuildFriends()
		rebuildBrainrots()
		rebuildPC()
	end

	local function openSection(section: string)
		hideAllContent()
		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		if section == "bag" then
			contentLabel.Text = "Bag"
			bagFrame.Visible = true
		elseif section == "trainer" then
			contentLabel.Text = "Trainer Card"
			trainerFrame.Visible = true
		elseif section == "dex" then
			contentLabel.Text = "Troppi-dex"
			dexFrame.Visible = true
		elseif section == "settings" then
			contentLabel.Text = "Settings"
			settingsFrame.Visible = true
			local s = data.settings or {}
			musicGroup.Volume = (s.musicEnabled == false) and 0 or 1
			sfxGroup.Volume = (s.sfxEnabled == false) and 0 or 1
			cameraSensitivity = s.cameraSensitivity or 1
			cameraSlider.Text = string.format("%.1f", cameraSensitivity)
			refreshSettingsToggles()
		elseif section == "friends" then
			contentLabel.Text = "Friends"
			friendsFrame.Visible = true
		elseif section == "brainrots" then
			contentLabel.Text = "Brainrots"
			brainrotsFrame.Visible = true
		elseif section == "pc" then
			contentLabel.Text = "PC / Boxes"
			pcFrame.Visible = true
		end

		refreshTrainerData()
	end

	menuButton.MouseButton1Click:Connect(function()
		menuFrame.Visible = not menuFrame.Visible
	end)

	bagButton.MouseButton1Click:Connect(function()
		openSection("bag")
	end)

	bagUseButton.MouseButton1Click:Connect(function()
		local entry = bagState.selectedItem
		if not entry then return end
		local success, msg = UseItemOutsideBattle:InvokeServer(entry.id, bagState.selectedPartyIndex)
		bagDetailLabel.Text = msg or (success and "Used!" or "Couldn't use.")
		if success then
			bagState.selectedItem = nil
			bagUseButton.Visible = false
			bagPartyDropdown.Visible = false
			refreshTrainerData()
		end
	end)

	bagPartyDropdown.MouseButton1Click:Connect(function()
		local data = GetTrainerData:InvokeServer()
		if not data or not data.party or #data.party == 0 then return end
		bagState.selectedPartyIndex = (bagState.selectedPartyIndex % #data.party) + 1
		local party = data.party
		local mon = party[bagState.selectedPartyIndex]
		local status = mon and (mon.hp <= 0 and " (fainted)" or (" HP " .. mon.hp .. "/" .. mon.maxHP)) or ""
		bagPartyDropdown.Text = "Use on: " .. (mon and (bagState.selectedPartyIndex .. ": " .. (mon.displayName or "?") .. status) or "—")
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

	BattleInviteResponse.OnClientEvent:Connect(function(success: boolean, message: string)
		friendsStatusLabel.Text = message
		friendsStatusLabel.TextColor3 = success and Color3.fromRGB(160, 220, 160) or Color3.fromRGB(255, 160, 160)
		friendsStatusLabel.Visible = true
		task.delay(4, function()
			friendsStatusLabel.Visible = false
		end)
	end)

	friendsButton.MouseButton1Click:Connect(function()
		openSection("friends")
	end)

	brainrotsButton.MouseButton1Click:Connect(function()
		openSection("brainrots")
	end)

	filterAllBtn.MouseButton1Click:Connect(function()
		brainrotsFilterMode = "all"
		refreshTrainerData()
	end)
	filterAliveBtn.MouseButton1Click:Connect(function()
		brainrotsFilterMode = "alive"
		refreshTrainerData()
	end)
	filterFaintedBtn.MouseButton1Click:Connect(function()
		brainrotsFilterMode = "fainted"
		refreshTrainerData()
	end)
	sortDropdown.MouseButton1Click:Connect(function()
		if brainrotsSortMode == "level" then
			brainrotsSortMode = "name"
			sortDropdown.Text = "Sort: Name"
		elseif brainrotsSortMode == "name" then
			brainrotsSortMode = "hp"
			sortDropdown.Text = "Sort: HP"
		else
			brainrotsSortMode = "level"
			sortDropdown.Text = "Sort: Level"
		end
		refreshTrainerData()
	end)

	pcButton.MouseButton1Click:Connect(function()
		openSection("pc")
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

	sendToPCButton.MouseButton1Click:Connect(function()
		if not currentSelectedPartyIndex then
			return
		end

		local ok, err = MoveBrainrotBetweenPartyAndCollection:InvokeServer(currentSelectedPartyIndex, nil)
		if not ok and err then
			brainrotDetail.Text = tostring(err)
		else
			currentSelectedPartyIndex = nil
			refreshTrainerData()
		end
	end)

	pcPrevButton.MouseButton1Click:Connect(function()
		if pcCurrentPage > 1 then
			pcCurrentPage -= 1
			refreshTrainerData()
		end
	end)

	pcNextButton.MouseButton1Click:Connect(function()
		pcCurrentPage += 1
		refreshTrainerData()
	end)

	pcAddToPartyButton.MouseButton1Click:Connect(function()
		if not pcSelectedCollectionIndex then
			return
		end

		local ok, err = MoveBrainrotBetweenPartyAndCollection:InvokeServer(nil, pcSelectedCollectionIndex)
		if not ok and err then
			pcErrorLabel.Text = tostring(err)
		else
			pcErrorLabel.Text = ""
			refreshTrainerData()
		end
	end)

	pcSwapWithPartyButton.MouseButton1Click:Connect(function()
		if not pcSelectedCollectionIndex then
			return
		end

		local data = GetTrainerData:InvokeServer()
		if not data then
			return
		end

		local party = data.party or {}
		if #party == 0 then
			return
		end

		local overlay = Instance.new("ScreenGui")
		overlay.Name = "PCSwapChooser"
		overlay.ResetOnSpawn = false
		overlay.IgnoreGuiInset = true
		overlay.Parent = PlayerGui

		local panel = Instance.new("Frame")
		panel.Size = UDim2.new(0, 260, 0, 40 + #party * 26)
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.new(0.5, 0, 0.5, 0)
		panel.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
		panel.Parent = overlay

		local panelCorner = Instance.new("UICorner")
		panelCorner.CornerRadius = UDim.new(0, 8)
		panelCorner.Parent = panel

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -10, 0, 24)
		title.Position = UDim2.new(0, 5, 0, 4)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.new(1, 1, 1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "Choose party slot to swap"
		title.Parent = panel

		local listFrame = Instance.new("Frame")
		listFrame.Size = UDim2.new(1, -10, 1, -32)
		listFrame.Position = UDim2.new(0, 5, 0, 28)
		listFrame.BackgroundTransparency = 1
		listFrame.Parent = panel

		local listLayout = Instance.new("UIListLayout")
		listLayout.FillDirection = Enum.FillDirection.Vertical
		listLayout.Padding = UDim.new(0, 4)
		listLayout.Parent = listFrame

		for index, mon in ipairs(party) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 22)
			b.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.Gotham
			b.TextSize = 14
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Text = string.format(" Slot %d: %s Lv.%d", index, mon.displayName, mon.level)
			b.Parent = listFrame

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = b

			b.MouseButton1Click:Connect(function()
				local okSwap, errSwap =
					MoveBrainrotBetweenPartyAndCollection:InvokeServer(index, pcSelectedCollectionIndex)
				if not okSwap and errSwap then
					pcErrorLabel.Text = tostring(errSwap)
				else
					pcErrorLabel.Text = ""
					refreshTrainerData()
				end
				overlay:Destroy()
			end)
		end
	end)

	pcReleaseButton.MouseButton1Click:Connect(function()
		if not pcSelectedCollectionIndex then
			return
		end

		local ok, err = ReleaseFromCollection:InvokeServer(pcSelectedCollectionIndex)
		if not ok and err then
			pcErrorLabel.Text = tostring(err)
		else
			pcErrorLabel.Text = ""
			pcSelectedCollectionIndex = nil
			refreshTrainerData()
		end
	end)

	OpenPC.OnClientEvent:Connect(function()
		menuFrame.Visible = true
		openSection("pc")
	end)

	task.spawn(function()
		local data = GetTrainerData:InvokeServer()
		if data and data.settings then
			local s = data.settings
			musicGroup.Volume = (s.musicEnabled == false) and 0 or 1
			sfxGroup.Volume = (s.sfxEnabled == false) and 0 or 1
		end
	end)
end

createMenuGui()

-- Item acquire popup (menu-7)
local itemPopupGui = Instance.new("ScreenGui")
itemPopupGui.Name = "ItemAcquirePopup"
itemPopupGui.ResetOnSpawn = false
itemPopupGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
itemPopupGui.Parent = PlayerGui

ItemAcquired.OnClientEvent:Connect(function(itemId: string, displayName: string, quantity: number)
	local overlay = Instance.new("Frame")
	overlay.Name = "ItemPopupOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Parent = itemPopupGui

	local popup = Instance.new("Frame")
	popup.Name = "ItemPopup"
	popup.Size = UDim2.new(0, 280, 0, 120)
	popup.Position = UDim2.new(0.5, -140, 0.5, -60)
	popup.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
	popup.Parent = overlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 120, 180)
	stroke.Thickness = 2
	stroke.Parent = popup

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 0, 24)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Text = "Item acquired!"
	titleLabel.Parent = popup

	local itemLabel = Instance.new("TextLabel")
	itemLabel.Size = UDim2.new(1, -20, 0, 36)
	itemLabel.Position = UDim2.new(0, 10, 0, 38)
	itemLabel.BackgroundTransparency = 1
	itemLabel.TextColor3 = Color3.new(1, 1, 1)
	itemLabel.Font = Enum.Font.Gotham
	itemLabel.TextSize = 18
	itemLabel.Text = string.format("%s x%d", displayName, quantity)
	itemLabel.Parent = popup

	local dismissLabel = Instance.new("TextLabel")
	dismissLabel.Size = UDim2.new(1, -20, 0, 20)
	dismissLabel.Position = UDim2.new(0, 10, 1, -28)
	dismissLabel.BackgroundTransparency = 1
	dismissLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
	dismissLabel.Font = Enum.Font.Gotham
	dismissLabel.TextSize = 12
	dismissLabel.Text = "Click anywhere to dismiss"
	dismissLabel.Parent = popup

	local function dismiss()
		overlay:Destroy()
	end

	overlay.MouseButton1Click:Connect(dismiss)
	task.delay(3, function()
		if overlay and overlay.Parent then
			dismiss()
		end
	end)
end)

