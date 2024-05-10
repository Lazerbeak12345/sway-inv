-- TODO: rewrite this file so a dependent mod developer can import this library as integration code. Once that's done
-- add it to the FAQ in the README
local function nilfn(...) local _={...} end -- By saving the args here, we get rid of a TON of false positive warnings
local function ident(v)
	return function ()
		return v
	end
end
local minetest = {
	register_on_player_receive_fields = nilfn,
	register_chatcommand = nilfn,
	get_translator = ident(ident),
	is_singleplayer = ident(true),
	global_exists = function (name)
		return _G[name] ~= nil
	end,
	log = nilfn,
	_register_on_leaveplayer_calls = {},
	register_on_leaveplayer = function (...)
		minetest._register_on_leaveplayer_calls[#minetest._register_on_leaveplayer_calls+1] = {...}
	end,
	_register_on_joinplayer_calls = {},
	register_on_joinplayer = function (...)
		minetest._register_on_joinplayer_calls[#minetest._register_on_joinplayer_calls+1] = {...}
	end,
	get_player_information = ident{}
}
local function stupid_dump(...)
	for _, item in ipairs{ ... } do
		print"{"
		for key, value in pairs(item) do
			print("", key, " = ", value)
		end
		print"}"
	end
	return ...
end
assert(stupid_dump) -- Hack to make it so I don't have to ignore that this function is usually unused.
local FORMSPEC_AST_PATH = '../formspec_ast'
_G.FORMSPEC_AST_PATH = FORMSPEC_AST_PATH
function minetest.get_modpath(modname)
	if modname == "flow" then return "../flow" end
	if modname == "formspec_ast" then return FORMSPEC_AST_PATH end
	if modname == "flow_extras" then return "../flow-extras" end
	assert(modname == "sway", "modname must be sway. was " .. modname)
	return "."
end
dofile(FORMSPEC_AST_PATH .. '/init.lua')
_G.minetest = minetest -- Must be defined after formspec_ast runs
_G.dump = function (item)
	if type(item) == "table" then
		local out = "{ "
		for key, value in pairs(item) do
			out = out .. dump(key) .. " = " .. dump(value) .. ", "
		end
		return out .. "}"
	elseif type(item) == "string" then
		return "\"" .. item .. "\""
	elseif type(item) == "boolean" then
		return item and "true" or "false"
	elseif type(item) == "function" then
		return "function () [...] end"
	elseif item == nil then
		return "nil"
	else
		return item .. ""
	end
end
dofile"../flow/init.lua"
dofile"../flow-extras/init.lua"
dofile"init.lua"
local default_pages = sway.pages
--local default_pages_ordered = sway.pages_ordered
local describe, it, assert, pending, stub, before_each = describe, it, assert, pending, stub, before_each
local function fancy_stub(obj, name, callback)
	local old = obj[name]
	stub(obj, name)
	callback(old)
	obj[name] = old
end
assert(pending, "Hack to ensure pending doesn't give errors if it's not in use")
local sway, flow_extras, formspec_ast, flow = sway, flow_extras, formspec_ast, flow
local gui = flow.widgets
describe("*basics*", function ()
	it("doesn't error out when loading init.lua", function ()
		assert(true, "by the time it got here it would have failed if it didn't work")
	end)
	it("provides a global variable for it's api to go into", function ()
		assert.equal("table", type(sway), "sway is a table")
	end)
end)
describe("pages", function ()
	local testpagename = "sway:test"
	before_each(function()
		sway.pages = {}
		sway.pages_ordered = {}
	end)
	describe("register_page", function ()
		it("is a function on sway", function ()
			assert.equal("function", type(sway.register_page))
		end)
		it("requires name", function ()
			assert.has_error(function ()
				sway.register_page()
			end, "[sway] register_page: requires name to be string")
		end)
		it("requires name is string", function ()
			assert.has_error(function ()
				sway.register_page({}, { get = true })
			end, "[sway] register_page: requires name to be string")
		end)
		it("requires definition table", function ()
			assert.has_error(function ()
				sway.register_page(testpagename)
			end, "[sway] register_page: requires definition table to be table")
		end)
		it("requires definition table is table", function ()
			assert.has_error(function ()
				sway.register_page(testpagename, true)
			end, "[sway] register_page: requires definition table to be table")
		end)
		it("requires get inside table", function ()
			assert.has_error(function ()
				sway.register_page(testpagename, {})
			end, "[sway] register_page: requires get inside the definition table to be function")
		end)
		it("requires get inside table to be function", function ()
			assert.has_error(function ()
				sway.register_page(testpagename, { get = true })
			end, "[sway] register_page: requires get inside the definition table to be function")
		end)
		it("page must not already be registered", function ()
			sway.register_page(testpagename, { get = function () end })
			assert.has_error(function ()
				sway.register_page(testpagename, { get = function () end })
			end, "[sway] register_page: page '" .. testpagename .. "' must not already be registered")
		end)
		it("assert when is_in_nav is not null or a function", function ()
			assert.has_error(function ()
				sway.register_page(testpagename, { get = function () end, is_in_nav = "A very sus string." })
			end, "[sway] register_page: page '" .. testpagename .. "' is_in_nav must be nil or a fn.")
		end)
		it("inserts name into def, puts def into pages as key and pages_ordered", function ()
			local def = { get = function () end }
			sway.register_page(testpagename, def)
			assert.equals(testpagename, def.name)
			assert.equals(def, sway.pages[testpagename])
			assert.equals(def, sway.pages_ordered[1])
		end)
	end)
	describe("override_page", function ()
		it("is a function on sway", function ()
			assert.equal("function", type(sway.override_page))
		end)
		it("requires name", function ()
			assert.has_error(function ()
				sway.override_page()
			end, "[sway] override_page: requires name to be a string")
		end)
		it("requires name to be a string", function ()
			assert.has_error(function ()
				sway.override_page({}, { get = function() end })
			end, "[sway] override_page: requires name to be a string")
		end)
		it("requires definition table", function ()
			assert.has_error(function ()
				sway.override_page(testpagename)
			end, "[sway] override_page: requires definition table to be a table")
		end)
		it("requires definition table to be a string", function ()
			assert.has_error(function ()
				sway.override_page(testpagename, true)
			end, "[sway] override_page: requires definition table to be a table")
		end)
		it("requires that the page must already exsist", function ()
			assert.has_error(function ()
				sway.override_page(testpagename, {})
			end, "[sway] override_page: the page '" .. testpagename .. "' could not be found to override")
		end)
		it("assert when is_in_nav is not null or a function", function ()
			sway.register_page(testpagename, { get = function () end })
			assert.has_error(function ()
				sway.override_page(testpagename, { get = function () end, is_in_nav = "A very sus string." })
			end, "[sway] override_page: page '" .. testpagename .. "' is_in_nav must be nil or a fn.")
		end)
		it("logs that a page is getting overriden", function ()
			sway.register_page(testpagename, { get = function () end })
			fancy_stub(minetest, "log", function ()
				sway.override_page(testpagename, {})
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] override_page: '" .. testpagename .. "' is becoming overriden"
				)
				assert.stub(minetest.log).was.called(1)
			end)
		end)
		it("copies all keys from the new def onto the old table", function ()
			local def = { a = 1, b = 2, get = function () end }
			local override = { b = 100, c = "value", thingy = {} }
			sway.register_page(testpagename, def)
			sway.override_page(testpagename, override)
			assert.same({ a = 1, b = 100, c = "value", get = def.get, thingy = {}, name = testpagename }, def)
			assert.are_not.equal(def, override)
			assert.are_not.same(def, override)
			assert.equal(override.thingy, def.thingy)
		end)
		-- This is to prevent invalid state, and also why it can be a bad idea to store self-refrences.
		it("ensures that changing name in def will update sway.def", function ()
			local def = { get = function () end }
			local override = { name = "sway:test2" }
			sway.register_page(testpagename, def)
			fancy_stub(minetest, "log", function ()
				sway.override_page(testpagename, override)
				assert.same({
					["sway:test2"] = def,
				}, sway.pages)
				assert.same({ def }, sway.pages_ordered)
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] override_page: '" .. testpagename .. "' is becoming renamed to 'sway:test2'"
				)
			end)
		end)
		it("requires overrides to name to be a string", function ()
			sway.register_page(testpagename, { get = function () end})
			assert.has_error(function ()
				sway.override_page(testpagename, { name = true })
			end, "[sway] override_page: When overriding the name, it must be a string.")
		end)
		it("requires overrides to get to be a function", function ()
			sway.register_page(testpagename, { get = function () end})
			assert.has_error(function ()
				sway.override_page(testpagename, { get = true })
			end, "[sway] override_page: When overriding get, it must be a function.")
		end)
	end)
	describe("pages", function ()
		-- TODO isn't this a pointless assertion?
		it("is a table on sway", function ()
			assert.equal("table", type(sway.pages))
		end)
		it("register_page adds to this table by pagename", function ()
			local def = { get = function () end }
			sway.register_page(testpagename, def)
			local def2 = { get = function () end }
			sway.register_page(testpagename .. "1", def2)
			assert.same({
				[testpagename]= def,
				[testpagename .. "1"]= def2
			}, sway.pages)
			assert.equal(def, sway.pages[testpagename])
			assert.equal(def2, sway.pages[testpagename .. "1"])
		end)
	end)
	describe("pages_ordered", function ()
		-- TODO isn't this a pointless assertion?
		it("is a table on sway", function ()
			assert.equal("table", type(sway.pages_ordered))
		end)
		it("register_page adds to this table by order registered", function ()
			local def = { get = function () end }
			sway.register_page(testpagename, def)
			local def2 = { get = function () end }
			sway.register_page(testpagename .. "1", def2)
			assert.same({ def, def2 }, sway.pages_ordered)
			assert.equal(def, sway.pages_ordered[1])
			assert.equal(def2, sway.pages_ordered[2])
		end)
	end)
	describe("get_homepage_name", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_homepage_name))
		end)
		it("by default returns the crafting page", function ()
			assert.same("sway:crafting", sway.get_homepage_name{}) -- This table is a mock of the player api
		end)
		it("can be overriden", function ()
			local old = sway.get_homepage_name
			function sway.get_homepage_name(_)
				return testpagename
			end
			assert.same(testpagename, sway.get_homepage_name{}) -- This table is a mock of the player api
			sway.get_homepage_name = old
		end)
		-- NOTE: Requires testing of the other stuff.... perhaps it should be tested from callsite instead
		--pending"is given the player object"
	end)
	-- TODO: Horrible names. Should be get_page_name and set_page_by_name
	describe("set_page", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.set_page))
		end)
		it("asserts that the pagename is a string", function ()
			assert.has_error(function ()
				sway.set_page({ get_player_name = ident"playername" }, {})
			end, "[sway] set_page: expected a string for the page name. Got a 'table'")
		end)
		it("gets the current page, sets to the new page and asserts if the newpage is invalid", function ()
			local old_pages = sway.pages
			local old_get_or_create_context = sway.get_or_create_context
			local ctx = {}
			sway.pages = {}
			sway.get_or_create_context = function ()
				return ctx
			end
			assert.has_error(function ()
				sway.set_page({}, "fake:page")
			end, "[sway] set_page: Page not found: 'fake:page'")
			assert.same({}, ctx)
			sway.get_or_create_context = old_get_or_create_context
			sway.pages = old_pages
		end)
		it("if the newpage is valid, calls set_player_inventory_formspec", function ()
			local old_get_or_create_context = sway.get_or_create_context
			local old_pages = sway.pages
			local old_set_player_inventory_formspec = sway.set_player_inventory_formspec
			local ctx = {}
			local player = {}
			sway.pages = { ["real:page"]={} }
			sway.get_or_create_context = function ()
				return ctx
			end
			local spif_calls = {}
			sway.set_player_inventory_formspec = function (...)
				spif_calls[#spif_calls+1] = {...}
			end
			sway.set_page(player, "real:page")
			sway.get_or_create_context = old_get_or_create_context
			sway.pages = old_pages
			sway.set_player_inventory_formspec = old_set_player_inventory_formspec
			assert.same({{player, ctx}}, spif_calls, "spif_calls")
			assert.same({page = "real:page"}, ctx, "context")
		end)
		it("if there's an on_leave function it calls it", function ()
			-- TODO  should I use test composition for these tests? They're nearly exactly the same.
			local old_get_or_create_context = sway.get_or_create_context
			local old_pages = sway.pages
			local old_set_player_inventory_formspec = sway.set_player_inventory_formspec
			local ctx = {page = "old:page"}
			local player = {}
			local ol_calls = {}
			local function on_leave(...)
				ol_calls[#ol_calls+1] = {...}
			end
			local old_page = { on_leave = on_leave }
			sway.pages = {
				["old:page"]=old_page,
				["real:page"]={}
			}
			sway.get_or_create_context = function ()
				return ctx
			end
			local spif_calls = {}
			sway.set_player_inventory_formspec = function (...)
				spif_calls[#spif_calls+1] = {...}
			end
			sway.set_page(player, "real:page")
			sway.get_or_create_context = old_get_or_create_context
			sway.pages = old_pages
			sway.set_player_inventory_formspec = old_set_player_inventory_formspec
			assert.same({{player, ctx}}, spif_calls, "spif_calls")
			assert.same({page = "real:page"}, ctx, "context")
			assert.same({{old_page, player, ctx}}, ol_calls, "ol_calls")
		end)
		it("on_leave is not called if the page is not found", function ()
			local old_pages = sway.pages
			local old_get_or_create_context = sway.get_or_create_context
			local ctx = {page = "old:page"}
			local ol_calls = {}
			local function on_leave(...)
				ol_calls[#ol_calls+1] = {...}
			end
			local old_page = { on_leave = on_leave }
			sway.pages = { ["old:page"]=old_page }
			sway.get_or_create_context = function ()
				return ctx
			end
			assert.has_error(function ()
				sway.set_page({}, "fake:page")
			end, "[sway] set_page: Page not found: 'fake:page'")
			assert.same({ page = "old:page" }, ctx, "context")
			assert.same({}, ol_calls, "ol_calls")
			sway.get_or_create_context = old_get_or_create_context
			sway.pages = old_pages
		end)
		it("if there's an on_enter function it calls it", function ()
			local old_get_or_create_context = sway.get_or_create_context
			local old_pages = sway.pages
			local old_set_player_inventory_formspec = sway.set_player_inventory_formspec
			local ctx = {}
			local player = {}
			local oe_calls = {}
			local function on_enter(...)
				oe_calls[#oe_calls+1] = {...}
			end
			local new_page = { on_enter = on_enter }
			sway.pages = { ["real:page"]= new_page }
			sway.get_or_create_context = function ()
				return ctx
			end
			local spif_calls = {}
			sway.set_player_inventory_formspec = function (...)
				spif_calls[#spif_calls+1] = {...}
			end
			sway.set_page(player, "real:page")
			sway.get_or_create_context = old_get_or_create_context
			sway.pages = old_pages
			sway.set_player_inventory_formspec = old_set_player_inventory_formspec
			assert.same({{player, ctx}}, spif_calls, "spif_calls")
			assert.same({page = "real:page"}, ctx, "context")
			assert.same({{new_page, player, ctx}}, oe_calls, "oe_calls")
		end)
	end)
	describe("get_page", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_page))
		end)
		it("makes a call to get the context then returns it if falsy", function ()
			local old_get_or_create_context = sway.get_or_create_context
			local gocc_called_with = {}
			local ctx = { page = "page:name" }
			local player = {234234}
			sway.get_or_create_context = function (...)
				gocc_called_with[# gocc_called_with+1] = {...}
				return ctx
			end
			local ret = sway.get_page(player)
			assert.same(gocc_called_with, {{player}}, "calls to get or get_or_create_context")
			assert.same(ret, "page:name", "return value")
			sway.get_or_create_context = old_get_or_create_context
		end)
	end)
end)
describe("context", function ()
	local mock_playerref = {
		get_player_name = function(_)
			return "lazerbeak12345"
		end
	}
	describe("set_context", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.set_context))
		end)
		it("requires a player", function ()
			assert.has_error(function ()
				sway.set_context()
			end, "[sway] set_context: Requires a playerref")
		end)
		it("requires a playerref", function ()
			assert.has_error(function ()
				sway.set_context{}
			end, "[sway] set_context: Requires a playerref")
		end)
		it("deletes the current context if it wasn't be provided", function ()
			fancy_stub(minetest, "log", function ()
				sway.set_context(mock_playerref)
				-- assert that it was logged to be deleted
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] set_context: deleting context for 'lazerbeak12345'"
				)
				assert.stub(minetest.log).was.called(1)
				sway.get_or_create_context(mock_playerref)
				-- assert that getting the context causes a new log item that it was created
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
				)
				assert.stub(minetest.log).was.called(2)
				-- delete it again to keep state clean. We know this works because we just asserted that it does.
				sway.set_context(mock_playerref)
			end)
		end)
		it("ensures that the needed properties are present", function ()
			local ctx = {}
			sway.set_context(mock_playerref, ctx)
			assert.equal(ctx, sway.get_or_create_context(mock_playerref))
			assert.same("string", type(ctx.page))
			assert.equal(mock_playerref:get_player_name(), ctx.player_name)
			-- Clean the state
			sway.set_context(mock_playerref)
		end)
	end)
	describe("get_or_create_context", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_or_create_context))
		end)
		it("returns context from flow_extras if found", function ()
			local flow_extras_ctx = {}
			local output
			flow_extras.set_wrapped_context(flow_extras_ctx, function ()
				output = sway.get_or_create_context()
			end)
			assert.equal(flow_extras_ctx, output)
		end)
		it("requires a player if flow_extras can't get the context", function ()
			assert.has_error(function ()
				sway.get_or_create_context()
			end, "[sway] get_or_create_context: Requires a playerref when run outside of a form.")
		end)
		it("if context can't be found create a new one", function ()
			-- Clean the state
			sway.set_context(mock_playerref)
			fancy_stub(minetest, "log", function ()
				local ctx = sway.get_or_create_context(mock_playerref)
				assert.truthy(ctx, "It exsists at first.")
				assert.stub(minetest.log).was.called(1)
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
				)
				-- Clean the state again
				sway.set_context(mock_playerref)
				assert.stub(minetest.log).was.called(2)
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] set_context: deleting context for 'lazerbeak12345'"
				)
				local old_ctx = ctx
				ctx = sway.get_or_create_context(mock_playerref)
				assert.stub(minetest.log).was.called(3)
				assert.stub(minetest.log).was.called_with(
					"action",
					"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
				)
				assert.truthy(ctx, "It still exsists")
				assert.are_not.equal(ctx, old_ctx)
				-- Clean the state at the end
				sway.set_context(mock_playerref)
			end)
		end)
		it("return the context if it can be found", function ()
			local ctx = {}
			sway.set_context(mock_playerref, ctx)
			assert.equal(ctx, sway.get_or_create_context(mock_playerref))
			sway.set_context(mock_playerref)
		end)
	end)
	describe("get_player_and_context", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_player_and_context))
		end)
		it("if context and player are provided, return them", function ()
			local player, context = {}, {}
			local r_player, r_context = sway.get_player_and_context(player, context)
			assert.equals(player, r_player, "player is equal")
			assert.equals(context, r_context, "context is equal")
		end)
		it("if only the player is provided, call get_or_create_context with the player", function ()
			--TODO spy broke .... the workaround is fine
			--spy(sway,"get_or_create_context")
			local old_get_or_create_context = sway.get_or_create_context
			local gocc_called_with ={}
			sway.get_or_create_context = function (...)
				gocc_called_with[#gocc_called_with+1] = {...}
				return old_get_or_create_context(...)
			end
			local old_get_player_by_name = minetest.get_player_by_name
			local player, i_context = {}, {}
			local get_player_by_name_count = 0
			minetest.get_player_by_name = function ()
				assert(false, "player by name must not be called!")
			end
			local r_player, r_context
			flow_extras.set_wrapped_context(i_context, function ()
				r_player, r_context = sway.get_player_and_context(player)
			end)
			--assert.spy(sway.get_or_create_context).was.called_with(player)
			assert.same({{player}}, gocc_called_with, "all args")
			assert.equals(player, gocc_called_with[1][1], "first arg")
			assert.equals(player, r_player, "player is equal")
			assert.equals(i_context, r_context, "context is equal")
			assert.equals(0, get_player_by_name_count, "we don't need to call this function")
			sway.get_or_create_context = old_get_or_create_context
			minetest.get_player_by_name = old_get_player_by_name
		end)
		it("if only the context is provided, return the player referenced by the context", function ()
			local i_player, context = {}, {
				player_name = "lazerbeak12345"
			}
			local old_get_player_by_name = minetest.get_player_by_name
			local gpbn_calls = {}
			minetest.get_player_by_name = function (...)
				gpbn_calls[#gpbn_calls+1] = {...}
				return i_player
			end
			local r_player, r_context = sway.get_player_and_context(nil, context)
			assert.same({{"lazerbeak12345"}}, gpbn_calls)
			assert.equals(i_player, r_player)
			assert.equals(context, r_context)
			minetest.get_player_by_name = old_get_player_by_name
		end)
		it("if neither args are provided, call get_or_create_context with nothing", function ()
			local old_get_or_create_context = sway.get_or_create_context
			local gocc_called_with ={}
			sway.get_or_create_context = function (...)
				gocc_called_with[#gocc_called_with+1] = {...}
				return old_get_or_create_context(...)
			end
			local old_get_player_by_name = minetest.get_player_by_name
			local i_player, i_context = {}, {
				player_name = "lazerbeak12345"
			}
			local gpbn_calls = {}
			minetest.get_player_by_name = function (...)
				gpbn_calls[#gpbn_calls+1] = {...}
				return i_player
			end
			local r_player, r_context
			flow_extras.set_wrapped_context(i_context, function ()
				r_player, r_context = sway.get_player_and_context()
			end)
			assert.same({{"lazerbeak12345"}}, gpbn_calls, "calls to get_player_by_name")
			assert.same({{}}, gocc_called_with, "all args to get_or_create_context")
			assert.equals(i_player, r_player, "player is equal")
			assert.equals(i_context, r_context, "context is equal")
			sway.get_or_create_context = old_get_or_create_context
			minetest.get_player_by_name = old_get_player_by_name
		end)
	end)
end)
describe("default page", function ()
	it("there's one default page", function ()
		local count = 0
		for _, _ in pairs(default_pages) do
			count = count + 1
		end
		assert.equal(1, count)
		assert.truthy(default_pages["sway:crafting"])
	end)
	-- This unit test doesn't test the _literal_ content of the form. Instead it tests by checking that the form has the
	-- parts it needs.
	it("the default page provides an overrideable function that returns a form", function ()
		local row = default_pages["sway:crafting"].CraftingRow
		assert.same("function", type(row), "CraftingRow is a function")
		local render = row()
		local sway_crafting_hbox = flow_extras.search{
			tree = render,
			key = "name",
			value = "sway_crafting_hbox",
			check_root = true
		}()
		assert.truthy(sway_crafting_hbox, "Contains sway_crafting_hbox")
		assert.same("hbox", sway_crafting_hbox.type, "sway_crafting_hbox type")
		do
			local has_at_least_one_crafting_inventory = false
			for crafting_inventory in flow_extras.search{
				tree = sway_crafting_hbox,
				key = "list_name",
				value = "craft"
			} do
				has_at_least_one_crafting_inventory = true
				assert.same("current_player", crafting_inventory.inventory_location, "location")
			end
			assert.True(has_at_least_one_crafting_inventory, "has_at_least_one_crafting_inventory")
		end
		do
			local has_at_least_one_crafting_preview = false
			for crafting_preview in flow_extras.search{
				tree = sway_crafting_hbox,
				key = "list_name",
				value = "craftpreview"
			} do
				has_at_least_one_crafting_preview = true
				assert.same("current_player", crafting_preview.inventory_location, "location")
			end
			assert.True(has_at_least_one_crafting_preview, "has_at_least_one_crafting_preview")
		end
	end)
	it("provides a get function that returns the result of sway.Form with the result of CraftingRow", function ()
		local crafting = default_pages["sway:crafting"]
		local get = crafting.get

		local old_CR = crafting.CraftingRow
		local old_Form = sway.Form

		local CR_args = {}
		crafting.CraftingRow = function (self, ...)
			CR_args[#CR_args+1] = {self, ...}
			return gui.VBox{ name = "crow", ... }
		end
		sway.Form = function (table)
			table.name = "form"
			return gui.VBox(table)
		end

		local render = get(crafting)

		sway.Form = old_Form
		crafting.CraftingRow = old_CR

		local form = flow_extras.search{
			tree = render,
			key = "name",
			value = "form",
			check_root = true
		}()

		assert.truthy(form, "Contains Form")
		assert.equal(crafting, CR_args[1][1], "it's passed self")
		assert.truthy(flow_extras.search{
			tree = form,
			key = "name",
			value = "crow",
		}(), "contains crafting row")
	end)
end)
-- tests for the API integration with Minetest, Flow and Flow-Extras (the tools this library is based upon)
describe("Lower-Layer Integration", function ()
	describe("sway.enabled", function ()
		it("is a boolean on sway", function ()
			assert.equal("boolean", type(sway.enabled))
		end)
		-- WARNING: This test would break integration test mode.
		it("defaults to true", function ()
			assert.True(sway.enabled)
		end)
	end)
	local onleaveplayer_cb = function (...)
		for _, args in ipairs(minetest._register_on_leaveplayer_calls) do
			args[1](...)
		end
	end
	local onjoinplayer_cb = function (...)
		for _, args in ipairs(minetest._register_on_joinplayer_calls) do
			args[1](...)
		end
	end
	local fakeplayer = {get_player_name=ident"fakeplayer"}
	describe("on_leaveplayer", function ()
		it("calls set_context", function ()
			local old_sc = sway.set_context
			local sc_calls = {}
			sway.set_context = function (...)
				sc_calls[#sc_calls+1] = {...}
			end
			onleaveplayer_cb(fakeplayer)
			sway.set_context = old_sc
			assert.same({{fakeplayer}}, sc_calls)
		end)
	end)
	describe("on_joinplayer", function ()
		it("if sway is disabled, the callback does nothing", function ()
			local old_enabled = sway.enabled
			sway.enabled = false
			local old_spif = sway.set_player_inventory_formspec
			local spif_calls = {}
			sway.set_player_inventory_formspec = function (...)
				spif_calls[#spif_calls+1] = {...}
			end
			onjoinplayer_cb(fakeplayer)
			sway.enabled = old_enabled
			sway.set_player_inventory_formspec = old_spif
			assert.same({}, spif_calls)
		end)
		it("if sway is enabled, it calls sway.set_player_inventory_formspec", function ()
			local old_enabled = sway.enabled
			sway.enabled = true
			local old_spif = sway.set_player_inventory_formspec
			local spif_calls = {}
			sway.set_player_inventory_formspec = function (...)
				spif_calls[#spif_calls+1] = {...}
			end
			onjoinplayer_cb(fakeplayer)
			sway.enabled = old_enabled
			sway.set_player_inventory_formspec = old_spif
			assert.same({{fakeplayer}}, spif_calls)
			assert.equal(fakeplayer, spif_calls[1][1])
		end)
	end)
	describe("set_inventory_formspec", function ()
		it("requires at least player or context", function ()
			assert.has_error(function ()
				sway.set_player_inventory_formspec()
			end) -- Doesn't matter which error message. gpac has a good enough one.
		end)
		it("calls get_player_and_context to ensure both are gotten if possible", function ()
			local p, x = {}, {}
			local p1, x1 = {}, {} -- Doing this ensures that it's the return of gpac that is gotten later
			local old_gpac = sway.get_player_and_context
			local gpac_calls = {}
			sway.get_player_and_context = function (...)
				gpac_calls[#gpac_calls+1] = {...}
				return p1, x1
			end
			-- INFO: This is likely to break since it's a private API
			-- TODO: feature request that to be stable?
			local sf_mti = getmetatable(sway.form).__index
			local old_saif = sf_mti.set_as_inventory_for
			local saif_calls = {}
			sf_mti.set_as_inventory_for = function (...)
				saif_calls[#saif_calls+1] = {...}
			end
			sway.set_player_inventory_formspec(p,x)
			sway.get_player_and_context = old_gpac
			sf_mti.set_as_inventory_for = old_saif
			assert.equal(#gpac_calls, 1, "get_player_and_context")
			assert.equal(gpac_calls[1][1], p, "get_player_and_context ctx")
			assert.equal(gpac_calls[1][2], x, "get_player_and_context ctx")
			assert.equal(#saif_calls, 1, "set_as_inventory_for")
			-- First arg is a "self" arg, 2nd and 3rd matter
			assert.equal(saif_calls[1][2], p1, "set_as_inventory_for p")
			assert.equal(saif_calls[1][3], x1, "set_as_inventory_for x")
		end)
	end)
	describe("sway.form", function ()
		local function do_render(p,x)
			return formspec_ast.parse(sway.form:render_to_formspec_string(p, x, false))
		end
		it("calls set_context to ensure the context is set per player", function ()
			local old_sc = sway.set_context
			local sc_calls = {}
			sway.set_context = function (...)
				sc_calls[#sc_calls+1] = {...}
				error"this is a test designed to fail here"
			end
			local p, c = fakeplayer, {}
			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")
			sway.set_context = old_sc
			assert.same(sc_calls, {{p, c}}, "calls")
			assert.equal(sc_calls[1][1], p, "player")
			assert.equal(sc_calls[1][2], c, "ctx")
		end)
		it("calls flow_extras.set_wrapped_context to wrap the context", function ()
			local old_sc = sway.set_context
			sway.set_context = nilfn -- We don't want to pollute anything in these tests.
			local old_swc = flow_extras.set_wrapped_context
			local swc_calls = {}
			flow_extras.set_wrapped_context = function (c, f)
				swc_calls[#swc_calls+1] = {c, type(f)}
				error"this is a test designed to fail here"
			end
			local p, c = fakeplayer, {}
			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")
			sway.set_context = old_sc
			flow_extras.set_wrapped_context = old_swc
			assert.same(swc_calls, {{c, "function"}}, "swc calls")
			assert.equal(swc_calls[1][1], c, "swc ctx")
			assert.same(swc_calls[1][2], "function", "swc function")
		end)
		it("calls sway.get_form from inside the wrapped context", function ()
			local old_sc = sway.set_context
			sway.set_context = nilfn
			local my_ex = sway.get_form
			local gf_calls = {}
			local gf_s_ctx
			sway.get_form = function (...)
				gf_calls[#gf_calls+1] = {...}
				gf_s_ctx = sway.get_or_create_context()
				error"this is a test designed to fail here"
			end
			local p, c = fakeplayer, {}
			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")
			sway.set_context = old_sc
			sway.get_form = my_ex -- I guess the old_gf is the new_gf again 😆
			assert.same(gf_calls, {{p, c}}, "gf_calls")
			assert.equal(gf_calls[1][1], p, "gf_calls p")
			assert.equal(gf_calls[1][2], c, "gf_calls c")
			assert.equal(gf_s_ctx, c, "can get context from inside form")
		end)
		it("returns the form", function ()
			local old_sc = sway.set_context
			sway.set_context = nilfn -- We don't want to pollute anything in these tests.
			local my_ex = sway.get_form
			local form = gui.VBox{no_prepend=true, gui.Label{label="I am a label!"}}
			sway.get_form = function ()
				return form
			end
			local p, c = fakeplayer, {}
			local form_ret = do_render(p, c)
			sway.set_context = old_sc
			sway.get_form = my_ex
			assert.same({
				formspec_version = 1,
				gui.Container{
					x = .3, y = .3,
					gui.Label{
						x = 0, y = 0.2,
						label="I am a label!"
					}
				}
			}, form_ret, "the rendered form is generated from the form returned from set_wrapped_context")
		end)
		it("calls insert_prepend if no_prepend is not set in the form", function ()
			local old_sc = sway.set_context
			sway.set_context = nilfn -- We don't want to pollute anything in these tests.
			local ip = sway.insert_prepend
			local ip_calls = {}
			sway.insert_prepend = function (...)
				ip_calls[#ip_calls+1] = {...}
				return ...
			end
			local my_ex = sway.get_form
			local form = gui.VBox{no_prepend=false, gui.Label{label="I am a label!"}}
			sway.get_form = function ()
				return form
			end
			local p, c = fakeplayer, {}
			local form_ret = do_render(p, c)
			sway.set_context = old_sc
			sway.get_form = my_ex
			sway.insert_prepend = ip
			assert.same({
				formspec_version = 1,
				gui.Container{
					x = .3, y = .3,
					gui.Label{
						x = 0, y = 0.2,
						label="I am a label!"
					}
				}
			}, form_ret, "the rendered form is generated from the form returned from set_wrapped_context")
			assert.same(ip_calls, {{form}})
			assert.equal(ip_calls[1][1], form)
		end)
	end)
	-- The first horseman of bloated inventory mods, the component that forces you to use it, even when others are present.
	describe("__conqueror", function ()
		-- It is recognised by several features:
		-- It disables the one good inventory mod, whos only weakness is an affixment to the past,
		-- leaving it featureless and permanantly obsolete
		it("slays the simple one", function ()
			_G.sfinv = {}
			sway.__conqueror();
			assert.equal(type(_G.sfinv.set_player_inventory_formspec), "function")
			assert.same(
				_G.sfinv.enabled,
				false,
				"Note how sfinv has already accepted its sad fate,"..
				" the Internet Explorer of inventory mods,"..
				" forever relegated to its solitary station as the doormat.\n" ..
				"No other mod is so self-aware of its flaws than the soldier you witness here." ..
				" Unlike his foes, he listens the first time when you say, 'please move,' and dutifully does so." ..
				" He knows his sad fate. He will become disabled in the line of duty. That he still serves is honor."
			)
		end)
		-- It disables the one mod everyone seems to enjoy, genuinely adding features people take for granted, but also is
		-- known to be brittle
		it("causes the slow and ugly one to stumble", function ()
			_G.unified_inventory = {}
			sway.__conqueror();
			assert.equal(type(_G.unified_inventory.set_inventory_formspec), "function")
		end)
		-- And last, it disables the very mod that was so poorly (over)engineered, it inspired sway, a post-ironic parody of
		-- all Minetest inventory mods, mostly just ones that try to recreate the average post-millenium RPG inventory
		-- "experience." If I wanted to play Xenoblade Cronicles X, I would have purchased a Nintendo account by now.
		it("encumberes the vain one", function ()
			_G.i3 = {}
			sway.__conqueror();
			assert.equal(type(_G.i3.set_fs), "function")
		end)
		-- Perhaps it should be mentioned. There's several I haven't disabled. This is for two reasons.
		--
		-- 1. The mod is better than this mod.
		-- 2. The mod is under a licence that would prevent me from doing so (legally).
		-- 3. The mod is so unused, it's not worth the effort.
		--
		-- One of these reasons is a lie, and the other two tell only the truth. I refuse to clarify.
	end)
end)
describe("content functions", function ()
	it("insert_prepend", function ()
		-- Simple enough that a snapshot should be fine.
		local elm = {}
		sway.insert_prepend(elm)
		assert.same({
			no_prepend = true,
			bgcolor = "#0000",
			gui.StyleType{ selectors = { "list" }, props = { spacing = 0.25 } }
		}, elm)
	end)
	describe("NavGui", function ()
		it("requires fields", function ()
			assert.has_error(function ()
				sway.NavGui()
			end, "[sway] NavGui: requires field table.")
			assert.has_error(function ()
				sway.NavGui(false)
			end, "[sway] NavGui: requires field table.")
		end)
		it("requires nav_titles to be a table", function ()
			assert.has_error(function ()
				sway.NavGui{ current_idx = 1 }
			end, "[sway] NavGui: requires requires nav_titles to be a table.")
			assert.has_error(function ()
				sway.NavGui{ current_idx = 1, nav_titles = false }
			end, "[sway] NavGui: requires requires nav_titles to be a table.")
		end)
		it("requires current_idx to be a number", function ()
			assert.has_error(function ()
				sway.NavGui{ nav_titles = {} }
			end, "[sway] NavGui: requires requires current_idx to be a number.")
			assert.has_error(function ()
				sway.NavGui{ current_idx = false, nav_titles = {} }
			end, "[sway] NavGui: requires requires current_idx to be a number.")
		end)
		it("returns nil if nav_titles is empty", function ()
			local ret = sway.NavGui{ nav_titles = {}, current_idx = -1 }
			assert.same(gui.Nil{}, ret)
		end)
		it("returns nil if nav_titles is one-long", function ()
			local ret = sway.NavGui{ nav_titles = { "title" }, current_idx = 1 }
			assert.same(gui.Nil{}, ret)
		end)
		it("contains a tabheader of certian description", function ()
			local args = { nav_titles = { "title", "next page" }, current_idx = 1 }
			local match = flow_extras.search{
				tree = sway.NavGui(args),
				value = "tabheader"
			}()
			assert.truthy(match, "tabheader was found")
			assert.equal(match.name, "sway_nav_tabs")
			assert.equal(match.captions, args.nav_titles, "titles")
			assert.equal(match.current_tab, args.current_idx, "index")
			assert.truthy(match.on_event, "event")
		end)
		it("tabheader event calls set_page", function ()
			local args = { nav_titles = { "title", "next page" }, current_idx = 1 }
			local match = flow_extras.search{
				tree = sway.NavGui(args),
				value = "tabheader"
			}()
			local sp = sway.set_page
			local sp_calls = {}
			sway.set_page = function (...)
				sp_calls[#sp_calls+1] = {...}
			end
			local p, x = {}, { nav = { a = "asdfasdf" }, form = { sway_nav_tabs = "a" } }
			local ret = match.on_event(p, x)
			sway.set_page = sp
			assert.truthy(match, "tabheader was found")
			assert.is_nil(ret, "ret")
			assert.same({{p, "asdfasdf"}}, sp_calls, "all calls")
			assert.equal(sp_calls[1][1], p, "first arg")
		end)
	end)
	describe("Form", function ()
		it("requires fields", function ()
			assert.has_error(function ()
				sway.Form()
			end, "[sway] Form: requires field table.")
			assert.has_error(function ()
				sway.Form(false)
			end, "[sway] Form: requires field table.")
		end)
		it("contains NavGui and the field children but not inv", function ()
			local NG = sway.NavGui
			local NG_calls = {}
			sway.NavGui = function (...)
				NG_calls[#NG_calls+1] = {...}
				return gui.Nil{}
			end
			local IT = sway.InventoryTiles
			local IT_calls = {}
			sway.InventoryTiles = function (...)
				IT_calls[#IT_calls+1] = {...}
			end
			local gocc = sway.get_or_create_context
			sway.get_or_create_context = function ()
				return { nav_titles = {"the title"}, nav_idx = 3 }
			end
			local ret = sway.Form{ gui.Box{} }
			local match = flow_extras.search{
				tree = ret,
				value = "box"
			}()
			sway.NavGui = NG
			sway.InventoryTiles = IT
			sway.get_or_create_context = gocc
			assert.same({}, IT_calls, "IT")
			assert.truthy(match, "box")
			assert.same({{{
				nav_titles = {"the title"},
				current_idx = 3
			}}}, NG_calls, "NG")
		end)
		it("show_inv field option includes the inv and the option is not exported", function ()
			local NG = sway.NavGui
			local NG_calls = {}
			sway.NavGui = function (...)
				NG_calls[#NG_calls+1] = {...}
				return gui.Nil{}
			end
			local IT = sway.InventoryTiles
			local IT_calls = {}
			sway.InventoryTiles = function (...)
				IT_calls[#IT_calls+1] = {...}
			end
			local gocc = sway.get_or_create_context
			sway.get_or_create_context = function ()
				return { nav_titles = {"the title"}, nav_idx = 3 }
			end
			local ret = sway.Form{ show_inv = true, gui.Box{} }
			local match = flow_extras.search{
				tree = ret,
				value = "box"
			}()
			sway.NavGui = NG
			sway.InventoryTiles = IT
			sway.get_or_create_context = gocc
			assert.same({{}}, IT_calls, "IT")
			assert.truthy(match, "box")
			assert.same({{{
				nav_titles = {"the title"},
				current_idx = 3
			}}}, NG_calls, "NG")
		end)
	end)
	describe("InventoryTiles", function ()
		it("with w and h of 1, contains certian elements", function ()
			local feL = flow_extras.List
			local feL_calls = {}
			flow_extras.List = function (...)
				feL_calls[#feL_calls+1] = {...}
				return { "asdf" }
			end
			local ret = sway.InventoryTiles{ w = 1, h = 1 }
			flow_extras.List = feL
			assert.same({{{
				align_h = "center",
				inventory_location = "current_player",
				list_name = "main",
				w = 1, h = 1,
				bgimg = "sway_hb_bg.png",
				spacing = 0.25,
			}}}, feL_calls, "calls")
			assert.same(gui.VBox{
				align_v = "end",
				expand = true,
				{ "asdf" },
				gui.Nil{}
			}, ret, "ret")
		end)
		it("default w and h", function ()
			local feL = flow_extras.List
			local feL_calls = {}
			flow_extras.List = function (...)
				feL_calls[#feL_calls+1] = {...}
				return { "asdfaa", #feL_calls }
			end
			local ret = sway.InventoryTiles{}
			flow_extras.List = feL
			assert.same({
				{{
					align_h = "center",
					inventory_location = "current_player",
					list_name = "main",
					w = 8, h = 1,
					bgimg = "sway_hb_bg.png",
					spacing = 0.25,
				}},
				{{
					align_h = "center",
					inventory_location = "current_player",
					list_name = "main",
					w = 8, h = 3,
					starting_item_index = 8,
					spacing = 0.25,
				}}
			}, feL_calls, "calls")
			assert.same(gui.VBox{
				align_v = "end",
				expand = true,
				{ "asdfaa", 1 },
				{ "asdfaa", 2 }
			}, ret, "ret")
		end)
		it("falls back with fields", function ()
			assert.same(
				sway.InventoryTiles{},
				sway.InventoryTiles()
			)
		end)
	end)
	describe("get_form", function ()
		it("calls get_player_and_context", function ()
			local old_gpac = sway.get_player_and_context
			local gpac_calls = {}
			sway.get_player_and_context = function (...)
				gpac_calls[#gpac_calls+1] = {...}
				error"halt execution here to ensure this is called"
			end
			local p, x = {}, {}
			assert.has_error(function ()
				sway.get_form(p,x)
			end, "halt execution here to ensure this is called")
			sway.get_player_and_context = old_gpac
			assert.same({{p, x}}, gpac_calls, "args")
			assert.equal(p, gpac_calls[1][1], "player arg")
			assert.equal(x, gpac_calls[1][2], "ctx arg")
		end)
		it("returns result of get for found page", function ()
			local old_gpac = sway.get_player_and_context
			sway.get_player_and_context = function (...)
				return ...
			end
			local old_pu = sway.pages_ordered
			local old_p = sway.pages
			local pagename = "asdfasdf"
			local pageContent = {}
			local called = 0
			local example_page = { name = pagename, get = function ()
				called = called + 1
				return pageContent
			end }
			sway.pages_ordered = {
				example_page
			}
			sway.pages = {}
			sway.pages[pagename] = example_page
			local p, x = {}, { page = pagename }
			local ret = sway.get_form(p,x)
			sway.get_player_and_context = old_gpac
			sway.pages_ordered = old_pu
			sway.pages = old_p
			assert.equal(pageContent, ret, "returns expected page")
			assert.equal(1, called, "Called thingy")
		end)
		describe("navigation loop", function ()
			it("calls is_in_nav for all pages where it is defined, in order, in sway.pages_ordered", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				local pagename = "asdfasdf"
				sway.pages_ordered = {}
				sway.pages = {}
				local p, x = {}, { page = "doesn't have one" }
				local calls = {}
				sway.register_page("doesn't have one",{
					get = function ()
						return gui.Nil{}
					end,
				})
				for i = 1, 5 do
					sway.register_page(pagename..i,{
						get = function ()
							return gui.Nil{}
						end,
						actualOrder=i,
						is_in_nav = function (self, ip, ix)
							calls[#calls+1] = {
								order = self.actualOrder,
								ip = p == ip,
								ix = x == ix,
							}
						end
					})
				end
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				assert.same(calls, {
					{ order = 1, ip = true, ix = true},
					{ order = 2, ip = true, ix = true},
					{ order = 3, ip = true, ix = true},
					{ order = 4, ip = true, ix = true},
					{ order = 5, ip = true, ix = true},
				}, "called correctly")
			end)
			it("adds the page info if is_in_nav is undefined or returns true", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				sway.pages_ordered = {}
				sway.pages = {}
				sway.register_page("fun -> true",{
					get = function ()
						return gui.Nil{}
					end,
					is_in_nav = function () return true end
				})
				sway.register_page("fun -> false",{
					get = function ()
						return gui.Nil{}
					end,
					is_in_nav = function () return false end
				})
				sway.register_page("nothing",{
					get = function ()
						return gui.Nil{}
					end
				})
				sway.register_page("nothing else",{
					get = function ()
						return gui.Nil{}
					end,
					is_in_nav = nil
				})
				local p, x = {}, { page = "nothing else" }
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				assert.same(x, {
					nav = {
						"fun -> true",
						"nothing",
						"nothing else",
					},
					nav_titles = {},
					nav_idx = 3,
					page = "nothing else"
				})
			end)
		end)
		describe("400 pages!", function ()
			it("returns result of get for sway.page['403'] when page not found, and 403 is truthy", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				sway.pages_ordered = {}
				sway.pages = {}
				local hiddenCalled = false
				sway.register_page("hidden page",{
					get = function ()
						hiddenCalled = true
						return gui.Nil{}
					end,
					is_in_nav = function () return false end
				})
				local fourOhThreeCalled = false
				sway.register_page("403",{
					get = function ()
						fourOhThreeCalled = true
						return gui.Nil{}
					end,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local p, x = {}, { page = "hidden page" }
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "403"
				}, x)
				assert.False(hiddenCalled, "hidden called")
				assert.True(fourOhThreeCalled, "403 called")
			end)
			it("returns result of get for sway.page['404'] when page not found, and 404 is truthy", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				sway.pages_ordered = {}
				sway.pages = {}
				local fourOhThreeCalled = false
				sway.register_page("403",{
					get = function ()
						fourOhThreeCalled = true
						return gui.Nil{}
					end,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local fourOhFourCalled = false
				sway.register_page("404",{
					get = function ()
						fourOhFourCalled = true
						return gui.Nil{}
					end,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local p, x = {}, { page = "wrong page" }
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.False(fourOhThreeCalled, "403 called")
				assert.True(fourOhFourCalled, "404 called")
			end)
		end)
		describe("when page is not found and 400 error pages aren't present", function ()
			it("returns gui.Nil and logs an error if the missing page is the homepage", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				local old_mtl = minetest.log
				local mtl_calls = {}
				minetest.log = function (...)
					mtl_calls[#mtl_calls+1] = {...}
				end
				sway.pages_ordered = {}
				sway.pages = {}
				local p, x = {}, { page = "sway:crafting" }
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				minetest.log = old_mtl
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.same({{
					"error",
					"[sway] Couldn't find the requested page, '\"sway:crafting\"', which is also the home page."
				}}, mtl_calls)
			end)
			it("logs an error, changes the page to the homepage and asserts that the homepage is possible to get", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				local old_mtl = minetest.log
				local mtl_calls = {}
				minetest.log = function (...)
					mtl_calls[#mtl_calls+1] = {...}
				end
				sway.pages_ordered = {}
				sway.pages = {}
				local p, x = {}, { page = "asdf" }
				assert.has_error(function ()
					sway.get_form(p,x)
				end, "[sway] Invalid homepage")
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				minetest.log = old_mtl
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.same({{
					"warning",
					"[sway] Couldn't find '\"asdf\"' so switching to homepage."
				}}, mtl_calls)
			end)
			it("logs an error, changes the page to the homepage and re-calls get_form", function ()
				local old_gpac = sway.get_player_and_context
				sway.get_player_and_context = function (...)
					return ...
				end
				local old_po = sway.pages_ordered
				local old_p = sway.pages
				local old_mtl = minetest.log
				local mtl_calls = {}
				minetest.log = function (...)
					mtl_calls[#mtl_calls+1] = {...}
				end
				sway.pages_ordered = {}
				sway.pages = {}
				local p, x = {}, { page = "asdf" }
				local old_sp = sway.set_page
				local sp_calls = {}
				sway.set_page = function (...)
					sp_calls[#sp_calls+1] = {...}
					x.page = "sway:crafting"
				end
				sway.register_page("sway:crafting", {
					get = function ()
						return gui.Nil{}
					end
				})
				sway.get_form(p,x)
				sway.get_player_and_context = old_gpac
				sway.pages_ordered = old_po
				sway.pages = old_p
				sway.set_page = old_sp
				minetest.log = old_mtl
				assert.same({{
					"warning",
					"[sway] Couldn't find '\"asdf\"' so switching to homepage."
				}}, mtl_calls)
				assert.same({{p,"sway:crafting"}}, sp_calls)
				assert.same({
					nav = { "sway:crafting" },
					nav_titles = {},
					nav_idx = 1,
					page = "sway:crafting"
				}, x)
			end)
		end)
	end)
end)
