local minetest, dump, flow, sway, flow_extras = minetest, dump, flow, sway, flow_extras
sway.pages = {}
sway.pages_unordered = {}
local contexts = {}
sway.enabled = true
local gui = flow.widgets

-- TODO: use fake tabheader

function sway.register_page(name, def)
	assert(type(name) == "string", "[sway] register_page: requires name to be string")
	assert(type(def) == "table", "[sway] register_page: requires definition table to be table")
	assert(type(def.get) == "function", "[sway] register_page: requires get inside the definition table to be function")
	assert(not sway.pages[name], "[sway] register_page: page '" .. name .. "' must not already be registered")

	sway.pages[name] = def
	def.name = name
	table.insert(sway.pages_unordered, def)
end

function sway.override_page(name, def)
	assert(type(name) == "string", "[sway] override_page: requires name to be a string")
	assert(type(def) == "table", "[sway] override_page: requires definition table to be a table")
	local page = sway.pages[name]
	assert(type(page) == "table", "[sway] override_page: the page '" .. name .. "' could not be found to override")
	if type(def.name) ~= "nil" then
		assert(type(def.name) == "string", "[sway] override_page: When overriding the name, it must be a string.")
	end
	if type(def.get) ~= "nil" then
		assert(type(def.get) == "function", "[sway] override_page: When overriding get, it must be a function.")
	end
	minetest.log("action", "[sway] override_page: '" .. name .. "' is becoming overriden")
	for key, value in pairs(def) do
		page[key] = value
	end
	if type(def.name) == "string" and name ~= def.name then
		minetest.log("action", "[sway] override_page: '" .. name .. "' is becoming renamed to '" .. page.name .. "'")
		sway.pages[page.name] = page
		sway.pages[name] = nil
	end
end

function sway.NavGui(fields)
	local nav_titles = fields.nav_titles
	local current_idx = fields.current_idx
	if #nav_titles > 1 then
		return gui.HBox{
			gui.Spacer{ expand = false, w = .2 },
			gui.Tabheader{
				h = 1,
				name = "sway_nav_tabs",
				captions = nav_titles,
				current_tab = current_idx,
				transparent = true,
				draw_border = false,
				on_event = function(player, context)
					sway.set_page(player, context.nav[context.form.sway_nav_tabs])
				end
			}
		}
	else
		return gui.Nil{}
	end
end

function sway.InventoryTiles(fields)
	if fields == nil then
		fields = {}
	end
	local w = fields.w or 8
	local h = fields.h or 4
	return gui.VBox{
		align_v = "end",
		expand = true,
		flow_extras.List{
			align_h = "center",
			inventory_location = "current_player",
			list_name = "main",
			w = w,
			h = 1,
			bgimg = "sway_hb_bg.png"
		},
		h > 1 and flow_extras.List{
			align_h = "center",
			inventory_location = "current_player",
			list_name = "main",
			w = w,
			h = h - 1,
			starting_item_index = w
		} or gui.Nil{}
	}
end
local spacing = 0.25 -- TODO
function sway.insert_prepend(widget)
	widget.no_prepend = true -- Hide the default background.
	widget.bgcolor = "#0000"
	table.insert(gui, 1, gui.StyleType{ selectors = { "list" }, props = { spacing = spacing } })
end
function sway.Form(fields)
	local show_inv = fields.show_inv
	fields.show_inv = nil

	local context = sway.get_or_create_context()

	fields.padding = .4
	if show_inv then
		fields[#fields+1] = sway.InventoryTiles()
	end

	fields.name = "content"

	return gui.VBox{
		bgimg = "sway_bg_full.png",
		bgimg_middle = 12, -- Number of pixels from each edge.
		padding = 0,
		sway.NavGui{
			nav_titles = context.nav_titles,
			current_idx = context.nav_idx
		},
		gui.VBox(fields)
	}
end

function sway.get_homepage_name(_)
	return "sway:crafting"
end

sway.form = flow.make_gui(function (player, ctx)
	sway.set_context(player, ctx)
	local form = flow_extras.set_wrapped_context(ctx, function ()
		return sway.get_form(player, ctx)
	end)
	if not form.no_prepend then
		sway.insert_prepend(form)
	end
	return form
end)

function sway.get_form(player, context)
	player, context = sway.get_player_and_context(player, context)
	-- Generate navigation tabs
	local nav = {}
	local nav_ids = {}
	local current_idx = 1
	for _, pdef in pairs(sway.pages_unordered) do
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

			return gui.Nil{}
		end

		minetest.log("warning", "[sway] Couldn't find " .. dump(old_page) ..
				" so switching to homepage")
		sway.set_page(player, home_page)
		context = sway.get_or_create_context(player)
		assert(sway.pages[context.page], "[sway] Invalid homepage")

		return sway.get_form(player, context)
	end
end

local function ensure_valid_context(player, ctx)
	if not ctx.page then
		ctx.page = sway.get_homepage_name(player)
	end
	if not ctx.player then
		ctx.player = player
	end
end

function sway.get_or_create_context(player)
	local context = flow_extras.get_context()
	if context then return context end
	assert(player, "[sway] get_or_create_context: Requires a playerref when run outside of a form.")
	local name = player:get_player_name()
	context = contexts[name]
	if not context then
		minetest.log("action", "[sway] get_or_create_context: creating new context for '" .. name .. "'")
		-- This must be the only place where a "fresh" context is generated.
		context = {}
		ensure_valid_context(player, context)
		contexts[name] = context
	end
	return context
end

function sway.get_player_and_context(player, context)
	if not context then
		context = sway.get_or_create_context(player)
	end
	if not player then
		player = context.player
	end
	return player, context
end

function sway.set_context(player, context)
	assert(player and player.get_player_name, "[sway] set_context: Requires a playerref")
	local name = player:get_player_name()
	if not context then
		minetest.log("action", "[sway] set_context: deleting context for '" .. name .. "'")
	else
		ensure_valid_context(player, context)
	end
	contexts[name] = context
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
	assert(page, "[sway] Page was set to an invalid page")
	if page.on_enter then
		page:on_enter(player, context)
	end
	sway.set_player_inventory_formspec(player, context)
end

function sway.get_page(player)
	local context = sway.get_or_create_context(player)
	return context and context.page
end

minetest.register_on_joinplayer(function(player)
	if sway.enabled then
		sway.set_player_inventory_formspec(player)
	end
end)

minetest.register_on_leaveplayer(function(player)
	contexts[player:get_player_name()] = nil
end)
