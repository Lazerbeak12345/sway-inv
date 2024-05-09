local minetest, sway, flow, flow_extras = minetest, sway, flow, flow_extras

-- Load support for MT game translation.
local S = minetest.get_translator("sway")

local gui = flow.widgets

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	CraftingRow = function ()
		return gui.HBox{
			align_h = "center",
			name = "sway_crafting_hbox",
			flow_extras.List{
				inventory_location = "current_player",
				list_name = "craft",
				w = 3, h = 3,
				listring = { { inventory_location = "current_player", list_name = "main" } },
				spacing = sway.list_spacing
			},
			gui.Image{ w = 1, h = 1, texture_name = "sway_crafting_arrow.png" },
			flow_extras.List{
				inventory_location = "current_player",
				list_name = "craftpreview",
				w = 1, h = 1,
				spacing = sway.list_spacing
			}
		}
	end,
	get = function(self, ...)
		return sway.Form{ show_inv = true, self.CraftingRow(self, ...) }
	end
})
