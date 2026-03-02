local Brainrots = {
	["chimpanzini_bananini"] = {
		id = "chimpanzini_bananini",
		displayName = "Chimpanzini Bananini",
		description = "A chaotic monkey brainrot obsessed with bananas and memes.",
		baseStats = {
			maxHP = 30,
			attack = 8,
			defense = 5,
			speed = 6,
		},
		moves = {
			{
				id = "banana_bonk",
				name = "Banana Bonk",
				power = 8,
				accuracy = 0.95,
			},
			{
				id = "chimp_screech",
				name = "Chimp Screech",
				power = 5,
				accuracy = 1.0,
			},
		},
	},

	["sigma_skibidi"] = {
		id = "sigma_skibidi",
		displayName = "Sigma Skibidi",
		description = "Cool-headed brainrot with a questionable taste in music.",
		baseStats = {
			maxHP = 26,
			attack = 7,
			defense = 6,
			speed = 8,
		},
		moves = {
			{
				id = "skibidi_blast",
				name = "Skibidi Blast",
				power = 9,
				accuracy = 0.9,
			},
			{
				id = "sigma_stare",
				name = "Sigma Stare",
				power = 4,
				accuracy = 1.0,
			},
		},
	},

	["rizzlord_gpt"] = {
		id = "rizzlord_gpt",
		displayName = "Rizzlord GPT",
		description = "Smooth-talking AI brainrot that never runs out of lines.",
		baseStats = {
			maxHP = 28,
			attack = 6,
			defense = 7,
			speed = 7,
		},
		moves = {
			{
				id = "rizz_reply",
				name = "Rizz Reply",
				power = 7,
				accuracy = 0.95,
			},
			{
				id = "overthink",
				name = "Overthink",
				power = 5,
				accuracy = 1.0,
			},
		},
	},
}

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

