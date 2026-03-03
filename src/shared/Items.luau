local Items = {
	["brainrot_treat"] = {
		id = "brainrot_treat",
		displayName = "Brainrot Treat",
		description = "A tasty snack that your brainrots love. Pure enrichment.",
		holdable = true,
		usableInBattle = false,
	},

	["capture_chip"] = {
		id = "capture_chip",
		displayName = "Capture Chip",
		description = "A high-tech chip that slightly improves capture chances in future updates.",
		holdable = true,
		usableInBattle = false,
	},

	["energy_drink"] = {
		id = "energy_drink",
		displayName = "Energy Drink",
		description = "Illegally caffeinated. Restores a little HP between battles (future feature).",
		usableInBattle = true,
	},

	["troppi_ball"] = {
		id = "troppi_ball",
		displayName = "Troppi-ball",
		description = "Special ball used to capture wild brainrots.",
		usableInBattle = true,
		effect = { captureRate = 1 },
	},

	["super_ball"] = {
		id = "super_ball",
		displayName = "Super Ball",
		description = "A stronger ball with improved capture rate.",
		usableInBattle = true,
		effect = { captureRate = 1.5 },
	},

	["ultra_ball"] = {
		id = "ultra_ball",
		displayName = "Ultra Ball",
		description = "The best ball for catching brainrots.",
		usableInBattle = true,
		effect = { captureRate = 2 },
	},

	["henny"] = {
		id = "henny",
		displayName = "Henny",
		description = "Revives a fainted brainrot with half of its max HP.",
		usableInBattle = true,
		effect = { revive = 0.5 },
	},

	["potion"] = {
		id = "potion",
		displayName = "Potion",
		description = "Restores 20 HP.",
		usableInBattle = true,
		effect = { heal = 20 },
	},

	["super_potion"] = {
		id = "super_potion",
		displayName = "Super Potion",
		description = "Restores 50 HP.",
		usableInBattle = true,
		effect = { heal = 50 },
	},

	["hyper_potion"] = {
		id = "hyper_potion",
		displayName = "Hyper Potion",
		description = "Restores 100 HP.",
		usableInBattle = true,
		effect = { heal = 100 },
	},

	["full_restore"] = {
		id = "full_restore",
		displayName = "Full Restore",
		description = "Fully restores HP and cures status.",
		usableInBattle = true,
		effect = { heal = 9999, clearStatus = true },
	},

	["attack_boost"] = {
		id = "attack_boost",
		displayName = "Attack Boost",
		description = "Raises attack for 3 turns.",
		usableInBattle = true,
		effect = { statBoost = "attack", turns = 3 },
	},

	["defense_boost"] = {
		id = "defense_boost",
		displayName = "Defense Boost",
		description = "Raises defense for 3 turns.",
		usableInBattle = true,
		effect = { statBoost = "defense", turns = 3 },
	},
}

local ItemList = {}
for _, item in pairs(Items) do
	table.insert(ItemList, item)
end

local module = {}

function module.getAll()
	return ItemList
end

function module.getRandom()
	if #ItemList == 0 then
		return nil
	end
	local index = math.random(1, #ItemList)
	return ItemList[index]
end

function module.getById(id: string)
	return Items[id]
end

return module

