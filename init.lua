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

-- This is defined as a function so I can unit-test it. Not intended for consumption. This function's specifications are
-- subject to change without notice. Please talk to your Doctor to see if sway is right for you. Known to cause cancer
-- and reproductive harm in the state of California. May explode if improperly recharged. Please stop using this
-- function if you feel like your code is bloated, if it feels sluggish, or generally behaves like systemd. Please do
-- not the cat. See CODE_LICENSE.txt and MEDIA_LICENSE.txt for information about copyright holders (when not expressly
-- mentioned near a relevant section of the code), warranty, and any terms and conditions that may or may not apply.
sway.__conqueror = function ()
	-- Before we do anything, disable sfinv, unified_inventory, and i3. (code from i3 at commit bd5ea4e6). Also under MIT,
	--  under Jean-Patrick-Guerrero and contributors. Modified to fit my style guidelines, and to also disable i3
	if minetest.global_exists("sfinv") then
		function sfinv.set_player_inventory_formspec() end
		sfinv.enabled = false
	end
	if minetest.global_exists("unified_inventory") then
		function unified_inventory.set_inventory_formspec() end
	end
	if minetest.global_exists("i3") then
		function i3.set_fs() end
	end
end
sway.__conqueror()

local modpath = minetest.get_modpath("sway")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/crafting.lua")
