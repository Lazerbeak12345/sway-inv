local old_sfinv = sfinv
local public_sfinv = {}
local gui = flow.widgets
function public_sfinv.register_page(name, def)
	local old_def_get = def.get
	def.get = function (self, player, context)
		local form = gui.embed(old_def_get(self, player, context))
		-- TODO insert on_event functions into form. Use it to call def:on_player_receive_fields, but only once per event.
		-- The function must be present on all nodes that can receive events, but must only be called once.
		if def.on_player_receive_fields then
			form.on_event = function (p, c, f)
				def:on_player_receive_fields(p, c, f)
			end
			local tabs = formspec_ast.get_element_by_name(form, "sway_nav_tabs") or
				formspec_ast.get_element_by_name(form, "sfinv_nav_tabs")
			tabs.on_event = sway.get_nav_gui_tabevent
		end
		return form
	end
	sway.register_page(name, def)
end
--[[ This function is under the LGPL3, since it's based on code from flow
local function force_render_flow(cb, player, ctx, form_name)
	local fl = flow.make_gui(cb)
	if fl._render == nil then
		minetest.log("error", "(sway) Undocumented Flow API has changed. _render not found. " .. dump(fl))
		return "size[5,1]label[0,0;Check Minetest error logs!]"
	end
	local player_info = minetest.get_player_information(player:get_player_name())
	local formspec_version = player_info and player_info.formspec_version

	local rendered, info = fl:_render(player, ctx, formspec_version, form_name)
	info.formname = form_name
	return assert(formspec_ast.unparse(rendered))
end]]
function public_sfinv.make_formspec(player, context, content, show_inv, size)
	if not player then return "size[8, 9.1]" .. content end
	-- assert(context ~= nil, "context can't be nil")
	-- assert(context.nav_titles ~= nil, "nav_titles needed in context")
	-- assert(context.nav_idx ~= nil, "nav_idx needed in context")
	local parsed_size = size and formspec_ast.parse(size) or { w = 8, h = 9.1 }
	local form = flow.make_gui(
		function (p, c)
			return sway.make_form(p, c, gui.embed(content, parsed_size.w, parsed_size.h), show_inv, parsed_size)
		end
		)
	local fs, callback = form:render_to_formspec_string(player, context)
	callback({})
	return fs
	--[[return force_render_flow(
		player,
		context
	)]]
end
function public_sfinv.get_homepage_name(player)
	return sway.get_homepage_name(player)
end
function public_sfinv.set_player_inventory_formspec(player, context)
sway.set_player_inventory_formspec(player, context)
end
local sfinv_metatable = {}
function sfinv_metatable:__newindex(key, value)
	if key == "get_homepage_name" then
		sway.get_homepage_name = value
	else
		minetest.log("error", "sway can't yet fake sfinv function overrides for '" .. key .. "'")
	end
end
function sfinv_metatable:__get(key) -- TODO not working
	if key == "pages_unordered" then
		return sway.pages_unordered
	end
end
sfinv = setmetatable(public_sfinv, sfinv_metatable)
