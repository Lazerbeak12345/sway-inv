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
_G.dump = function (...)
	local out = "(\n"
	for _, value in ipairs{ ... } do
		out = out .. value .. ",\n"
	end
	return out .. ")\n"
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
dofile(FORMSPEC_AST_PATH .. '/init.lua')
_G.minetest = minetest -- Must be defined after formspec_ast runs
dofile"../flow/init.lua"
dofile"../flow-extras/init.lua"
dofile"init.lua"
local describe, it, assert = describe, it, assert
local sway = sway
describe("*basics*", function ()
	it("doesn't error out when loading init.lua", function ()
		assert(true, "by the time it got here it would have failed if it didn't work")
	end)
	it("provides a global variable for it's api to go into", function ()
		assert.equal("table", type(sway), "sway is a table")
	end)
end)
