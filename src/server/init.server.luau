local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local TrainerDataStore = DataStoreService:GetDataStore("TrainerData_v1")

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

local BattleInviteRemote = RemotesFolder:FindFirstChild("BattleInvite") :: RemoteEvent?
if not BattleInviteRemote then
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = "BattleInvite"
	newEvent.Parent = RemotesFolder
	BattleInviteRemote = newEvent
end
local BattleInvite = BattleInviteRemote :: RemoteEvent

local BattleInviteResponseRemote = RemotesFolder:FindFirstChild("BattleInviteResponse") :: RemoteEvent?
if not BattleInviteResponseRemote then
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = "BattleInviteResponse"
	newEvent.Parent = RemotesFolder
	BattleInviteResponseRemote = newEvent
end
local BattleInviteResponse = BattleInviteResponseRemote :: RemoteEvent

local SetSettingsRemote = RemotesFolder:FindFirstChild("SetSettings") :: RemoteEvent?
if not SetSettingsRemote then
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = "SetSettings"
	newEvent.Parent = RemotesFolder
	SetSettingsRemote = newEvent
end
local SetSettings = SetSettingsRemote :: RemoteEvent

local UseItemOutsideBattleRemote = RemotesFolder:FindFirstChild("UseItemOutsideBattle") :: RemoteFunction?
if not UseItemOutsideBattleRemote then
	local newFn = Instance.new("RemoteFunction")
	newFn.Name = "UseItemOutsideBattle"
	newFn.Parent = RemotesFolder
	UseItemOutsideBattleRemote = newFn
end
local UseItemOutsideBattle = UseItemOutsideBattleRemote :: RemoteFunction

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
	statusEffect: string?,
	statusTurns: number?,
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
	settings: { musicEnabled: boolean?, sfxEnabled: boolean?, cameraSensitivity: number? }?,
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

local function calculateExpGain(playerMon: BrainrotInstance, enemyMon: BrainrotInstance): number
	local baseExp = math.max(5, enemyMon.level * 10)
	local levelDiff = enemyMon.level - (playerMon.level or 1)
	if levelDiff > 0 then
		baseExp = math.floor(baseExp * (1 + levelDiff * 0.15))
	elseif levelDiff < 0 then
		baseExp = math.floor(baseExp * math.max(0.5, 1 + levelDiff * 0.1))
	end
	if (playerMon :: any).heldItemId == "brainrot_treat" then
		baseExp = math.floor(baseExp * 1.5)
	end
	return baseExp
end

local function grantExpAndNotifyLevelUp(player: Player, playerMon: BrainrotInstance, expGain: number)
	if expGain <= 0 then
		return
	end
	local levelsGained = Brainrots.gainExperience(playerMon, expGain)
	if levelsGained > 0 then
		sendBattleAnimation(player, "levelUp", {
			brainrotId = playerMon.id,
			displayName = playerMon.displayName,
			newLevel = playerMon.level,
		})
	end
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

local STATUS_POISON = "poison"
local STATUS_BURN = "burn"
local STATUS_PARALYZE = "paralyze"
local STATUS_SLEEP = "sleep"

local function clearStatus(mon: BrainrotInstance)
	(mon :: any).statusEffect = nil
	(mon :: any).statusTurns = nil
end

local function tryApplyStatus(defender: BrainrotInstance, move: any)
	if not move or not defender or defender.hp <= 0 then
		return
	end
	local statusEffect = (move :: any).statusEffect
	local statusChance = (move :: any).statusChance or 1
	if not statusEffect or (defender :: any).statusEffect then
		return
	end
	if math.random() > statusChance then
		return
	end
	(defender :: any).statusEffect = statusEffect
	if statusEffect == STATUS_SLEEP then
		(defender :: any).statusTurns = math.random(2, 4)
	end
end

local function processEndOfTurnStatus(player: Player, battle: BattleState): string?
	local playerMon = battle.playerBrainrot
	local enemyMon = battle.enemyBrainrot
	local msg = ""

	for _, mon in ipairs({ playerMon, enemyMon }) do
		if mon.hp > 0 then
			local status = (mon :: any).statusEffect
			if status == STATUS_POISON or status == STATUS_BURN then
				local damage = math.max(1, math.floor(mon.maxHP / 8))
				mon.hp = math.max(mon.hp - damage, 0)
				local name = mon == playerMon and ("Your " .. mon.displayName) or mon.displayName
				msg = msg .. name .. " took " .. tostring(damage) .. " damage from " .. status .. "! "
			end
		end
	end

	if msg ~= "" then
		return msg
	end
	return nil
end

local function checkStatusSkipTurn(mon: BrainrotInstance): (boolean, string?)
	local status = (mon :: any).statusEffect
	if status == STATUS_PARALYZE then
		if math.random() < 0.25 then
			return true, "It's paralyzed! It couldn't move!"
		end
	elseif status == STATUS_SLEEP then
		local turns = (mon :: any).statusTurns or 0
		if turns > 0 then
			(mon :: any).statusTurns = turns - 1
			return true, "It's fast asleep!"
		else
			clearStatus(mon)
			return false, nil
		end
	end
	return false, nil
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

local function computeAttackResult(attacker: BrainrotInstance, defender: BrainrotInstance, move)
	if not move then
		return 0, false
	end
	local hitChance = move.accuracy or 1
	if math.random() > hitChance then
		return 0, false
	end
	local damage = Brainrots.calculateDamage(attacker, defender, move)
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
	local data = playerData[player]
	if data and data.party then
		for _, mon in ipairs(data.party) do
			clearStatus(mon :: BrainrotInstance)
		end
	end
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
		local playerSpeed = playerMon.speed or 5
		local enemySpeed = enemyMon.speed or 5
		local runChance = 0.6 + (playerSpeed - enemySpeed) * 0.05
		runChance = math.clamp(runChance, 0.3, 0.95)
		if math.random() < runChance then
			endBattleForPlayer(player, "finished")
			sendBattleUpdate(player, battle, "You ran away!")
		else
			sendBattleUpdate(player, battle, "Couldn't escape! " .. enemyMon.displayName .. " blocks your path!")
			enemyRespond(player, battle, playerMon, enemyMon)
		end
		return
	end

	if action == "switch" and moveId then
		local data = playerData[player]
		if not data then
			return
		end

		local party = data.party or {}
		local index = tonumber(moveId)
		if not index or index < 1 or index > #party then
			return
		end

		local newMon = party[index]
		if newMon.hp <= 0 then
			sendBattleUpdate(player, battle, "You can't switch to a fainted brainrot!")
			return
		end

		if newMon == playerMon then
			sendBattleUpdate(player, battle, newMon.displayName .. " is already in battle!")
			return
		end

		battle.playerBrainrot = newMon
		data.activeIndex = index
		sendBattleUpdate(player, battle, "You switched to " .. newMon.displayName .. "!")
		enemyRespond(player, battle, newMon, enemyMon)
		return
	end

	if action == "capture" then
		local data = playerData[player]
		if not data then
			return
		end

		local ballId = (type(moveId) == "string" and (moveId == "troppi_ball" or moveId == "super_ball" or moveId == "ultra_ball")) and moveId or "troppi_ball"
		local ballEntry = getBagItem(data, ballId)
		if not ballEntry or ballEntry.quantity <= 0 then
			ballEntry = getBagItem(data, "troppi_ball")
			ballId = "troppi_ball"
		end
		if not ballEntry or ballEntry.quantity <= 0 then
			sendBattleUpdate(player, battle, "You don't have any capture balls!")
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
		local ballDef = Items.getById(ballId)
		if ballDef and ballDef.effect and ballDef.effect.captureRate then
			captureChance = captureChance * ballDef.effect.captureRate
		end
		if (playerMon :: any).heldItemId == "capture_chip" then
			captureChance = math.min(0.95, captureChance + 0.15)
		end
		captureChance = math.clamp(captureChance, 0.05, 0.95)

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
					grantExpAndNotifyLevelUp(player, playerMon, calculateExpGain(playerMon, enemyMon))
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
				clearStatus(playerMon)
				sendBattleUpdate(
					player,
					battle,
					"You poured Henny on "
						.. playerMon.displayName
						.. "! It revived with half HP."
				)
			end
		elseif itemId == "potion" or itemId == "super_potion" or itemId == "hyper_potion" or itemId == "full_restore" then
			local effect = itemDef.effect
			local healAmount = effect and effect.heal or 20
			if playerMon.hp <= 0 then
				sendBattleUpdate(player, battle, "You can't use that on a fainted brainrot!")
			else
				local oldHp = playerMon.hp
				playerMon.hp = math.min(playerMon.hp + healAmount, playerMon.maxHP)
				local healed = playerMon.hp - oldHp
				if effect and effect.clearStatus then
					clearStatus(playerMon)
				end
				sendBattleUpdate(player, battle, "You used " .. itemDef.displayName .. "! " .. playerMon.displayName .. " recovered " .. tostring(healed) .. " HP!")
			end
		elseif itemId == "attack_boost" or itemId == "defense_boost" then
			local effect = itemDef.effect
			local stat = effect and effect.statBoost or "attack"
			if stat == "attack" then
				(playerMon :: any).attackBoostTurns = ((playerMon :: any).attackBoostTurns or 0) + (effect and effect.turns or 3)
				playerMon.attack = playerMon.attack + 2
			else
				(playerMon :: any).defenseBoostTurns = ((playerMon :: any).defenseBoostTurns or 0) + (effect and effect.turns or 3)
				playerMon.defense = playerMon.defense + 2
			end
			sendBattleUpdate(player, battle, "You used " .. itemDef.displayName .. "! " .. playerMon.displayName .. "'s " .. stat .. " rose!")
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

		local playerSkip, playerSkipMsg = checkStatusSkipTurn(playerMon)
		local enemyMove = chooseEnemyMove(enemyMon)
		local enemySkip, enemySkipMsg = checkStatusSkipTurn(enemyMon)

		local playerDamage, playerHit = 0, false
		if not playerSkip then
			playerDamage, playerHit = computeAttackResult(playerMon, enemyMon, chosenMove)
		end
		local enemyDamage, enemyHit = 0, false
		if not enemySkip then
			enemyDamage, enemyHit = computeAttackResult(enemyMon, playerMon, enemyMove)
		end

		local playerSpeed = playerMon.speed or 5
		local enemySpeed = enemyMon.speed or 5
		local playerFirst = playerSpeed >= enemySpeed

		local function applyDamage(target, amount)
			target.hp = math.max(target.hp - amount, 0)
		end

		local msg = ""
		if playerFirst then
			if playerSkip then
				msg = msg .. (playerSkipMsg or "Your brainrot couldn't move! ") .. " "
			elseif playerHit then
				applyDamage(enemyMon, playerDamage)
				msg = msg .. "You used " .. chosenMove.name .. " and dealt " .. tostring(playerDamage) .. " damage! "
				tryApplyStatus(enemyMon, chosenMove)
			else
				msg = msg .. "Your attack missed! "
			end
			if enemyMon.hp <= 0 then
				battle.state = "won"
				local data = playerData[player]
				if data then
					data.stats.battlesWon += 1
					markDexCaught(data, enemyMon.id)
					grantExpAndNotifyLevelUp(player, playerMon, calculateExpGain(playerMon, enemyMon))
				end
				sendBattleUpdate(player, battle, msg .. "The wild " .. enemyMon.displayName .. " fainted!")
				endBattleForPlayer(player, "won")
				return
			end
			if enemySkip then
				msg = msg .. (enemySkipMsg or (enemyMon.displayName .. " couldn't move! ")) .. " "
			elseif enemyHit then
				applyDamage(playerMon, enemyDamage)
				msg = msg .. enemyMon.displayName .. " used " .. (enemyMove and enemyMove.name or "an attack") .. " and dealt " .. tostring(enemyDamage) .. " damage! "
				tryApplyStatus(playerMon, enemyMove)
			else
				msg = msg .. enemyMon.displayName .. "'s attack missed!"
			end
			if playerMon.hp <= 0 then
				battle.state = "lost"
				local data = playerData[player]
				if data then
					data.stats.battlesLost += 1
				end
				sendBattleUpdate(player, battle, msg .. " Your brainrot fainted!")
				endBattleForPlayer(player, "lost")
				return
			end
		else
			if enemySkip then
				msg = msg .. (enemySkipMsg or (enemyMon.displayName .. " couldn't move! ")) .. " "
			elseif enemyHit then
				applyDamage(playerMon, enemyDamage)
				msg = msg .. enemyMon.displayName .. " used " .. (enemyMove and enemyMove.name or "an attack") .. " and dealt " .. tostring(enemyDamage) .. " damage! "
				tryApplyStatus(playerMon, enemyMove)
			else
				msg = msg .. enemyMon.displayName .. "'s attack missed! "
			end
			if playerMon.hp <= 0 then
				battle.state = "lost"
				local data = playerData[player]
				if data then
					data.stats.battlesLost += 1
				end
				sendBattleUpdate(player, battle, msg .. " Your brainrot fainted!")
				endBattleForPlayer(player, "lost")
				return
			end
			if playerSkip then
				msg = msg .. (playerSkipMsg or "Your brainrot couldn't move! ") .. " "
			elseif playerHit then
				applyDamage(enemyMon, playerDamage)
				msg = msg .. "You used " .. chosenMove.name .. " and dealt " .. tostring(playerDamage) .. " damage! "
				tryApplyStatus(enemyMon, chosenMove)
			else
				msg = msg .. "Your attack missed! "
			end
			if enemyMon.hp <= 0 then
				battle.state = "won"
				local data = playerData[player]
				if data then
					data.stats.battlesWon += 1
					markDexCaught(data, enemyMon.id)
					grantExpAndNotifyLevelUp(player, playerMon, calculateExpGain(playerMon, enemyMon))
				end
				sendBattleUpdate(player, battle, msg .. " The wild " .. enemyMon.displayName .. " fainted!")
				endBattleForPlayer(player, "won")
				return
			end
		end

		local statusMsg = processEndOfTurnStatus(player, battle)
		if statusMsg then
			msg = msg .. statusMsg
		end
		if playerMon.hp <= 0 then
			battle.state = "lost"
			local data = playerData[player]
			if data then
				data.stats.battlesLost += 1
			end
			sendBattleUpdate(player, battle, msg .. " Your brainrot fainted!")
			endBattleForPlayer(player, "lost")
			return
		end
		if enemyMon.hp <= 0 then
			battle.state = "won"
			local data = playerData[player]
			if data then
				data.stats.battlesWon += 1
				markDexCaught(data, enemyMon.id)
				grantExpAndNotifyLevelUp(player, playerMon, calculateExpGain(playerMon, enemyMon))
			end
			sendBattleUpdate(player, battle, msg .. " The wild " .. enemyMon.displayName .. " fainted!")
			endBattleForPlayer(player, "won")
			return
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
		settings = data.settings or { musicEnabled = true, sfxEnabled = true, cameraSensitivity = 1 },
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

	local pcModel = center:FindFirstChild("PC")
	if pcModel then
		local pcPart: BasePart? = nil
		if pcModel:IsA("BasePart") then
			pcPart = pcModel :: BasePart
		elseif pcModel:IsA("Model") then
			pcPart = (pcModel :: Model):FindFirstChildWhichIsA("BasePart")
		end

		if pcPart then
			local pcPrompt = pcPart:FindFirstChildOfClass("ProximityPrompt")
			if not pcPrompt then
				pcPrompt = Instance.new("ProximityPrompt")
				pcPrompt.ObjectText = "PC"
				pcPrompt.ActionText = "Open PC"
				pcPrompt.RequiresLineOfSight = false
				pcPrompt.MaxActivationDistance = 10
				pcPrompt.Parent = pcPart
			end

			pcPrompt.Triggered:Connect(function(player: Player)
				if playerData[player] then
					OpenPC:FireClient(player)
				end
			end)
		end
	end
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

BattleInvite.OnServerEvent:Connect(function(player: Player, targetUserId: number)
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then
		BattleInviteResponse:FireClient(player, false, "Invalid or offline player.")
		return
	end
	if activeBattles[player] or activeBattles[target] then
		BattleInviteResponse:FireClient(player, false, "One of you is already in a battle.")
		return
	end
	BattleInviteResponse:FireClient(target, true, player.Name .. " invited you to a battle!")
	BattleInviteResponse:FireClient(player, true, "Invite sent to " .. target.Name .. ".")
end)

SetSettings.OnServerEvent:Connect(function(player: Player, musicEnabled: boolean?, sfxEnabled: boolean?, cameraSensitivity: number?)
	local data = playerData[player]
	if not data then
		return
	end
	data.settings = data.settings or {}
	if musicEnabled ~= nil then
		data.settings.musicEnabled = musicEnabled
	end
	if sfxEnabled ~= nil then
		data.settings.sfxEnabled = sfxEnabled
	end
	if cameraSensitivity ~= nil then
		data.settings.cameraSensitivity = cameraSensitivity
	end
end)

UseItemOutsideBattle.OnServerInvoke = function(player: Player, itemId: string, partyIndex: number?): (boolean, string)
	if activeBattles[player] then
		return false, "You can't use items during a battle."
	end

	local data = playerData[player]
	if not data then
		return false, "No trainer data."
	end

	local entry = getBagItem(data, itemId)
	local itemDef = Items.getById(itemId)
	if not entry or not itemDef then
		return false, "You don't have that item."
	end

	local effect = itemDef.effect
	local hasHeal = effect and effect.heal
	local hasRevive = effect and effect.revive
	if not hasHeal and not hasRevive then
		return false, "That item can't be used outside of battle."
	end

	partyIndex = partyIndex or 1
	local mon = data.party[partyIndex]
	if not mon then
		return false, "Invalid party slot."
	end

	if hasRevive then
		if mon.hp > 0 then
			return false, mon.displayName .. " is already conscious."
		end
		mon.hp = math.max(1, math.floor(mon.maxHP * (effect.revive or 0.5)))
		clearStatus(mon :: BrainrotInstance)
	else
		if mon.hp <= 0 then
			return false, "You can't use that on a fainted brainrot. Try Henny!"
		end
		local healAmount = effect.heal or 20
		local oldHp = mon.hp
		mon.hp = math.min(mon.hp + healAmount, mon.maxHP)
		if effect.clearStatus then
			clearStatus(mon :: BrainrotInstance)
		end
		if mon.hp == oldHp then
			return false, mon.displayName .. " is already at full HP."
		end
	end

	entry.quantity -= 1
	if entry.quantity <= 0 then
		for i, e in ipairs(data.bag) do
			if e == entry then
				table.remove(data.bag, i)
				break
			end
		end
	end

	if hasRevive then
		return true, "You revived " .. mon.displayName .. " with " .. itemDef.displayName .. "!"
	end
	return true, "You used " .. itemDef.displayName .. " on " .. mon.displayName .. "!"
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

local SCHEMA_VERSION = 2

local function serializeTrainerData(data: TrainerData): string
	return HttpService:JSONEncode({
		schemaVersion = SCHEMA_VERSION,
		party = data.party,
		collection = data.collection,
		activeIndex = data.activeIndex,
		bag = data.bag,
		stats = data.stats,
		dexSeen = data.dexSeen,
		dexCaught = data.dexCaught,
		settings = data.settings or {},
	})
end

-- data-6: statusEffect/statusTurns persist via serialized party/collection (no extra handling needed)
-- data-7: Migrate expanded brainrot definitions (type, moves from content-1)
local function migrateBrainrot(mon: any): any
	if not mon or type(mon) ~= "table" then
		return mon
	end

	-- data-7: Migration for expanded brainrot definitions (type, moves from content-1)
	local base = Brainrots.getById(mon.id)
	if base then
		if not mon.type or mon.type == "" then
			mon.type = base.type or "Neutral"
		end
		if not mon.moves or #mon.moves == 0 then
			mon.moves = {}
			for _, m in ipairs(base.moves or {}) do
				table.insert(mon.moves, {
					id = m.id,
					name = m.name,
					power = m.power,
					accuracy = m.accuracy,
					type = m.type or "Neutral",
					statusEffect = m.statusEffect,
					statusChance = m.statusChance,
				})
			end
		end
	end
	return mon
end

local function migrateTrainerData(decoded: any): TrainerData?
	local version = decoded.schemaVersion or 0
	if version < 1 then
		decoded.stats = decoded.stats or {}
		decoded.stats.totalReleased = decoded.stats.totalReleased or 0
	end

	-- data-6 & data-7: Migrate each brainrot in party and collection
	local party = decoded.party or {}
	local collection = decoded.collection or {}
	for _, mon in ipairs(party) do
		migrateBrainrot(mon)
	end
	for _, mon in ipairs(collection) do
		migrateBrainrot(mon)
	end

	return {
		party = party,
		collection = collection,
		activeIndex = decoded.activeIndex or 1,
		bag = decoded.bag or {},
		stats = decoded.stats or {
			totalCaught = 0,
			battlesWon = 0,
			battlesLost = 0,
			totalReleased = 0,
		},
		dexSeen = decoded.dexSeen or {},
		dexCaught = decoded.dexCaught or {},
		settings = decoded.settings and type(decoded.settings) == "table" and {
			musicEnabled = decoded.settings.musicEnabled ~= false,
			sfxEnabled = decoded.settings.sfxEnabled ~= false,
			cameraSensitivity = decoded.settings.cameraSensitivity or 1,
		} or { musicEnabled = true, sfxEnabled = true, cameraSensitivity = 1 },
	}
end

local function deserializeTrainerData(json: string): TrainerData?
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or not decoded then
		return nil
	end
	return migrateTrainerData(decoded)
end

local function savePlayerData(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	local key = "Player_" .. player.UserId
	local ok, err = pcall(function()
		TrainerDataStore:SetAsync(key, serializeTrainerData(data))
	end)
	if not ok then
		warn("[TrainerData] Failed to save for", player.Name, err)
	end
end

local function loadPlayerData(player: Player): TrainerData?
	local key = "Player_" .. player.UserId
	local ok, result = pcall(function()
		return TrainerDataStore:GetAsync(key)
	end)
	if not ok or not result then
		return nil
	end
	return deserializeTrainerData(result)
end

Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)
	if not data or #data.party == 0 then
		local starter = Brainrots.createInstance("chimpanzini_bananini", 1)
		data = {
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
			settings = { musicEnabled = true, sfxEnabled = true, cameraSensitivity = 1 },
		}
		-- data-8: Give new players 5 Troppi balls and 5 Henny
		for _ = 1, 5 do
			addToBag(data, "troppi_ball")
		end
		for _ = 1, 5 do
			addToBag(data, "henny")
		end
	end
	if not data.settings then
		data.settings = { musicEnabled = true, sfxEnabled = true, cameraSensitivity = 1 }
	end
	playerData[player] = data
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	activeBattles[player] = nil
	playerData[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(300)
		for _, player in ipairs(Players:GetPlayers()) do
			if playerData[player] then
				savePlayerData(player)
			end
		end
	end
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

