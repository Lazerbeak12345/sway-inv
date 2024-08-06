-- TODO: rewrite this file so a dependent mod developer can import this library as integration code. Once that's done
-- add it to the FAQ in the README
-- NOTE: I don't NEED to do it this way, but it minimises warnings
local busted = require"busted"

local before_each = busted.before_each
local describe = busted.describe
local it = busted.it
local pending = busted.pending

local assert = busted.assert

---@class spycalls
---@field vals table<number, unknown>

---@generic T:function
---@class spy<T>
---@field new fun(spied:`T`):spy<`T`>
---@field on fun(table:table<string, `T`|any>, name:string):spy<`T`>
---@field clear fun()
---@field revert fun()
---@field calls table<number, spycalls>
local spy = busted.spy
---@generic T:function
---@class stub<T>:spy<T>
---@overload fun(table:table<string, `T`|any>, name:string|nil):stub<`T`>
local stub = busted.stub

local match = busted.match

-- TODO: contribute this to busted if I end up liking it?
--
---@class Agent:spy
--- An agent is like a spy, but is replaced with a function that does something specific.
local Agent = {}
---Construct an agent
function Agent:new(tb, key, replacement)
	local o = {
		_old = tb[key],
		_replacement = spy.new(replacement),
		_revert = function (old)
			tb[key] = old
		end,
	}
	setmetatable(o, self)
	return o
end
function Agent:__index(key)
	return Agent[key] or rawget(self, "_replacement")[key]
end
function Agent:__call(...)
	return rawget(self, "_replacement")(...)
end
function Agent:revert()
	rawget(self, "_revert")(rawget(self, "_old"))
	return rawget(self, "_replacement"):revert()
end
local function agent(tb, key, replacement)
	local a = Agent:new(tb, key, replacement)
	tb[key] = a
	return a
end
local function set_agent(state, arguments)
	state.payload = arguments[1]
	state.failure_message = arguments[2]
end
assert:register("modifier", "agent", set_agent)

local function nilfn(...) local _={...} end -- By saving the args here, we get rid of a TON of false positive warnings
local function ident(v)
	return function (...)
		local _ = {...}
		return v
	end
end
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

local minetest = {
	register_on_player_receive_fields = nilfn,
	register_chatcommand = nilfn,
	get_translator = ident(ident),
	is_singleplayer = ident(true),
	global_exists = function (name)
		return _G[name] ~= nil
	end,
	---@type spy
	register_on_leaveplayer = spy.new(nilfn),
	---@type spy
	register_on_joinplayer = spy.new(nilfn),
	---@type spy
	register_on_mods_loaded = spy.new(nilfn),
	get_player_information = ident{},
	---@type spy
	log = spy.new(nilfn),
}
local onleaveplayer_cb = function (...)
	for _,call in ipairs(minetest.register_on_leaveplayer.calls) do
		call.vals[1](...)
	end
end
local onjoinplayer_cb = function (...)
	for _,call in ipairs(minetest.register_on_joinplayer.calls) do
		call.vals[1](...)
	end
end
local onmodloaded_cb = function (...)
	for _,call in ipairs(minetest.register_on_mods_loaded.calls) do
		call.vals[1](...)
	end
end
local FORMSPEC_AST_PATH = '../formspec_ast'
_G.FORMSPEC_AST_PATH = FORMSPEC_AST_PATH
function minetest.get_modpath(modname)
	if modname == "flow" then return "../flow" end
	if modname == "formspec_ast" then return FORMSPEC_AST_PATH end
	if modname == "flow_extras" then return "../flow-extras" end
	assert(modname == "sway", "modname must be sway. was " .. modname)
	return "."
end
_G.formspec_ast = {}
dofile(FORMSPEC_AST_PATH .. '/init.lua')
_G.minetest = minetest -- Must be defined after formspec_ast runs
_G.flow = {}
dofile"../flow/init.lua"
_G.flow_extras = {}
dofile"../flow-extras/init.lua"
dofile"init.lua"
local default_pages = sway.pages
--local default_pages_ordered = sway.pages_ordered
local gui = flow.widgets
before_each(function()
	sway.pages = {}
	sway.pages_ordered = {}
	sway.enabled = true
end)
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

			sway.override_page(testpagename, {})

			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] override_page: '" .. testpagename .. "' is becoming overriden"
			)
			assert.spy(minetest.log).was.called(1)
			minetest.log:clear()
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
			sway.override_page(testpagename, override)
			assert.same({
				["sway:test2"] = def,
			}, sway.pages)
			assert.same({ def }, sway.pages_ordered)
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] override_page: '" .. testpagename .. "' is becoming renamed to 'sway:test2'"
			)
			minetest.log:clear()
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
		-- TODO: isn't this a pointless assertion?
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
			agent(sway, "get_homepage_name", ident(testpagename))
			assert.same(testpagename, sway.get_homepage_name{}) -- This table is a mock of the player api
			sway.get_homepage_name:revert()
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
			local ctx = {}
			agent(sway, "get_or_create_context", ident(ctx))
			assert.has_error(function ()
				sway.set_page({}, "fake:page")
			end, "[sway] set_page: Page not found: 'fake:page'")
			assert.same({}, ctx)
			sway.get_or_create_context:revert()
		end)
		it("if the newpage is valid, calls set_player_inventory_formspec", function ()
			local ctx = {}
			local player = {}
			sway.pages = { ["real:page"]={} }
			agent(sway, "get_or_create_context", ident(ctx))
			stub(sway, "set_player_inventory_formspec")

			sway.set_page(player, "real:page")

			assert.stub(sway.set_player_inventory_formspec).was.called(1)
			assert.stub(sway.set_player_inventory_formspec).was.called_with(player, ctx)
			assert.same({page = "real:page"}, ctx, "context")
			sway.get_or_create_context:revert()
			sway.set_player_inventory_formspec:revert()
		end)
		it("if there's an on_leave function it calls it", function ()
			-- TODO: should I use test composition for these tests? They're nearly exactly the same.
			local ctx = {page = "old:page"}
			local player = {name="asdfasdf"}
			sway.pages = {
				["old:page"]={title="asdfasdf"},
				["real:page"]={}
			}
			---@type spy
			local ol = stub(sway.pages["old:page"], "on_leave")
			agent(sway, "get_or_create_context", ident(ctx))
			stub(sway, "set_player_inventory_formspec")

			sway.set_page(player, "real:page")

			sway.get_or_create_context:revert()
			assert.stub(sway.set_player_inventory_formspec).was.called(1)
			assert.stub(sway.set_player_inventory_formspec).was.called_with(player, ctx)
			sway.set_player_inventory_formspec:revert()

			assert.same({page = "real:page"}, ctx, "context")

			assert.stub(ol).was.called(1)
			assert.stub(ol).was.called_with(sway.pages["old:page"], player, { page = "old:page" })
			ol:revert()
		end)
		it("on_leave is not called if the page is not found", function ()
			local ctx = {page = "old:page"}
			sway.pages = { ["old:page"]={} }
			---@type stub
			local ol = stub(sway.pages["old:page"], "on_leave")
			agent(sway, "get_or_create_context", ident(ctx))

			assert.has_error(function ()
				sway.set_page({}, "fake:page")
			end, "[sway] set_page: Page not found: 'fake:page'")

			sway.get_or_create_context:revert()
			assert.same({ page = "old:page" }, ctx, "context")
			assert.stub(ol).was.not_called()
			ol:revert()
		end)
		it("if there's an on_enter function it calls it", function ()
			local ctx = {}
			local player = {}
			sway.pages = {
				["real:page"] = {
					title = "the real page"
				}
			}
			---@type stub
			local oe = stub(sway.pages["real:page"],"on_enter")
			agent(sway, "get_or_create_context", ident(ctx))
			stub(sway, "set_player_inventory_formspec")

			sway.set_page(player, "real:page")

			sway.get_or_create_context:revert()

			assert.same({page = "real:page"}, ctx, "context")

			assert.stub(sway.set_player_inventory_formspec).was.called(1)
			assert.stub(sway.set_player_inventory_formspec).was.called_with(player, ctx)
			sway.set_player_inventory_formspec:revert()

			assert.stub(oe).was.called(1)
			assert.stub(oe).was.called_with(sway.pages["real:page"], player, { page = "real:page" })
			oe:revert()
		end)
	end)
	describe("get_page", function ()
		it("is a function on sway", function ()
			assert.same("function", type(sway.get_page))
		end)
		it("makes a call to get the context then returns it if falsy", function ()
			local ctx = { page = "page:name" }
			local player = {234234}
			agent(sway, "get_or_create_context", ident(ctx))
			local ret = sway.get_page(player)
			assert.agent(sway.get_or_create_context).was.called(1)
			assert.agent(sway.get_or_create_context).was.called_with(player)
			assert.same(ret, "page:name", "return value")
			sway.get_or_create_context:revert()
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
			minetest.log:clear() -- TODO: this is only needed because of a buggy test elsewhere
			sway.set_context(mock_playerref)
			-- assert that it was logged to be deleted
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] set_context: deleting context for 'lazerbeak12345'"
			)
			assert.spy(minetest.log).was.called(1)
			sway.get_or_create_context(mock_playerref)
			-- assert that getting the context causes a new log item that it was created
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
			)
			assert.spy(minetest.log).was.called(2)
			-- delete it again to keep state clean. We know this works because we just asserted that it does.
			sway.set_context(mock_playerref)
			minetest.log:clear()
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
		-- TODO: this should be multiple, smaller tests
		it("if context can't be found create a new one", function ()
			-- Clean the state
			minetest.log:clear() -- TODO: this is only needed because of a buggy test elsewhere
			sway.set_context(mock_playerref)
			local ctx = sway.get_or_create_context(mock_playerref)
			assert.truthy(ctx, "It exsists at first.")
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
			)
			-- Clean the state again
			minetest.log:clear() -- TODO: this is only needed because of a buggy test elsewhere
			sway.set_context(mock_playerref)
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] set_context: deleting context for 'lazerbeak12345'"
			)
			local old_ctx = ctx
			ctx = sway.get_or_create_context(mock_playerref)
			assert.spy(minetest.log).was.called_with(
				"action",
				"[sway] get_or_create_context: creating new context for 'lazerbeak12345'"
			)
			assert.truthy(ctx, "It still exsists")
			assert.are_not.equal(ctx, old_ctx)
			-- Clean the state at the end
			sway.set_context(mock_playerref)
			minetest.log:clear()
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
			local player, i_context = {}, {}

			spy.on(sway, "get_or_create_context")
			---@type stub
			local gpbn = stub(minetest, "get_player_by_name")

			local r_player, r_context
			flow_extras.set_wrapped_context(i_context, function ()
				r_player, r_context = sway.get_player_and_context(player)
			end)

			assert.equals(player, r_player, "player is equal")
			assert.equals(i_context, r_context, "context is equal")

			assert.spy(sway.get_or_create_context).was.called(1)
			assert.spy(sway.get_or_create_context).was.called_with(player)
			sway.get_or_create_context:revert()

			assert.stub(gpbn).was.not_called()
			gpbn:revert()
		end)
		it("if only the context is provided, return the player referenced by the context", function ()
			local i_player, context = {}, {
				player_name = "lazerbeak12345"
			}

			---@type Agent
			local gpbn = agent(minetest, "get_player_by_name", ident(i_player))

			local r_player, r_context = sway.get_player_and_context(nil, context)

			assert.equals(i_player, r_player)
			assert.equals(context, r_context)

			assert.agent(gpbn).was.called(1)
			assert.agent(gpbn).was.called_with"lazerbeak12345"
			gpbn:revert()
		end)
		it("if neither args are provided, call get_or_create_context with nothing", function ()
			local i_player, i_context = {}, {
				player_name = "lazerbeak12345"
			}

			spy.on(sway, "get_or_create_context")
			---@type Agent
			local gpbn = agent(minetest, "get_player_by_name", ident(i_player))

			local r_player, r_context
			flow_extras.set_wrapped_context(i_context, function ()
				r_player, r_context = sway.get_player_and_context()
			end)

			assert.same(i_player, r_player, "player is equal")
			assert.same(i_context, r_context, "context is equal")

			assert.spy(sway.get_or_create_context).was.called(1)
			assert.spy(sway.get_or_create_context).was.called_with(nil)
			sway.get_or_create_context:revert()

			assert.agent(gpbn).was.called(1)
			assert.agent(gpbn).was.called_with"lazerbeak12345"
			gpbn:revert()
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

		agent(crafting, "CraftingRow", function (_, ...)
			return gui.VBox{ name = "crow", ... }
		end)
		agent(sway, "Form", function (table)
			table.name = "form"
			return gui.VBox(table)
		end)

		local render = get(crafting)

		local form = flow_extras.search{
			tree = render,
			key = "name",
			value = "form",
			check_root = true
		}()

		sway.Form:revert()
		assert.truthy(form, "Contains Form")
		assert.truthy(flow_extras.search{
			tree = form,
			key = "name",
			value = "crow",
		}(), "contains crafting row")

		assert.agent(crafting.CraftingRow).was.called(1)
		assert.agent(crafting.CraftingRow).was.called_with(crafting)
		crafting.CraftingRow:revert()
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
		pending"if it is set to false, sway does nothing"
	end)
	local fakeplayer = {get_player_name=ident"fakeplayer"}
	describe("on_leaveplayer", function ()
		it("calls set_context", function ()
			stub(sway, "set_context")

			onleaveplayer_cb(fakeplayer)

			assert.stub(sway.set_context).was.called(1)
			assert.stub(sway.set_context).was.called_with(fakeplayer)
			sway.set_context:revert()
		end)
	end)
	describe("on_joinplayer", function ()
		it("if sway is disabled, the callback does nothing", function ()
			sway.enabled = false
			spy.on(sway, "set_player_inventory_formspec")
			onjoinplayer_cb(fakeplayer)
			assert.spy(sway.set_player_inventory_formspec).was.not_called()
			sway.set_player_inventory_formspec:revert()
		end)
		it("if sway is enabled, it calls sway.set_player_inventory_formspec", function ()
			sway.enabled = true
			stub(sway, "set_player_inventory_formspec")
			onjoinplayer_cb(fakeplayer)
			assert.stub(sway.set_player_inventory_formspec).was.called(1)
			assert.stub(sway.set_player_inventory_formspec).was.called_with(fakeplayer)
			sway.set_player_inventory_formspec:revert()
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
			local gpac = agent(sway, "get_player_and_context", function ()
				return p1, x1
			end)
			-- INFO: This is likely to break since it's a private API
			-- TODO: feature request that to be stable?
			local sf_mti = getmetatable(sway.form).__index
			local saif_calls = {}
			agent(sf_mti, "set_as_inventory_for", function (...)
				saif_calls[#saif_calls+1] = {...}
			end)

			sway.set_player_inventory_formspec(p,x)

			assert.agent(gpac).was.called(1)
			assert.agent(gpac).was.called_with(p, x)
			gpac:revert()

			assert.agent(sf_mti.set_as_inventory_for).was.called(1)
			-- First arg is a "self" arg, 2nd and 3rd matter
			assert.equal(saif_calls[1][2], p1, "set_as_inventory_for p")
			assert.equal(saif_calls[1][3], x1, "set_as_inventory_for x")
			sf_mti.set_as_inventory_for:revert()
		end)
	end)
	describe("sway.form", function ()
		local function do_render(p,x)
			return formspec_ast.parse(sway.form:render_to_formspec_string(p, x, false))
		end
		it("calls set_context to ensure the context is set per player", function ()
			local p, c = fakeplayer, {}
			agent(sway, "set_context", function ()
				error"this is a test designed to fail here"
			end)

			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")

			assert.agent(sway.set_context).was.called(1)
			assert.agent(sway.set_context).was.called_with(p, c)
			sway.set_context:revert()
		end)
		it("calls flow_extras.set_wrapped_context to wrap the context", function ()
			local p, c = fakeplayer, {}
			stub(sway,"set_context") -- We don't want to pollute anything in these tests.
			agent(flow_extras, "set_wrapped_context", function ()
				error"this is a test designed to fail here"
			end)

			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")

			sway.set_context:revert()
			assert.agent(flow_extras.set_wrapped_context).was.called(1)
			assert.agent(flow_extras.set_wrapped_context).was.called_with(c, match.is_function())
			flow_extras.set_wrapped_context:revert()
		end)
		it("calls sway.get_form from inside the wrapped context", function ()
			local p, c = fakeplayer, {}
			stub(sway,"set_context") -- We don't want to pollute anything in these tests.
			local ctx_from_inside_get_form
			agent(sway, "get_form", function ()
				ctx_from_inside_get_form = sway.get_or_create_context()
				error"this is a test designed to fail here"
			end)

			assert.has_error(function ()
				do_render(p, c)
			end, "this is a test designed to fail here")

			sway.set_context:revert()
			assert.equal(ctx_from_inside_get_form, c, "can get context from inside form")
			assert.agent(sway.get_form).was.called(1)
			assert.agent(sway.get_form).was.called_with(p, c)
			sway.get_form:revert()
		end)
		it("returns the form", function ()
			local p, c = fakeplayer, {}
			local form = gui.VBox{no_prepend=true, gui.Label{label="I am a label!"}}
			stub(sway,"set_context") -- We don't want to pollute anything in these tests.
			agent(sway, "get_form", ident(form))

			local form_ret = do_render(p, c)

			sway.set_context:revert()
			sway.get_form:revert()
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
			local form = gui.VBox{no_prepend=false, gui.Label{label="I am a label!"}}
			stub(sway,"set_context") -- We don't want to pollute anything in these tests.
			local ip_calls = {}
			agent(sway, "insert_prepend", function (...)
				ip_calls[#ip_calls+1] = {...}
				return ...
			end)
			agent(sway, "get_form", ident(form))
			local p, c = fakeplayer, {}

			local form_ret = do_render(p, c)

			sway.set_context:revert()
			sway.get_form:revert()
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
			assert.agent(sway.insert_prepend).was.called(1)
			assert.same(ip_calls, {{form}})
			assert.equal(ip_calls[1][1], form)
			sway.insert_prepend:revert()
		end)
	end)
	-- The first horseman of bloated inventory mods, the component that forces you to use it, even when others are present.
	describe("__conqueror", function ()
		-- It is recognised by several features:
		-- It disables the one good inventory mod, whos only weakness is an affixment to the past,
		-- leaving it featureless and permanantly obsolete
		it("slays the simple one", function ()
			_G.sfinv = {}
			onmodloaded_cb()
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
			onmodloaded_cb()
			assert.equal(type(_G.unified_inventory.set_inventory_formspec), "function")
		end)
		-- And last, it complains about the very mod that was so poorly (over)engineered, it inspired sway, a post-ironic
		-- parody of all Minetest inventory mods, mostly just ones that try to recreate the average post-millenium RPG
		-- inventory "experience." If I wanted to play Xenoblade Cronicles X, I would have purchased a Nintendo account by
		-- now.
		--
		-- On another note, it's rather fitting that it's impossible to disable the mod anyway.
		it("complains about the vain one", function ()
			_G.i3 = {}
			assert.has_error(function ()
				onmodloaded_cb()
			end)
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
			local search_result = flow_extras.search{
				tree = sway.NavGui(args),
				value = "tabheader"
			}()
			assert.truthy(search_result, "tabheader was found")
			assert.equal(search_result.name, "sway_nav_tabs")
			assert.equal(search_result.captions, args.nav_titles, "titles")
			assert.equal(search_result.current_tab, args.current_idx, "index")
			assert.truthy(search_result.on_event, "event")
		end)
		it("tabheader event calls set_page", function ()
			local p, x = {}, { nav = { a = "asdfasdf" }, form = { sway_nav_tabs = "a" } }
			stub(sway, "set_page")

			local search_result = flow_extras.search{
				tree = sway.NavGui{ nav_titles = { "title", "next page" }, current_idx = 1 },
				value = "tabheader"
			}()
			assert.truthy(search_result, "tabheader was found")

			local ret = search_result.on_event(p, x)

			assert.is_nil(ret, "ret")
			assert.stub(sway.set_page).was.called(1)
			assert.stub(sway.set_page).was.called_with(p, "asdfasdf")
			sway.set_page:revert()
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
			agent(sway, "NavGui", ident(gui.Nil{}))
			stub(sway, "InventoryTiles")
			agent(sway, "get_or_create_context", ident{ nav_titles = {"the title"}, nav_idx = 3 })

			local search_result = flow_extras.search{
				tree = sway.Form{ gui.Box{} },
				value = "box"
			}()

			sway.get_or_create_context:revert()

			assert.truthy(search_result, "box")

			assert.agent(sway.NavGui).was.called(1)
			assert.agent(sway.NavGui).was.called_with{
				nav_titles = {"the title"},
				current_idx = 3
			}
			sway.NavGui:revert()

			assert.stub(sway.InventoryTiles).was.not_called()
			sway.InventoryTiles:revert()
		end)
		it("show_inv field option includes the inv and the option is not exported", function ()
			agent(sway, "NavGui", ident(gui.Nil{}))
			stub(sway, "InventoryTiles")
			agent(sway, "get_or_create_context", ident{ nav_titles = {"the title"}, nav_idx = 3 })

			local search_result = flow_extras.search{
				tree = sway.Form{ show_inv = true, gui.Box{} },
				value = "box"
			}()

			sway.get_or_create_context:revert()

			assert.truthy(search_result, "box")

			assert.agent(sway.NavGui).was.called(1)
			assert.agent(sway.NavGui).was.called_with{
				nav_titles = {"the title"},
				current_idx = 3
			}
			sway.NavGui:revert()

			assert.stub(sway.InventoryTiles).was.called(1)
			assert.stub(sway.InventoryTiles).was.called_with()
			sway.InventoryTiles:revert()
		end)
	end)
	describe("InventoryTiles", function ()
		it("with w and h of 1, contains certian elements", function ()
			agent(flow_extras, "List", ident{ "asdf" })

			local ret = sway.InventoryTiles{ w = 1, h = 1 }

			assert.agent(flow_extras.List).was.called(1)
			assert.agent(flow_extras.List).was.called_with{
				align_h = "center",
				inventory_location = "current_player",
				list_name = "main",
				w = 1, h = 1,
				bgimg = "sway_hb_bg.png",
				spacing = 0.25,
			}
			flow_extras.List:revert()

			assert.same(gui.VBox{
				align_v = "end",
				expand = true,
				{ "asdf" },
				gui.Nil{}
			}, ret, "ret")
		end)
		it("default w and h", function ()
			local feL_call_count = 0
			agent(flow_extras, "List", function ()
				feL_call_count = feL_call_count + 1
				return { "asdfaa", feL_call_count }
			end)

			local ret = sway.InventoryTiles{}

			assert.agent(flow_extras.List).was.called(2)
			assert.agent(flow_extras.List).was.called_with{
				align_h = "center",
				inventory_location = "current_player",
				list_name = "main",
				w = 8, h = 1,
				bgimg = "sway_hb_bg.png",
				spacing = 0.25,
			}
			assert.agent(flow_extras.List).was.called_with{
				align_h = "center",
				inventory_location = "current_player",
				list_name = "main",
				w = 8, h = 3,
				starting_item_index = 8,
				spacing = 0.25,
			}
			flow_extras.List:revert()

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
			local p, x = {name="player"}, {}
			local gpac = agent(sway, "get_player_and_context", function ()
				error"halt execution here to ensure this is called"
			end)

			assert.has_error(function ()
				sway.get_form(p,x)
			end, "halt execution here to ensure this is called")

			assert.agent(gpac).was.called(1)
			assert.agent(gpac).was.called_with(p, x)
			gpac:revert()
		end)
		it("returns result of get for found page", function ()
			local pagename = "asdfasdf"
			local p, x = {}, { page = pagename }
			local example_page = { get = nilfn }
			sway.register_page(pagename, example_page)
			local pageContent = gui.Label{ label = "asdfasfdasfdasfd" }
			agent(example_page, "get", ident(pageContent))
			local gpac = agent(sway, "get_player_and_context", function (...)
				return ...
			end)

			local ret = sway.get_form(p,x)

			gpac:revert()
			assert.equal(pageContent, ret, "returns expected page")
			assert.agent(example_page.get).was.called(1)
		end)
		describe("navigation loop", function ()
			it("calls is_in_nav for all pages where it is defined, in order, in sway.pages_ordered", function ()
				local pagename = "asdfasdf"
				local p, x = {}, { page = "doesn't have one" }
				local order = {}
				sway.register_page("doesn't have one",{
					get = function ()
						return gui.Nil{}
					end,
				})
				spy.on(sway.pages["doesn't have one"], "get")
				local pages = {}
				for i = 1, 5 do
					local page = {
						get = function ()
							return gui.Nil{}
						end,
						actualOrder=i,
						is_in_nav = function (self)
							order[#order+1] = self.actualOrder
						end
					}
					sway.register_page(pagename..i, page)
					spy.on(page, "get")
					spy.on(page, "is_in_nav")
					pages[#pages+1] = page
				end
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				sway.get_form(p,x)

				gpac:revert()
				assert.same(order, { 1, 2, 3, 4, 5 }, "called correctly")
				for i = 1, 5 do
					assert.spy(pages[i].get).was.not_called()
					assert.spy(pages[i].is_in_nav).was.called(1)
					assert.spy(pages[i].is_in_nav).was.called_with(pages[i], p, { page = "doesn't have one" })
				end
				assert.spy(sway.pages["doesn't have one"].get).was.called(1)
			end)
			it("adds the page info if is_in_nav is undefined or returns true", function ()
				local p, x = {}, { page = "nothing else" }
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
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				sway.get_form(p,x)

				gpac:revert()
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
				local p, x = {}, { page = "hidden page" }
				local retNil = ident(gui.Nil{})
				sway.register_page("hidden page",{
					get = retNil,
					is_in_nav = function () return false end
				})
				local hidden = spy.on(sway.pages["hidden page"], "get")
				sway.register_page("403",{
					get = retNil,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local fourOhThree = spy.on(sway.pages["403"], "get")
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				sway.get_form(p,x)

				gpac:revert()
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "403"
				}, x)
				assert.spy(hidden).was.not_called()
				assert.spy(fourOhThree).was.called()
			end)
			it("returns result of get for sway.page['404'] when page not found, and 404 is truthy", function ()
				local p, x = {}, { page = "wrong page" }
				local retNil = ident(gui.Nil{})
				sway.register_page("403",{
					get = retNil,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local fourOhThree = spy.on(sway.pages["403"], "get")
				sway.register_page("404",{
					get = retNil,
					-- Most 404 pages would be hidden as well.
					is_in_nav = function () return false end
				})
				local fourOhFour = spy.on(sway.pages["404"], "get")
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				sway.get_form(p,x)

				gpac:revert()
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.spy(fourOhThree).was.not_called()
				assert.spy(fourOhFour).was.called()
			end)
		end)
		describe("when page is not found and 400 error pages aren't present", function ()
			it("returns gui.Nil and logs an error if the missing page is the homepage", function ()
				local p, x = {}, { page = "sway:crafting" }
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				sway.get_form(p,x)

				gpac:revert()
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.spy(minetest.log).was.called_with(
					"error",
					"[sway] Couldn't find the requested page, '\"sway:crafting\"', which is also the home page."
				)
				minetest.log:clear()
			end)
			it("logs an error, changes the page to the homepage and asserts that the homepage is possible to get", function ()
				local p, x = {}, { page = "asdf" }
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)

				assert.has_error(function ()
					sway.get_form(p,x)
				end, "[sway] Invalid homepage")

				gpac:revert()
				assert.same({
					nav = { },
					nav_titles = {},
					nav_idx = -1,
					page = "404"
				}, x)
				assert.spy(minetest.log).was.called_with(
					"warning",
					"[sway] Couldn't find '\"asdf\"' so switching to homepage."
				)
				minetest.log:clear()
			end)
			it("logs an error, changes the page to the homepage and re-calls get_form", function ()
				local p, x = {}, { page = "asdf" }
				local gpac = agent(sway, "get_player_and_context", function (...)
					return ...
				end)
				agent(sway, "set_page", function ()
					x.page = "sway:crafting"
				end)
				sway.register_page("sway:crafting", {
					get = ident(gui.Nil{})
				})

				sway.get_form(p,x)

				gpac:revert()
				assert.spy(minetest.log).was.called_with(
					"warning",
					"[sway] Couldn't find '\"asdf\"' so switching to homepage."
				)
				minetest.log:clear()

				assert.agent(sway.set_page).was.called(1)
				assert.agent(sway.set_page).was.called_with(p, "sway:crafting")
				sway.set_page:revert()

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
