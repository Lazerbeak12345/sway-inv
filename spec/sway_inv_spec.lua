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
assert(pending, "Hack to ensure pending doesn't give errors if it's not in use")
local sway = sway
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
			stub(minetest, "log")
			sway.override_page(testpagename, {})
			assert.stub(minetest.log).was.called_with(
				"action",
				"[sway] override_page: '" .. testpagename .. "' is becoming overriden"
			)
			assert.stub(minetest.log).was.called(1)
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
			stub(minetest, "log")
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
	pending"pages"
	pending"pages_unordered"
	pending"get_homepage_name"
	pending"set_page"
	pending"get_page"
end)
