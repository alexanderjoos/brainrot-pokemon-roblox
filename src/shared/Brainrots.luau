local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots: { [string]: any } = {}

local function initFromModels()
	local modelsFolder = ReplicatedStorage:FindFirstChild("BrainrotList")
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
			end
		end
	end
end

initFromModels()

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

function module.gainExperience(mon, amount: number)
	if not mon or amount <= 0 then
		return
	end

	mon.exp = (mon.exp or 0) + amount
	mon.nextLevelExp = mon.nextLevelExp or (20 + (mon.level - 1) * 10)

	while mon.exp >= mon.nextLevelExp do
		mon.exp -= mon.nextLevelExp
		mon.level += 1

		mon.maxHP += 2
		mon.hp = mon.maxHP
		mon.attack += 1
		mon.defense += 1
		mon.speed += 1

		mon.nextLevelExp = math.floor(mon.nextLevelExp * 1.5)
	end
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

	return math.max(damage, 1)
end

return module

