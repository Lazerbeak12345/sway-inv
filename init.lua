-- sway/init.lua

do
	-- Before we do anything, disable sfinv and unified_inventory. (code from i3 at
	--  commit bd5ea4e6). Also under MIT, under Jean-Patrick-Guerrero and
	--  contributors. Modified to fit my style guidelines.
	if minetest.global_exists("sfinv") then
		function sfinv.set_player_inventory_formspec() return end
		sfinv.enabled = false
	end
	if minetest.global_exists("unified_inventory") then
		function unified_inventory.set_inventory_formspec() return end
	end
end

dofile(minetest.get_modpath("sway") .. "/api.lua")

-- Load support for MT game translation.
local S = minetest.get_translator("sfinv")

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	get = function(self, player, context)
		return sway.make_formspec(player, context, [[
				list[current_player;craft;1.75,0.5;3,3;]
				list[current_player;craftpreview;5.75,1.5;1,1;]
				image[4.75,1.5;1,1;sway_crafting_arrow.png]
				listring[current_player;main]
				listring[current_player;craft]
			]], true)
	end
})
