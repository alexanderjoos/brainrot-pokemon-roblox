local Items = {
	["brainrot_treat"] = {
		id = "brainrot_treat",
		displayName = "Brainrot Treat",
		description = "A tasty snack that your brainrots love. Pure enrichment.",
		holdable = true,
	},

	["capture_chip"] = {
		id = "capture_chip",
		displayName = "Capture Chip",
		description = "A high-tech chip that slightly improves capture chances in future updates.",
		holdable = true,
	},

	["energy_drink"] = {
		id = "energy_drink",
		displayName = "Energy Drink",
		description = "Illegally caffeinated. Restores a little HP between battles (future feature).",
	},

	["troppi_ball"] = {
		id = "troppi_ball",
		displayName = "Troppi-ball",
		description = "Special ball used to capture wild brainrots.",
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

