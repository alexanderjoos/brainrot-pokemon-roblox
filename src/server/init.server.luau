local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(SharedFolder:WaitForChild("Brainrots"))
local Items = require(SharedFolder:WaitForChild("Items"))

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local BattleRequest: RemoteEvent = RemotesFolder:WaitForChild("BattleRequest") :: RemoteEvent
local BattleUpdate: RemoteEvent = RemotesFolder:WaitForChild("BattleUpdate") :: RemoteEvent
local GetTrainerData: RemoteFunction = RemotesFolder:WaitForChild("GetTrainerData") :: RemoteFunction
local BattleAnimation: RemoteEvent = RemotesFolder:WaitForChild("BattleAnimation") :: RemoteEvent
local HealComplete: RemoteEvent = RemotesFolder:WaitForChild("HealComplete") :: RemoteEvent
local SetHeldItem: RemoteEvent = RemotesFolder:WaitForChild("SetHeldItem") :: RemoteEvent
local SetLeader: RemoteEvent = RemotesFolder:WaitForChild("SetLeader") :: RemoteEvent
local ReleaseBrainrot: RemoteEvent = RemotesFolder:WaitForChild("ReleaseBrainrot") :: RemoteEvent

local MoveBrainrotBetweenPartyAndCollectionRemote =
	RemotesFolder:FindFirstChild("MoveBrainrotBetweenPartyAndCollection") :: RemoteFunction?
if not MoveBrainrotBetweenPartyAndCollectionRemote then
	local newRemote = Instance.new("RemoteFunction")
	newRemote.Name = "MoveBrainrotBetweenPartyAndCollection"
	newRemote.Parent = RemotesFolder
	MoveBrainrotBetweenPartyAndCollectionRemote = newRemote
end
local MoveBrainrotBetweenPartyAndCollection = MoveBrainrotBetweenPartyAndCollectionRemote :: RemoteFunction

local ReleaseFromCollectionRemote = RemotesFolder:FindFirstChild("ReleaseFromCollection") :: RemoteFunction?
if not ReleaseFromCollectionRemote then
	local newRelease = Instance.new("RemoteFunction")
	newRelease.Name = "ReleaseFromCollection"
	newRelease.Parent = RemotesFolder
	ReleaseFromCollectionRemote = newRelease
end
local ReleaseFromCollection = ReleaseFromCollectionRemote :: RemoteFunction

local OpenPCRemote = RemotesFolder:FindFirstChild("OpenPC") :: RemoteEvent?
if not OpenPCRemote then
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = "OpenPC"
	newEvent.Parent = RemotesFolder
	OpenPCRemote = newEvent
end
local OpenPC = OpenPCRemote :: RemoteEvent

type BrainrotInstance = {
	id: string,
	displayName: string,
	level: number,
	exp: number?,
	nextLevelExp: number?,
	maxHP: number,
	hp: number,
	attack: number,
	defense: number,
	speed: number,
	moves: { any },
}

type BattleState = {
	playerBrainrot: BrainrotInstance,
	enemyBrainrot: BrainrotInstance,
	state: string,
	arenaOrigin: Vector3?,
	returnCFrame: CFrame?,
}

type TrainerStats = {
	totalCaught: number,
	battlesWon: number,
	battlesLost: number,
	totalReleased: number,
}

type BagItem = {
	id: string,
	displayName: string,
	quantity: number,
}

type TrainerData = {
	party: { BrainrotInstance },
	collection: { BrainrotInstance },
	activeIndex: number,
	bag: { BagItem },
	stats: TrainerStats,
	dexSeen: { [string]: boolean },
	dexCaught: { [string]: boolean },
}

local playerData: { [Player]: TrainerData } = {}
local activeBattles: { [Player]: BattleState } = {}

local MAX_PARTY_SIZE = 6
local COLLECTION_CAP = 200
local TOWN_HALF_X = 135
local TOWN_HALF_Z = 135

local function markDexSeen(data: TrainerData, brainrotId: string)
	data.dexSeen[brainrotId] = true
end

local function markDexCaught(data: TrainerData, brainrotId: string)
	data.dexSeen[brainrotId] = true
	data.dexCaught[brainrotId] = true
end

local function addToBag(data: TrainerData, itemId: string)
	local existing = nil
	for _, entry in ipairs(data.bag) do
		if entry.id == itemId then
			existing = entry
			break
		end
	end

	local itemDef = Items.getById(itemId)
	if not itemDef then
		return
	end

	if existing then
		existing.quantity += 1
	else
		table.insert(data.bag, {
			id = itemDef.id,
			displayName = itemDef.displayName,
			quantity = 1,
		})
	end
end

local function getBagItem(data: TrainerData, itemId: string): BagItem?
	for _, entry in ipairs(data.bag) do
		if entry.id == itemId then
			return entry
		end
	end
	return nil
end

local function sendBattleUpdate(player: Player, battle: BattleState, message: string)
	BattleUpdate:FireClient(player, battle, message)
end

local function sendBattleAnimation(player: Player, action: string, payload: any?)
	BattleAnimation:FireClient(player, action, payload)
end

local function getBrainrotCenterSpawnCFrame(): CFrame?
	local center = Workspace:FindFirstChild("BrainrotCenter")
	if not center then
		return nil
	end
	local spawn = center:FindFirstChild("Spawn") :: BasePart?
	if not spawn then
		return nil
	end
	return spawn.CFrame + Vector3.new(0, 3, 0)
end

local function chooseEnemyMove(enemy: BrainrotInstance)
	local moves = enemy.moves
	if #moves == 0 then
		return nil
	end
	local index = math.random(1, #moves)
	return moves[index]
end

local function performAttack(attacker: BrainrotInstance, defender: BrainrotInstance, move)
	if not move then
		return 0, false
	end

	local hitChance = move.accuracy or 1
	if math.random() > hitChance then
		return 0, false
	end

	local damage = Brainrots.calculateDamage(attacker, defender, move)
	defender.hp = math.max(defender.hp - damage, 0)
	return damage, true
end

local function enemyRespond(player: Player, battle: BattleState, playerMon: BrainrotInstance, enemyMon: BrainrotInstance)
	if battle.state ~= "ongoing" then
		return
	end

	if enemyMon.hp <= 0 then
		return
	end

	local enemyMove = chooseEnemyMove(enemyMon)
	local enemyDamage, enemyHit = performAttack(enemyMon, playerMon, enemyMove)

	if playerMon.hp <= 0 then
		battle.state = "lost"
		local data = playerData[player]
		if data then
			data.stats.battlesLost += 1
		end
		local msg = string.format(
			"%s used %s and dealt %d damage! Your brainrot fainted!",
			enemyMon.displayName,
			enemyMove and enemyMove.name or "an attack",
			enemyDamage
		)
		sendBattleUpdate(player, battle, msg)
		endBattleForPlayer(player, "lost")
		return
	end

	local msg
	if enemyHit then
		msg = string.format(
			"%s used %s and dealt %d damage!",
			enemyMon.displayName,
			enemyMove and enemyMove.name or "an attack",
			enemyDamage
		)
	else
		msg = string.format("%s's attack missed!", enemyMon.displayName)
	end

	sendBattleUpdate(player, battle, msg)
end

local function startWildEncounter(player: Player)
	if activeBattles[player] then
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local data = playerData[player]
	if not data then
		return
	end

	local starter = data.party[data.activeIndex]
	if not starter or starter.hp <= 0 then
		starter = nil
		for i, mon in ipairs(data.party) do
			if mon.hp > 0 then
				starter = mon
				data.activeIndex = i
				break
			end
		end
	end
	if not starter then
		return
	end

	local randomBrainrot = Brainrots.getRandom()
	if not randomBrainrot then
		return
	end

	local enemy = Brainrots.createInstance(randomBrainrot.id, starter.level)

	markDexSeen(data, randomBrainrot.id)

	local baseplate = Workspace:FindFirstChild("Baseplate") :: Part?
	local arenaOrigin = Vector3.new(0, 120, 0)
	if baseplate then
		arenaOrigin = baseplate.Position + Vector3.new(0, baseplate.Size.Y / 2 + 120, 0)
	end

	local returnCFrame = hrp.CFrame
	hrp.CFrame = CFrame.new(arenaOrigin + Vector3.new(-8, 3, 0))

	local battle: BattleState = {
		playerBrainrot = starter,
		enemyBrainrot = enemy,
		state = "ongoing",
		arenaOrigin = arenaOrigin,
		returnCFrame = returnCFrame,
	}

	activeBattles[player] = battle
	sendBattleAnimation(player, "start", {
		playerBrainrotId = starter.id,
		enemyBrainrotId = enemy.id,
		arenaOrigin = arenaOrigin,
	})
	sendBattleUpdate(player, battle, "A wild " .. enemy.displayName .. " appeared!")
end

local function endBattleForPlayer(player: Player, finalState: string?)
	local battle = activeBattles[player]
	if not battle then
		return
	end

	if finalState then
		battle.state = finalState
	end

	local character = player.Character
	local hrp = character and (character:FindFirstChild("HumanoidRootPart") :: BasePart?)
	if hrp then
		local target = battle.returnCFrame
		if finalState == "lost" then
			target = getBrainrotCenterSpawnCFrame() or target
		end
		if target then
			hrp.CFrame = target
		end
	end

	sendBattleAnimation(player, "end", nil)
	activeBattles[player] = nil
end

local function handleBattleRequest(player: Player, action: string, moveId: string?)
	local battle = activeBattles[player]
	if not battle or battle.state ~= "ongoing" then
		return
	end

	local playerMon = battle.playerBrainrot
	local enemyMon = battle.enemyBrainrot

	if action == "run" then
		if (battle :: any).isTrainerBattle then
			sendBattleUpdate(player, battle, "You can't run from a trainer battle!")
			return
		end
		endBattleForPlayer(player, "finished")
		sendBattleUpdate(player, battle, "You ran away!")
		return
	end

	if action == "capture" then
		local data = playerData[player]
		if not data then
			return
		end

		local ballEntry = getBagItem(data, "troppi_ball")
		if not ballEntry or ballEntry.quantity <= 0 then
			sendBattleUpdate(player, battle, "You don't have any Troppi-balls!")
			return
		end

		ballEntry.quantity -= 1
		if ballEntry.quantity <= 0 then
			for index, entry in ipairs(data.bag) do
				if entry == ballEntry then
					table.remove(data.bag, index)
					break
				end
			end
		end

		sendBattleAnimation(player, "captureAttempt", nil)
		local hpRatio = enemyMon.hp / math.max(enemyMon.maxHP, 1)
		local captureChance = math.clamp(0.7 - hpRatio * 0.5, 0.2, 0.9)

		if math.random() < captureChance then
			local data = playerData[player]
			if data then
				if #data.collection >= COLLECTION_CAP then
					sendBattleUpdate(
						player,
						battle,
						"Your collection is full! You couldn't keep the captured brainrot."
					)
				else
					table.insert(data.collection, enemyMon)

					if #data.party < MAX_PARTY_SIZE then
						table.insert(data.party, enemyMon)
					end

					data.stats.totalCaught += 1
					markDexCaught(data, enemyMon.id)
				end
			end
			battle.state = "finished"
			sendBattleUpdate(player, battle, "You captured " .. enemyMon.displayName .. "!")
			sendBattleAnimation(player, "caughtPopup", {
				brainrotId = enemyMon.id,
				displayName = enemyMon.displayName,
			})
			task.delay(2, function()
				if activeBattles[player] == battle then
					endBattleForPlayer(player, "finished")
				end
			end)
		else
			local enemyMove = chooseEnemyMove(enemyMon)
			local damage, hit = performAttack(enemyMon, playerMon, enemyMove)

			if playerMon.hp <= 0 then
				battle.state = "lost"
				sendBattleUpdate(player, battle, enemyMon.displayName .. " knocked out your brainrot!")
				endBattleForPlayer(player, "lost")
			else
				local msg = "Capture failed!"
				if hit then
					msg ..= " " .. enemyMon.displayName .. " used " .. enemyMove.name .. " and dealt " .. tostring(damage) .. " damage!"
				end
				sendBattleUpdate(player, battle, msg)
			end
		end

		return
	end

	if action == "useItem" and moveId then
		local data = playerData[player]
		if not data then
			return
		end

		local itemId = moveId
		local entry = getBagItem(data, itemId)
		local itemDef = Items.getById(itemId)
		if not entry or not itemDef or not itemDef.usableInBattle then
			return
		end

		entry.quantity -= 1
		if entry.quantity <= 0 then
			for index, e in ipairs(data.bag) do
				if e == entry then
					table.remove(data.bag, index)
					break
				end
			end
		end

		if itemId == "energy_drink" then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local applied = false
			if humanoid then
				local originalSpeed = humanoid.WalkSpeed
				humanoid.WalkSpeed = originalSpeed * 1.5
				task.delay(60, function()
					if humanoid then
						humanoid.WalkSpeed = originalSpeed
					end
				end)
				applied = true
			end
			if applied then
				sendBattleUpdate(player, battle, "You used an Energy Drink! Your speed increased for a while.")
			else
				sendBattleUpdate(player, battle, "You used an Energy Drink, but nothing happened.")
			end
		elseif itemId == "henny" then
			if playerMon.hp > 0 then
				sendBattleUpdate(player, battle, "You used Henny, but your brainrot is already conscious.")
			else
				playerMon.hp = math.max(1, math.floor(playerMon.maxHP / 2))
				sendBattleUpdate(
					player,
					battle,
					"You poured Henny on "
						.. playerMon.displayName
						.. "! It revived with half HP."
				)
			end
		end

		enemyRespond(player, battle, playerMon, enemyMon)

		return
	end

	if action == "move" and moveId then
		local chosenMove = nil
		for _, move in ipairs(playerMon.moves) do
			if move.id == moveId then
				chosenMove = move
				break
			end
		end

		if not chosenMove then
			return
		end

		local damage, hit = performAttack(playerMon, enemyMon, chosenMove)

		if enemyMon.hp <= 0 then
			battle.state = "won"
			local data = playerData[player]
			if data then
				data.stats.battlesWon += 1
				markDexCaught(data, enemyMon.id)

				local expGain = math.max(5, enemyMon.level * 10)
				Brainrots.gainExperience(playerMon, expGain)
			end
			sendBattleUpdate(
				player,
				battle,
				"You used "
					.. chosenMove.name
					.. " and dealt "
					.. tostring(damage)
					.. " damage! The wild "
					.. enemyMon.displayName
					.. " fainted!"
			)
			endBattleForPlayer(player, "won")
			return
		end

		local enemyMove = chooseEnemyMove(enemyMon)
		local enemyDamage, enemyHit = performAttack(enemyMon, playerMon, enemyMove)

		if playerMon.hp <= 0 then
				battle.state = "lost"
			local data = playerData[player]
			if data then
				data.stats.battlesLost += 1
			end
			local msg = "You used "
				.. chosenMove.name
				.. " and dealt "
				.. tostring(damage)
				.. " damage! "
				.. enemyMon.displayName
				.. " used "
				.. enemyMove.name
				.. " and dealt "
				.. tostring(enemyDamage)
				.. " damage! Your brainrot fainted!"
			sendBattleUpdate(player, battle, msg)
			endBattleForPlayer(player, "lost")
			return
		end

		local msg = ""
		if hit then
			msg = msg
				.. "You used "
				.. chosenMove.name
				.. " and dealt "
				.. tostring(damage)
				.. " damage! "
		else
			msg = msg .. "Your attack missed! "
		end
		if enemyHit then
			msg = msg
				.. enemyMon.displayName
				.. " used "
				.. enemyMove.name
				.. " and dealt "
				.. tostring(enemyDamage)
				.. " damage!"
		else
			msg = msg .. enemyMon.displayName .. "'s attack missed!"
		end

		sendBattleUpdate(player, battle, msg)
	end
end

BattleRequest.OnServerEvent:Connect(handleBattleRequest)

local function createTrainerSnapshot(player: Player)
	local data = playerData[player]
	if not data then
		return nil
	end

	local snapshotParty = {}
	for i, mon in ipairs(data.party) do
		snapshotParty[i] = mon
	end

	local snapshotCollection = {}
	for i, mon in ipairs(data.collection) do
		local inParty = false
		local partyIndex: number? = nil
		for pIndex, pMon in ipairs(data.party) do
			if pMon == mon then
				inParty = true
				partyIndex = pIndex
				break
			end
		end

		snapshotCollection[i] = {
			id = mon.id,
			displayName = mon.displayName,
			level = mon.level,
			hp = mon.hp,
			maxHP = mon.maxHP,
			isInParty = inParty,
			partyIndex = partyIndex,
		}
	end

	local snapshotBag = {}
	for i, entry in ipairs(data.bag) do
		local itemDef = Items.getById(entry.id)
		snapshotBag[i] = {
			id = entry.id,
			displayName = entry.displayName,
			quantity = entry.quantity,
			holdable = itemDef and (itemDef.holdable == true) or false,
			usableInBattle = itemDef and (itemDef.usableInBattle == true) or false,
		}
	end

	return {
		trainerName = player.Name,
		stats = {
			totalCaught = data.stats.totalCaught,
			battlesWon = data.stats.battlesWon,
			battlesLost = data.stats.battlesLost,
			totalReleased = data.stats.totalReleased or 0,
		},
		party = snapshotParty,
		bag = snapshotBag,
		dexSeen = data.dexSeen,
		dexCaught = data.dexCaught,
		collection = snapshotCollection,
		leaderIndex = data.activeIndex,
	}
end

GetTrainerData.OnServerInvoke = function(player: Player)
	return createTrainerSnapshot(player)
end

local function getTouchingPlayer(hit: BasePart?)
	if not hit then
		return nil
	end
	local character = hit.Parent
	if not character then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	return player
end

local function spawnRandomItem()
	local baseplate = Workspace:FindFirstChild("Baseplate") :: Part?
	if not baseplate then
		return
	end

	local itemDef = Items.getRandom()
	if not itemDef then
		return
	end

	local size = baseplate.Size
	local cf = baseplate.CFrame

	local offsetX = (math.random() - 0.5) * (size.X - 10)
	local offsetZ = (math.random() - 0.5) * (size.Z - 10)

	local position = (cf * CFrame.new(offsetX, size.Y / 2 + 2, offsetZ)).Position

	local part = Instance.new("Part")
	part.Name = "Item_" .. itemDef.id
	part.Size = Vector3.new(2, 1, 2)
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	part.Color = Color3.fromRGB(255, 255, 0)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = Workspace

	part:SetAttribute("ItemId", itemDef.id)

	part.Touched:Connect(function(hit)
		local player = getTouchingPlayer(hit)
		if not player then
			return
		end

		local data = playerData[player]
		if not data then
			return
		end

		local itemId = part:GetAttribute("ItemId")
		if not itemId then
			return
		end

		addToBag(data, itemId)

		part:Destroy()
	end)
end

local function healTrainerBrainrots(player: Player)
	local data = playerData[player]
	if not data then
		return
	end

	local function healList(list)
		for _, mon in ipairs(list) do
			mon.hp = mon.maxHP
		end
	end

	healList(data.party)
	healList(data.collection)
end

local function setupBrainrotCenter()
	local center = Workspace:FindFirstChild("BrainrotCenter")
	if not center then
		return
	end

	local nurse = center:FindFirstChild("Nurse") :: BasePart?
	local healBox = center:FindFirstChild("HealBox") :: BasePart?
	if not nurse or not healBox then
		return
	end

	local prompt = nurse:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Nurse"
		prompt.ActionText = "Heal brainrots"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = nurse
	end

	local originalNurseCFrame = nurse.CFrame
	local originalBoxColor = healBox.Color

	prompt.Triggered:Connect(function(player: Player)
		local data = playerData[player]
		if not data then
			return
		end

		nurse.CFrame = CFrame.new(nurse.Position, healBox.Position)

		task.spawn(function()
			for _ = 1, 3 do
				healBox.Color = Color3.fromRGB(255, 255, 255)
				task.wait(0.15)
				healBox.Color = originalBoxColor
				task.wait(0.15)
			end
			nurse.CFrame = originalNurseCFrame
		end)

		healTrainerBrainrots(player)
		HealComplete:FireClient(player)
	end)
end

SetHeldItem.OnServerEvent:Connect(function(player: Player, partyIndex: number, itemId: string?)
	local data = playerData[player]
	if not data then
		return
	end

	local mon = data.party[partyIndex]
	if not mon then
		return
	end

	if not itemId or itemId == "" then
		mon.heldItemId = nil
		return
	end

	local itemDef = Items.getById(itemId)
	if not itemDef or not itemDef.holdable then
		return
	end

	mon.heldItemId = itemId
end)

SetLeader.OnServerEvent:Connect(function(player: Player, partyIndex: number)
	local data = playerData[player]
	if not data then
		return
	end

	local mon = data.party[partyIndex]
	if not mon or mon.hp <= 0 then
		return
	end

	data.activeIndex = partyIndex
end)

ReleaseBrainrot.OnServerEvent:Connect(function(player: Player, partyIndex: number)
	local data = playerData[player]
	if not data then
		return
	end

	if #data.party <= 1 then
		return
	end

	table.remove(data.party, partyIndex)

	if data.activeIndex == partyIndex then
		data.activeIndex = math.clamp(partyIndex, 1, #data.party)
	elseif data.activeIndex > partyIndex then
		data.activeIndex -= 1
	end
end)

MoveBrainrotBetweenPartyAndCollection.OnServerInvoke = function(player: Player, partyIndex: number?, collectionIndex: number?)
	local data = playerData[player]
	if not data then
		return false, "No trainer data."
	end

	if activeBattles[player] then
		return false, "You can't manage brainrots during a battle."
	end

	if partyIndex and collectionIndex then
		local partyMon = data.party[partyIndex]
		local collectionMon = data.collection[collectionIndex]
		if not partyMon or not collectionMon then
			return false, "Invalid indices."
		end

		data.party[partyIndex], data.collection[collectionIndex] = collectionMon, partyMon
		return true
	elseif partyIndex then
		if #data.party <= 1 then
			return false, "You must keep at least one brainrot in your party."
		end

		local mon = data.party[partyIndex]
		if not mon then
			return false, "Invalid party index."
		end

		if #data.collection >= COLLECTION_CAP then
			return false, "Your collection is full."
		end

		table.insert(data.collection, mon)
		table.remove(data.party, partyIndex)

		if data.activeIndex == partyIndex then
			data.activeIndex = math.clamp(partyIndex, 1, #data.party)
		elseif data.activeIndex > partyIndex then
			data.activeIndex -= 1
		end

		return true
	elseif collectionIndex then
		if #data.party >= MAX_PARTY_SIZE then
			return false, "Your party is full."
		end

		local mon = data.collection[collectionIndex]
		if not mon then
			return false, "Invalid collection index."
		end

		table.insert(data.party, mon)
		table.remove(data.collection, collectionIndex)

		if #data.party == 1 then
			data.activeIndex = 1
		end

		return true
	end

	return false, "No indices provided."
end

ReleaseFromCollection.OnServerInvoke = function(player: Player, collectionIndex: number)
	local data = playerData[player]
	if not data then
		return false, "No trainer data."
	end

	if activeBattles[player] then
		return false, "You can't release brainrots during a battle."
	end

	local mon = data.collection[collectionIndex]
	if not mon then
		return false, "Invalid collection index."
	end

	for _, partyMon in ipairs(data.party) do
		if partyMon == mon then
			return false, "You can't release a brainrot that is in your party."
		end
	end

	table.remove(data.collection, collectionIndex)

	data.stats.totalReleased = (data.stats.totalReleased or 0) + 1

	return true
end

Players.PlayerAdded:Connect(function(player)
	local starter = Brainrots.createInstance("chimpanzini_bananini", 1)
	local data = {
		collection = { starter },
		party = { starter },
		activeIndex = 1,
		bag = {},
		stats = {
			totalCaught = 0,
			battlesWon = 0,
			battlesLost = 0,
			totalReleased = 0,
		},
		dexSeen = {},
		dexCaught = {},
	}
	playerData[player] = data
end)

Players.PlayerRemoving:Connect(function(player)
	activeBattles[player] = nil
	playerData[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(15)
		spawnRandomItem()
	end
end)

local function handleGrassTouched(hit: BasePart)
	local player = getTouchingPlayer(hit)
	if not player then
		return
	end

	if activeBattles[player] then
		return
	end

	if math.random() < 0.5 then
		startWildEncounter(player)
	end
end

local function spawnGrassClusters()
	local baseplate = Workspace:FindFirstChild("Baseplate") :: Part?
	if not baseplate then
		return
	end

	local size = baseplate.Size
	local cf = baseplate.CFrame

	local townModel = Workspace:FindFirstChild("StarterTown")
	local townCFrame, townSize
	if townModel and townModel:IsA("Model") then
		townCFrame, townSize = townModel:GetBoundingBox()
	end

	local brainrotCenterModel = Workspace:FindFirstChild("BrainrotCenter")
	local brainrotCenterPos: Vector3? = nil
	if brainrotCenterModel then
		if brainrotCenterModel:IsA("Model") then
			local cframe = nil
			if (brainrotCenterModel :: Model).PrimaryPart then
				cframe = (brainrotCenterModel :: Model).PrimaryPart.CFrame
			else
				cframe = select(1, (brainrotCenterModel :: Model):GetBoundingBox())
			end
			brainrotCenterPos = cframe.Position
		elseif brainrotCenterModel:IsA("BasePart") then
			brainrotCenterPos = (brainrotCenterModel :: BasePart).Position
		end
	end

	local brainrotNoGrassRadius = 50
	local townPadding = 6

	for _ = 1, 16 do
		local center: Vector3? = nil
		for _ = 1, 30 do
			local offsetX = (math.random() - 0.5) * (size.X - 40)
			local offsetZ = (math.random() - 0.5) * (size.Z - 40)

			local candidate = (cf * CFrame.new(offsetX, size.Y / 2 + 2.5, offsetZ)).Position

			local insideTown = false
			if townCFrame and townSize then
				local localPos = townCFrame:PointToObjectSpace(candidate)
				if math.abs(localPos.X) <= townSize.X / 2 + townPadding and math.abs(localPos.Z) <= townSize.Z / 2 + townPadding then
					insideTown = true
				end
			else
				if math.abs(candidate.X) <= TOWN_HALF_X and math.abs(candidate.Z) <= TOWN_HALF_Z then
					insideTown = true
				end
			end

			if insideTown then
				continue
			end

			if brainrotCenterPos then
				local dx = candidate.X - brainrotCenterPos.X
				local dz = candidate.Z - brainrotCenterPos.Z
				if math.sqrt(dx * dx + dz * dz) < brainrotNoGrassRadius then
					continue
				end
			end

			center = candidate
			break
		end

		if center then
			local patch = Instance.new("Part")
			patch.Name = "TallGrass"
			patch.Size = Vector3.new(18, 5, 18)
			patch.Anchored = true
			patch.CanCollide = false
			patch.Position = center
			patch.Material = Enum.Material.Grass
			patch.Color = Color3.fromRGB(50, 160, 60)
			patch.TopSurface = Enum.SurfaceType.Smooth
			patch.BottomSurface = Enum.SurfaceType.Smooth
			patch.Parent = Workspace

			patch.Touched:Connect(handleGrassTouched)
		end
	end
end

task.spawn(function()
	task.wait(2)
	spawnGrassClusters()
end)

task.spawn(function()
	task.wait(2)
	setupBrainrotCenter()
end)

