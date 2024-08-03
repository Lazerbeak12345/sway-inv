-- sway/init.lua
print[[
                          Inventory powered by
 ____                                      ______
/\  _`\                                   /\__  _\
\ \,\L\_\  __  __  __     __     __  __   \/_/\ \/     ___   __  __
 \/_\__ \ /\ \/\ \/\ \  /'__`\  /\ \/\ \     \ \ \   /' _ `\/\ \/\ \
   /\ \L\ \ \ \_/ \_/ \/\ \L\.\_\ \ \_\ \     \_\ \__/\ \/\ \ \ \_/ |__
   \ `\____\ \___x___/'\ \__/.\_\\/`____ \    /\_____\ \_\ \_\ \___//\_\
    \/_____/\/__//__/   \/__/\/_/ `/___/> \   \/_____/\/_/\/_/\/__/ \/_/
                                     /\___/
                                     \/__/
]]
-- See README.md for art credit

local minetest = minetest
sway = {}

minetest.register_on_mods_loaded(function()
	-- Before we do anything, disable sfinv, unified_inventory, and i3. (code from i3 at commit bd5ea4e6). Also under MIT,
	--  under Jean-Patrick-Guerrero and contributors. Modified to fit my style guidelines, and to also disable i3
	if minetest.global_exists"sfinv" then
		function sfinv.set_player_inventory_formspec() end
		sfinv.enabled = false
	end
	if minetest.global_exists"unified_inventory" then
		function unified_inventory.set_inventory_formspec() end
	end
	assert(
		not minetest.global_exists"i3",
		"\n\n\t\t\tFATAL: Unlike all other inventory mods, is impossible to automatically disable i3, so you must do it "
		.. "yourself.\n"
	)
end)

local modpath = minetest.get_modpath"sway"
dofile(modpath .. "/api.lua")
dofile(modpath .. "/crafting.lua")
