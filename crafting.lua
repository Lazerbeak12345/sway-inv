local minetest, sway = minetest, sway

-- Load support for MT game translation.
local S = minetest.get_translator("sway")

local gui = sway.widgets

sway.register_page("sway:crafting", {
	title = S("Crafting"),
	-- Replace this function to modify crafting page
	-- I'll be honest... this isn't a perfect solution. I've decided to knowingly compromise so _something_ happens,
	--  rather than let the project fail. Now is the perfect time to finish this project. The time could literally not be
	--  better than this.
	-- The alternative idea is to make a "template" middle layer between sway (and and everything that uses it) and flow.
	--  This layer would not immidietly expand out to final form, but delay all function calls that would do so until right
	--  before getting handed off to flow. Thus modders would have full sexp control over the gui before the expansion
	--  phase (perhaps with the exception of callbacks?). Other ideas were explored but were far too bad to work.
	filter = function (_, _, _, elm) return elm end,
	get = function(self, player, context)
		return gui.sway.Form{
			player = player,
			context = context,
			show_inv = true,
			self.filter(self, player, context, gui.HBox{
				align_h = "center",
				gui.List{
					inventory_location = "current_player",
					list_name = "craft",
					w = 3, h = 3
				},
				gui.Image{
					w = 1, h = 1,
					texture_name = "sway_crafting_arrow.png"
				},
				gui.List{
					inventory_location = "current_player",
					list_name = "craftpreview",
					w = 1, h = 1
				},
				gui.Listring{
					inventory_location = "current_player",
					list_name = "main"
				},
				gui.Listring{
					inventory_location = "current_player",
					list_name = "craft"
				}
			})
		}
	end
})
