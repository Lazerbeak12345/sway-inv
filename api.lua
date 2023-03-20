sway = {
	pages = {},
	pages_unordered = {},
	contexts = {},
	enabled = true
}
local gui = flow.widgets

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

function sway.get_nav_gui(player, context, nav, current_idx)
	if #nav > 1 then
		return gui.Tabheader{
			h = 1,
			name = "sway_nav_tabs",
			captions = nav,
			current_tab = current_idx,
			transparent = true,
			draw_border = false,
		}
	else
		return gui.Box{w=0, h=0, visible = false}
	end
end
--function sway.get_nav_fs(player, context, nav, current_idx)
--	-- Only show tabs if there is more than one page
--	if #nav > 1 then
--		return "tabheader[0,0;sway_nav_tabs;" .. table.concat(nav, ",") ..
--				";" .. current_idx .. ";true;false]"
--	else
--		return ""
--	end
--end

local theme_inv = [[
		image[0,5.2;1,1;gui_hb_bg.png]
		image[1,5.2;1,1;gui_hb_bg.png]
		image[2,5.2;1,1;gui_hb_bg.png]
		image[3,5.2;1,1;gui_hb_bg.png]
		image[4,5.2;1,1;gui_hb_bg.png]
		image[5,5.2;1,1;gui_hb_bg.png]
		image[6,5.2;1,1;gui_hb_bg.png]
		image[7,5.2;1,1;gui_hb_bg.png]
		list[current_player;main;0,5.2;8,1;]
		list[current_player;main;0,6.35;8,3;8]
	]]

-- This function is under the LGPL3, since it's based on code from flow
local function force_render_flow(cb, player, ctx, form_name)
	local fl = flow.make_gui(cb)
	local mt = getmetatable(fl)
	if mt == nil then
		minetest.log("error", "(sway) Undocumented Flow API has changed. Metatable broke.")
		return ""
	end
	local idx = mt.__index
	if idx == nil then
		minetest.log("error", "(sway) Undocumented Flow API has changed. __index not found. " .. dump(mt))
		return ""
	end
	local render = idx._render
	if render == nil then
		minetest.log("error", "(sway) Undocumented Flow API has changed. _render not found. " .. dump(idx))
		return ""
	end
	local player_info = minetest.get_player_information(player:get_player_name())
	local formspec_version = player_info and player_info.formspec_version

	local rendered, info = render(fl, player, ctx, formspec_version, form_name)
	info.formname = form_name
	return assert(formspec_ast.unparse(rendered))
end

function sway.make_gui(player, context, content, show_inv, size)
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
			gui.embed( -- TODO Deprecated, but I'm using it anyway.
				(show_inv and theme_inv or "") ..
				content
			),
		}
	}
end

function sway.make_formspec(player, context, content, show_inv, size)
	return force_render_flow(
		function (p, c)
			return sway.make_gui(p, c, content, show_inv, size and formspec_ast.parse(size))
		end,
		player,
		context
	)
end

function sway.get_homepage_name(player)
	return "sway:crafting"
end

function sway.get_formspec(player, context)
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

		return sway.get_formspec(player, context)
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
	local fs = sway.get_formspec(player,
			context or sway.get_or_create_context(player))
	player:set_inventory_formspec(fs)
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

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" or not sway.enabled then
		return false
	end

	-- Get Context
	local name = player:get_player_name()
	local context = sway.contexts[name]
	if not context then
		sway.set_player_inventory_formspec(player)
		return false
	end

	-- Was a tab selected?
	if fields.sway_nav_tabs and context.nav then
		local tid = tonumber(fields.sway_nav_tabs)
		if tid and tid > 0 then
			local id = context.nav[tid]
			local page = sway.pages[id]
			if id and page then
				sway.set_page(player, id)
			end
		end
	else
		-- Pass event to page
		local page = sway.pages[context.page]
		if page and page.on_player_receive_fields then
			return page:on_player_receive_fields(player, context, fields)
		end
	end
end)
