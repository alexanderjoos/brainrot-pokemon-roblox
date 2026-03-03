local Items = {
	["brainrot_treat"] = {
		id = "brainrot_treat",
		displayName = "Brainrot Treat",
		description = "A tasty snack that your brainrots love. Pure enrichment.",
		ability = "When held: boosts EXP gained when this brainrot defeats or captures enemies.",
		holdable = true,
		usableInBattle = false,
	},

	["capture_chip"] = {
		id = "capture_chip",
		displayName = "Capture Chip",
		description = "A high-tech chip that improves capture chances when held.",
		ability = "When held: increases capture rate when capturing wild brainrots.",
		holdable = true,
		usableInBattle = false,
	},

	["energy_drink"] = {
		id = "energy_drink",
		displayName = "Energy Drink",
		description = "Illegally caffeinated. Drink it and zoom across the map.",
		ability = "Boosts your trainer's movement speed by 50% for 60 seconds.",
		usableInBattle = true,
		effect = { speedBoost = 1.5, duration = 60 },
	},

	["troppi_ball"] = {
		id = "troppi_ball",
		displayName = "Troppi-ball",
		description = "The standard capture ball. Simple, reliable, and effective.",
		ability = "Standard capture rate. Attempts to catch wild brainrots.",
		usableInBattle = true,
		effect = { captureRate = 1 },
	},

	["super_ball"] = {
		id = "super_ball",
		displayName = "Super Ball",
		description = "A stronger ball with improved capture rate.",
		ability = "1.5x capture rate. Better than a Troppi-ball.",
		usableInBattle = true,
		effect = { captureRate = 1.5 },
	},

	["ultra_ball"] = {
		id = "ultra_ball",
		displayName = "Ultra Ball",
		description = "The best ball for catching brainrots. Rare and powerful.",
		ability = "2x capture rate. The most reliable capture ball.",
		usableInBattle = true,
		effect = { captureRate = 2 },
	},

	["henny"] = {
		id = "henny",
		displayName = "Henny",
		description = "A legendary elixir. Rumored to bring back the fallen.",
		ability = "Revives a fainted brainrot with 50% of max HP.",
		usableInBattle = true,
		effect = { revive = 0.5 },
	},

	["potion"] = {
		id = "potion",
		displayName = "Potion",
		description = "A basic healing spray. Trusted by trainers everywhere.",
		ability = "Restores 20 HP.",
		usableInBattle = true,
		effect = { heal = 20 },
	},

	["super_potion"] = {
		id = "super_potion",
		displayName = "Super Potion",
		description = "A stronger healing formula. More effective than a regular potion.",
		ability = "Restores 50 HP.",
		usableInBattle = true,
		effect = { heal = 50 },
	},

	["hyper_potion"] = {
		id = "hyper_potion",
		displayName = "Hyper Potion",
		description = "Premium healing. Restores a large amount of HP.",
		ability = "Restores 100 HP.",
		usableInBattle = true,
		effect = { heal = 100 },
	},

	["full_restore"] = {
		id = "full_restore",
		displayName = "Full Restore",
		description = "The ultimate healing item. Restores everything.",
		ability = "Fully restores HP and cures all status effects (poison, burn, paralyze, sleep).",
		usableInBattle = true,
		effect = { heal = 9999, clearStatus = true },
	},

	["attack_boost"] = {
		id = "attack_boost",
		displayName = "Attack Boost",
		description = "A supplement that boosts attack power temporarily.",
		ability = "Raises Attack for 3 turns.",
		usableInBattle = true,
		effect = { statBoost = "attack", turns = 3 },
	},

	["defense_boost"] = {
		id = "defense_boost",
		displayName = "Defense Boost",
		description = "A supplement that boosts defense temporarily.",
		ability = "Raises Defense for 3 turns.",
		usableInBattle = true,
		effect = { statBoost = "defense", turns = 3 },
	},

	["speed_boost"] = {
		id = "speed_boost",
		displayName = "Speed Boost",
		description = "A fizzy supplement that makes your brainrot lightning-fast.",
		ability = "Raises Speed for 3 turns.",
		usableInBattle = true,
		effect = { statBoost = "speed", turns = 3 },
	},

	["antidote"] = {
		id = "antidote",
		displayName = "Antidote",
		description = "A cleansing tonic that purges toxins and ailments.",
		ability = "Cures all status effects (poison, burn, paralyze, sleep).",
		usableInBattle = true,
		effect = { clearStatus = true },
	},

	["master_ball"] = {
		id = "master_ball",
		displayName = "Master Ball",
		description = "The ultimate capture ball. Virtually guaranteed to catch anything.",
		ability = "5x capture rate. Almost never fails.",
		usableInBattle = true,
		effect = { captureRate = 5 },
	},

	["max_revive"] = {
		id = "max_revive",
		displayName = "Max Revive",
		description = "The premium revival item. Brings back the fallen at full strength.",
		ability = "Revives a fainted brainrot with 100% of max HP.",
		usableInBattle = true,
		effect = { revive = 1.0 },
	},

	["sigma_shield"] = {
		id = "sigma_shield",
		displayName = "Sigma Shield",
		description = "An aura of pure sigma energy. Deflects incoming damage when held.",
		ability = "When held: reduces damage taken by 20%.",
		holdable = true,
		usableInBattle = false,
	},

	["lucky_egg"] = {
		id = "lucky_egg",
		displayName = "Lucky Egg",
		description = "A mysterious glowing egg. Holding it attracts fortune.",
		ability = "When held: doubles EXP gained from battles.",
		holdable = true,
		usableInBattle = false,
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

