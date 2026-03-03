local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots: { [string]: any } = {}

-- Type effectiveness: attacker type -> defender type -> multiplier
local TYPE_EFFECTIVENESS: { [string]: { [string]: number } } = {
	Fire = { Grass = 1.5, Water = 0.5, Fire = 0.5 },
	Water = { Fire = 1.5, Grass = 0.5, Water = 0.5 },
	Grass = { Water = 1.5, Fire = 0.5, Grass = 0.5 },
	Electric = { Water = 1.5, Grass = 0.5, Electric = 0.5 },
	Poison = { Grass = 1.5, Poison = 0.5 },
	Chaos = { Meme = 1.5, Sigma = 0.5 },
	Meme = { Sigma = 1.5, Chaos = 0.5 },
	Sigma = { Chaos = 1.5, Meme = 0.5 },
}
local TYPES = { "Fire", "Water", "Grass", "Electric", "Poison", "Chaos", "Meme", "Sigma", "Neutral" }

-- Move pool: 2-4 per brainrot, varied power/accuracy/status/type
local MOVE_POOL = {
	{ id = "slam", name = "Slam", power = 8, accuracy = 0.95, type = "Neutral" },
	{ id = "tackle", name = "Tackle", power = 5, accuracy = 1.0, type = "Neutral" },
	{ id = "scratch", name = "Scratch", power = 6, accuracy = 1.0, type = "Neutral" },
	{ id = "bite", name = "Bite", power = 10, accuracy = 0.9, type = "Neutral" },
	{ id = "headbutt", name = "Headbutt", power = 12, accuracy = 0.85, type = "Neutral" },
	{ id = "tackle", name = "Tackle", power = 5, accuracy = 1.0, type = "Neutral" },
	{ id = "sting", name = "Sting", power = 7, accuracy = 0.95, statusEffect = "poison", statusChance = 0.15, type = "Poison" },
	{ id = "flame", name = "Flame", power = 8, accuracy = 0.9, statusEffect = "burn", statusChance = 0.1, type = "Fire" },
	{ id = "zap", name = "Zap", power = 9, accuracy = 0.95, statusEffect = "paralyze", statusChance = 0.1, type = "Electric" },
	{ id = "yawn", name = "Yawn", power = 3, accuracy = 0.85, statusEffect = "sleep", statusChance = 0.3, type = "Neutral" },
	{ id = "punch", name = "Punch", power = 11, accuracy = 0.9, type = "Neutral" },
	{ id = "kick", name = "Kick", power = 13, accuracy = 0.8, type = "Neutral" },
	{ id = "tackle", name = "Tackle", power = 5, accuracy = 1.0, type = "Neutral" },
	{ id = "slam", name = "Slam", power = 8, accuracy = 0.95, type = "Neutral" },
	{ id = "charge", name = "Charge", power = 10, accuracy = 0.9, type = "Electric" },
	{ id = "rush", name = "Rush", power = 12, accuracy = 0.85, type = "Neutral" },
	{ id = "peck", name = "Peck", power = 9, accuracy = 0.95, type = "Neutral" },
	{ id = "splash", name = "Splash", power = 4, accuracy = 1.0, type = "Water" },
	{ id = "bubble", name = "Bubble", power = 7, accuracy = 0.95, type = "Water" },
	{ id = "vine", name = "Vine Whip", power = 8, accuracy = 0.9, type = "Grass" },
	{ id = "scratch", name = "Scratch", power = 6, accuracy = 1.0 },
	{ id = "bite", name = "Bite", power = 10, accuracy = 0.9 },
	{ id = "headbutt", name = "Headbutt", power = 12, accuracy = 0.85 },
	{ id = "sting", name = "Sting", power = 7, accuracy = 0.95, statusEffect = "poison", statusChance = 0.15 },
	{ id = "flame", name = "Flame", power = 8, accuracy = 0.9, statusEffect = "burn", statusChance = 0.1 },
	{ id = "zap", name = "Zap", power = 9, accuracy = 0.95, statusEffect = "paralyze", statusChance = 0.1 },
	{ id = "yawn", name = "Yawn", power = 3, accuracy = 0.85, statusEffect = "sleep", statusChance = 0.3 },
	{ id = "punch", name = "Punch", power = 11, accuracy = 0.9 },
	{ id = "kick", name = "Kick", power = 13, accuracy = 0.8 },
	{ id = "charge", name = "Charge", power = 10, accuracy = 0.9 },
	{ id = "rush", name = "Rush", power = 12, accuracy = 0.85 },
	{ id = "peck", name = "Peck", power = 9, accuracy = 0.95 },
	{ id = "bubble", name = "Bubble", power = 7, accuracy = 0.95 },
	{ id = "vine", name = "Vine Whip", power = 8, accuracy = 0.9 },
	{ id = "scratch", name = "Scratch", power = 6, accuracy = 1.0 },
	{ id = "bite", name = "Bite", power = 10, accuracy = 0.9 },
	{ id = "headbutt", name = "Headbutt", power = 12, accuracy = 0.85 },
	{ id = "sting", name = "Sting", power = 7, accuracy = 0.95, statusEffect = "poison", statusChance = 0.15 },
	{ id = "flame", name = "Flame", power = 8, accuracy = 0.9, statusEffect = "burn", statusChance = 0.1 },
	{ id = "zap", name = "Zap", power = 9, accuracy = 0.95, statusEffect = "paralyze", statusChance = 0.1 },
	{ id = "yawn", name = "Yawn", power = 3, accuracy = 0.85, statusEffect = "sleep", statusChance = 0.3 },
	{ id = "punch", name = "Punch", power = 11, accuracy = 0.9 },
	{ id = "kick", name = "Kick", power = 13, accuracy = 0.8 },
	{ id = "charge", name = "Charge", power = 10, accuracy = 0.9 },
	{ id = "rush", name = "Rush", power = 12, accuracy = 0.85 },
	{ id = "peck", name = "Peck", power = 9, accuracy = 0.95 },
	{ id = "bubble", name = "Bubble", power = 7, accuracy = 0.95 },
	{ id = "vine", name = "Vine Whip", power = 8, accuracy = 0.9 },
}

-- Stat profiles: varied base stats
local STAT_PROFILES = {
	{ maxHP = 28, attack = 10, defense = 6, speed = 10 },
	{ maxHP = 32, attack = 6, defense = 12, speed = 6 },
	{ maxHP = 30, attack = 8, defense = 8, speed = 8 },
	{ maxHP = 26, attack = 12, defense = 6, speed = 10 },
	{ maxHP = 34, attack = 6, defense = 10, speed = 6 },
	{ maxHP = 28, attack = 8, defense = 8, speed = 10 },
	{ maxHP = 30, attack = 10, defense = 6, speed = 8 },
	{ maxHP = 32, attack = 7, defense = 9, speed = 6 },
	{ maxHP = 26, attack = 9, defense = 7, speed = 12 },
	{ maxHP = 32, attack = 8, defense = 8, speed = 6 },
}

-- Description templates
local DESC_TEMPLATES = {
	"A curious brainrot. %s is known for its unique charm.",
	"A spirited brainrot. %s loves to show off.",
	"An energetic brainrot. %s never sits still.",
	"A mysterious brainrot. %s keeps its secrets close.",
	"A friendly brainrot. %s makes friends easily.",
	"A playful brainrot. %s enjoys a good time.",
	"A determined brainrot. %s never gives up.",
	"A clever brainrot. %s thinks outside the box.",
	"A calm brainrot. %s takes things in stride.",
	"A bold brainrot. %s is not afraid to act.",
}

local function hashString(s: string): number
	local h = 0
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % 2147483647
	end
	return math.abs(h)
end

local function applyContentToBrainrot(id: string, data: any)
	local h = hashString(id)
	local statIdx = (h % #STAT_PROFILES) + 1
	local descIdx = ((h // 31) % #DESC_TEMPLATES) + 1
	local moveCount = 2 + (h % 3) -- 2, 3, or 4 moves

	data.baseStats = STAT_PROFILES[statIdx]
	data.description = string.format(DESC_TEMPLATES[descIdx], data.displayName)
	data.type = TYPES[(h % #TYPES) + 1]

	local usedIdx = {}
	local moves = {}
	local poolLen = #MOVE_POOL
	for i = 1, moveCount do
		local attempts = 0
		local idx
		repeat
			idx = ((h + i * 17 + attempts * 13) % poolLen) + 1
			attempts = attempts + 1
		until not usedIdx[idx] or attempts > poolLen
		usedIdx[idx] = true
		local move = MOVE_POOL[idx]
		table.insert(moves, {
			id = move.id .. "_" .. tostring(i),
			name = move.name,
			power = move.power,
			accuracy = move.accuracy,
			statusEffect = move.statusEffect,
			statusChance = move.statusChance,
			type = move.type or "Neutral",
		})
	end
	data.moves = moves
end

local function initFromModels()
	local modelsFolder = ReplicatedStorage:FindFirstChild("BrainrotList") or ReplicatedStorage:FindFirstChild("BrainrotModels")
	if not modelsFolder then
		return
	end

	for _, model in ipairs(modelsFolder:GetChildren()) do
		if model:IsA("Model") then
			local rawName = model.Name
			local id = rawName:lower()
			id = id:gsub("%s+", "_")
			id = id:gsub("[^%w_]", "")

			if id ~= "" and not Brainrots[id] then
				Brainrots[id] = {
					id = id,
					displayName = rawName,
					description = "TODO: describe " .. rawName,
					modelName = rawName,
					baseStats = {
						maxHP = 30,
						attack = 8,
						defense = 8,
						speed = 8,
					},
					moves = {
						{ id = "slam", name = "Slam", power = 8, accuracy = 0.95 },
						{ id = "tackle", name = "Tackle", power = 5, accuracy = 1.0 },
					},
				}
				applyContentToBrainrot(id, Brainrots[id])
			end
		end
	end
end

initFromModels()

-- Alias: chimpanzinibananini (no underscore) maps to chimpanzini_bananini to avoid duplicates
if Brainrots["chimpanzini_bananini"] then
	Brainrots["chimpanzinibananini"] = Brainrots["chimpanzini_bananini"]
elseif Brainrots["chimpanzinibananini"] then
	Brainrots["chimpanzini_bananini"] = Brainrots["chimpanzinibananini"]
end

local BrainrotList = {}
for id, data in pairs(Brainrots) do
	table.insert(BrainrotList, data)
end

local module = {}

function module.getAll()
	return BrainrotList
end

function module.getById(id: string)
	return Brainrots[id]
end

function module.getRandom()
	local count = #BrainrotList
	if count == 0 then
		return nil
	end
	local index = math.random(1, count)
	return BrainrotList[index]
end

function module.createInstance(brainrotId: string, level: number?)
	level = level or 1
	local base = Brainrots[brainrotId]
	if not base then
		return nil
	end

	local stats = base.baseStats

	return {
		id = base.id,
		displayName = base.displayName,
		modelName = base.modelName or base.id,
		level = level,
		exp = 0,
		nextLevelExp = 20 + (level - 1) * 10,
		maxHP = stats.maxHP + (level - 1) * 2,
		hp = stats.maxHP + (level - 1) * 2,
		attack = stats.attack + (level - 1),
		defense = stats.defense + (level - 1),
		speed = stats.speed + (level - 1),
		moves = base.moves,
	}
end

function module.gainExperience(mon, amount: number): number
	if not mon or amount <= 0 then
		return 0
	end

	mon.exp = (mon.exp or 0) + amount
	mon.nextLevelExp = mon.nextLevelExp or (20 + (mon.level - 1) * 10)

	local levelsGained = 0
	while mon.exp >= mon.nextLevelExp do
		mon.exp -= mon.nextLevelExp
		mon.level += 1
		levelsGained += 1

		mon.maxHP += 2
		mon.hp = mon.maxHP
		mon.attack += 1
		mon.defense += 1
		mon.speed += 1

		mon.nextLevelExp = math.floor(mon.nextLevelExp * 1.5)
	end
	return levelsGained
end

function module.getTypeEffectiveness(attackType: string?, defendType: string?): number
	if not attackType or not defendType then
		return 1
	end
	local row = TYPE_EFFECTIVENESS[attackType]
	if not row then
		return 1
	end
	return row[defendType] or 1
end

function module.calculateDamage(attacker, defender, move)
	local power = move.power or 5
	local level = attacker.level or 1
	local attack = attacker.attack or 5
	local defense = defender.defense or 5

	defense = math.max(defense, 1)

	-- Simple level‑scaled physical damage formula
	local base =
		(((2 * level) / 5 + 2) * power * attack / defense) / 50

	local variance = math.random(85, 100) / 100
	local damage = math.floor((base + 2) * variance)

	-- Type effectiveness
	local attackType = move.type or "Neutral"
	local def = Brainrots[defender.id]
	local defendType = def and def.type or "Neutral"
	damage = math.floor(damage * module.getTypeEffectiveness(attackType, defendType))

	return math.max(damage, 1)
end

return module

