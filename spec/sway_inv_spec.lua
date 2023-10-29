local function nilfn() end
local function ident(v)
	return function ()
		return v
	end
end
local minetest = {
	register_on_player_receive_fields = nilfn,
	register_on_joinplayer = nilfn,
	register_on_leaveplayer = nilfn,
	register_chatcommand = nilfn,
	get_translator = ident(ident),
	is_singleplayer = ident(true),
	global_exists = ident(false),
	log = nilfn
}
local function debug(...)
	for _, item in ipairs{ ... } do
		print"{"
		for key, value in pairs(item) do
			print("", key, " = ", value)
		end
		print"}"
	end
	return ...
end
assert(debug) -- Hack to make it so I don't have to ignore that this function is usually unused.
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
dofile"../flow/init.lua"
dofile"../flow-extras/init.lua"
dofile"init.lua"
local describe, it, assert, pending, stub, before_each = describe, it, assert, pending, stub, before_each
local function fancy_stub(obj, name, callback)
	local old = obj[name]
	stub(obj, name)
	callback(old)
	obj[name] = old
end
assert(pending, "Hack to ensure pending doesn't give errors if it's not in use")
local sway, flow_extras = sway, flow_extras
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
		sway.pages_unordered = {}
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
		it("inserts name into def, puts def into pages as key and pages_unordered", function ()
			local def = { get = function () end }
			sway.register_page(testpagename, def)
			assert.equals(testpagename, def.name)
			assert.equals(def, sway.pages[testpagename])
			assert.equals(def, sway.pages_unordered[1])
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
				assert.same({ def }, sway.pages_unordered)
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
	describe("pages_unordered", function ()
		-- TODO isn't this a pointless assertion?
		it("is a table on sway", function ()
			assert.equal("table", type(sway.pages_unordered))
		end)
		it("register_page adds to this table by order registered", function ()
			local def = { get = function () end }
			sway.register_page(testpagename, def)
			local def2 = { get = function () end }
			sway.register_page(testpagename .. "1", def2)
			assert.same({ def, def2 }, sway.pages_unordered)
			assert.equal(def, sway.pages_unordered[1])
			assert.equal(def2, sway.pages_unordered[2])
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
	-- TODO do these after context
	-- TODO: Horrible names. Should be get_page_name and set_page_by_name
	describe("set_page", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.set_page))
		end)
		pending"asserts that the pagename is a string"
		-- This test actually found a bug in sfinv... It should assert before setting context.page
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
		pending"if there's an on_leave funciton it calls it"
		pending"if there's an on_enter function it calls it"
	end)
	describe("get_page", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_page))
		end)
		pending"makes a call to get the context then returns it if falsy"
		pending"if the context isn't falsy it returns the pagename"
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
