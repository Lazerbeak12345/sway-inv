sway = {
	pages = {},
	pages_unordered = {},
	contexts = {},
	enabled = true
}
local gui = flow.widgets
local gui_nil = gui.Spacer{expand=false}

function sway.register_page(name, def)
	assert(name, "Invalid sway page. Requires a name")
	assert(def, "Invalid sway page. Requires a def[inition] table")
	assert(def.get, "Invalid sway page. Def requires a get function.")
	assert(not sway.pages[name], "Attempt to register already registered sway page " .. dump(name))

	sway.pages[name] = def
	def.name = name
	table.insert(sway.pages_unordered, def)
end

function sway.override_page(name, def)
	assert(name, "Invalid sway page override. Requires a name")
	assert(def, "Invalid sway page override. Requires a def[inition] table")
	local page = sway.pages[name]
	assert(page, "Attempt to override sway page " .. dump(name) .. " which does not exist.")
	for key, value in pairs(def) do
		page[key] = value
	end
end

function sway.get_nav_gui_tabevent(player, context)
	sway.set_page(player, context.nav[context.form.sway_nav_tabs])
end

function sway.get_nav_gui(player, context, nav_titles, current_idx)
	if #nav_titles > 1 then
		return gui.Tabheader{
			h = 1,
			name = "sway_nav_tabs",
			captions = nav_titles,
			current_tab = current_idx,
			transparent = true,
			draw_border = false,
			on_event = sway.get_nav_gui_tabevent
		}
	else
		return gui_nil
	end
end

-- TODO turn this into a function overidable by downstream. Take w and h args.
local theme_inv = gui.VBox{
	gui.Stack{
		padding = 0.1,
		gui.HBox{
			-- Eight horizontal images
			spacing = 0.25, -- Off by less than a pixel on most aspect ratios I tried, but some will be off by quite a bit.
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" },
			gui.Image{ w = 1, h = 1, texture_name = "gui_hb_bg.png" }
		},
		gui.List{
			inventory_location = "current_player",
			list_name = "main",
			w = 8,
			h = 1,
		}
	},
	gui.List{
		inventory_location = "current_player",
		list_name = "main",
		w = 8,
		h = 3,
		starting_item_index = 8
	}
}

function sway.make_form(player, context, content, show_inv, size)
	if size then
		assert(type(size) == "table", "size must be table")
	end
	local default_size = { w = 8, h = 9.1 }
	local actual_size = size and {
		size.w or default_size.w,
		size.h or default_size.h
	} or default_size
	return gui.VBox{
		padding = 0,
		sway.get_nav_gui(player, context, context.nav_titles, context.nav_idx),
		gui.VBox{
			min_w = actual_size.w,
			min_h = actual_size.h,
			padding = .3,
			content,
			(show_inv and theme_inv or gui_nil),
		}
	}
end

function sway.get_homepage_name(player)
	return "sway:crafting"
end

sway.form = flow.make_gui(function (player, ctx)
	return sway.get_form(player, ctx)
end)

function sway.get_form(player, context)
	-- Generate navigation tabs
	local nav = {}
	local nav_ids = {}
	local current_idx = 1
	for i, pdef in pairs(sway.pages_unordered) do
		if not pdef.is_in_nav or pdef:is_in_nav(player, context) then
			nav[#nav + 1] = pdef.title
			nav_ids[#nav_ids + 1] = pdef.name
			if pdef.name == context.page then
				current_idx = #nav_ids
			end
		end
	end
	context.nav = nav_ids
	context.nav_titles = nav
	context.nav_idx = current_idx

	-- Generate formspec
	local page = sway.pages[context.page] or sway.pages["404"]
	if page then
		return page:get(player, context)
	else
		local old_page = context.page
		local home_page = sway.get_homepage_name(player)

		if old_page == home_page then
			minetest.log("error", "[sway] Couldn't find " .. dump(old_page) ..
					", which is also the old page")

			return ""
		end

		context.page = home_page
		assert(sway.pages[context.page], "[sway] Invalid homepage")
		minetest.log("warning", "[sway] Couldn't find " .. dump(old_page) ..
				" so switching to homepage")

		return sway.get_form(player, context)
	end
end

function sway.get_or_create_context(player)
	local name = player:get_player_name()
	local context = sway.contexts[name]
	if not context then
		context = {
			page = sway.get_homepage_name(player)
		}
		sway.contexts[name] = context
	end
	return context
end

function sway.set_context(player, context)
	sway.contexts[player:get_player_name()] = context
end

function sway.set_player_inventory_formspec(player, context)
	sway.form:set_as_inventory_for(player, context or sway.get_or_create_context(player))
end

function sway.set_page(player, pagename)
	local context = sway.get_or_create_context(player)
	local oldpage = sway.pages[context.page]
	if oldpage and oldpage.on_leave then
		oldpage:on_leave(player, context)
	end
	context.page = pagename
	local page = sway.pages[pagename]
	if page.on_enter then
		page:on_enter(player, context)
	end
	sway.set_player_inventory_formspec(player, context)
end

function sway.get_page(player)
	local context = sway.contexts[player:get_player_name()]
	return context and context.page or sway.get_homepage_name(player)
end

minetest.register_on_joinplayer(function(player)
	if sway.enabled then
		sway.set_player_inventory_formspec(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	sway.contexts[player:get_player_name()] = nil
end)
