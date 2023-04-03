# Sway is a experimental beyond-next-gen inventory for minetest

```text
 ____                                      ______
/\  _`\                                   /\__  _\
\ \,\L\_\  __  __  __     __     __  __   \/_/\ \/     ___   __  __
 \/_\__ \ /\ \/\ \/\ \  /'__`\  /\ \/\ \     \ \ \   /' _ `\/\ \/\ \
   /\ \L\ \ \ \_/ \_/ \/\ \L\.\_\ \ \_\ \     \_\ \__/\ \/\ \ \ \_/ |__
   \ `\____\ \___x___/'\ \__/.\_\\/`____ \    /\_____\ \_\ \_\ \___//\_\
    \/_____/\/__//__/   \/__/\/_/ `/___/> \   \/_____/\/_/\/_/\/__/ \/_/
                                     /\___/
                                     \/__/
```

<!-- Above generated via `echo "Sway Inv." | figlet -f larry3d`. `larry3d` font is from the
official figlet "contributed" collection. `pepper` from the same collection was a close 2nd. -->

I'll be making lots of changes, so expect almost all of the text or image documentation to be _very_ outdated. I'll try to keep as much API compatiblity as I can.

In the meantime, checkout [i3](https://github.com/minetest-mods/i3). It's almost certianly what you want to use till this starts working.

## Long-term Goals:

- I3 is awesome, but not simple.
	- 10 × as many LOC as sfinv. (pending measurment comparison to this mod, ofc so this isn't a truly fair metric)
	- The type of mods that I find people asking for aren't possible in _any_ inventory. I3 adds many of this type of feature - at the cost of core code complexity.
- Use a _slightly_ different approach for generating the formspecs from I3. This approach gives a very rich API.
- Use a modpack to reach feature-parity with I3.
	- It's also under MIT so I can "steal" code, but I'll try my very best to give proper attribution, making use of `Co-authored-by` and `git blame`.
- Make great use of modpacks
	- Somehow make use of modpacks to provide API gateways so mods relying on X api should be able to work in this inventory.
	- Feature modules. Progressive mode and other features will be modules.
- Support multiple games. (I think most inventory mods do, but I want to be extra sure)

> Why is this forked from sfinv?

- Sfinv is simple enough in its core that I can spend more time porting and less time worrying about what features really matter.
- The structure should be mostly the same
- I want the core mod to be just as simple as sfinv.

> Why call it "Sway" or "sway-inv?"

That'll make more sense in due time. 😉 It's a perfect name, trust me.

Everything below is subject to become outdated until I reach my minimum goals.

---

![SFINV Screeny](screenshot.png)

A cleaner, simpler solution to having an advanced inventory in Minetest.

Written by rubenwardy.\\
License: MIT

* sfinv_crafting_arrow.png - by paramat, derived from a texture by BlockMen (CC BY-SA 3.0).

## API

It is recommended that you read this link for a good introduction to the sfinv API
by its author: https://rubenwardy.com/minetest_modding_book/en/players/sfinv.html

### sfinv Methods

**Pages**

* sfinv.set_page(player, pagename) - changes the page
* sfinv.get_homepage_name(player) - get the page name of the first page to show to a player
* sfinv.register_page(name, def) - register a page, see section below
* sfinv.override_page(name, def) - overrides fields of an page registered with register_page.
    * Note: Page must already be defined, (opt)depend on the mod defining it.
* sfinv.set_player_inventory_formspec(player) - (re)builds page formspec
             and calls set_inventory_formspec().
* sfinv.get_formspec(player, context) - builds current page's formspec

**Contexts**

* sfinv.get_or_create_context(player) - gets the player's context
* sfinv.set_context(player, context)

**Theming**

* sfinv.make_formspec(player, context, content, show_inv, size) - adds a theme to a formspec
    * show_inv, defaults to false. Whether to show the player's main inventory
    * size, defaults to `size[8,8.6]` if not specified
* sfinv.get_nav_fs(player, context, nav, current_idx) - creates tabheader or ""

### sfinv Members

* pages - table of pages[pagename] = def
* pages_unordered - array table of pages in order of addition (used to build navigation tabs).
* contexts - contexts[playername] = player_context
* enabled - set to false to disable. Good for inventory rehaul mods like unified inventory

### Context

A table with these keys:

* page - current page name
* nav - a list of page names
* nav_titles - a list of page titles
* nav_idx - current nav index (in nav and nav_titles)
* any thing you want to store
    * sfinv will clear the stored data on log out / log in

### sfinv.register_page

sfinv.register_page(name, def)

def is a table containing:

* `title` - human readable page name (required)
* `get(self, player, context)` - returns a formspec string. See formspec variables. (required)
* `is_in_nav(self, player, context)` - return true to show in the navigation (the tab header, by default)
* `on_player_receive_fields(self, player, context, fields)` - on formspec submit.
* `on_enter(self, player, context)` - called when the player changes pages, usually using the tabs.
* `on_leave(self, player, context)` - when leaving this page to go to another, called before other's on_enter

### get formspec

Use sfinv.make_formspec to apply a layout:

	return sfinv.make_formspec(player, context, [[
		list[current_player;craft;1.75,0.5;3,3;]
		list[current_player;craftpreview;5.75,1.5;1,1;]
		image[4.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]
		listring[current_player;main]
		listring[current_player;craft]
		image[0,4.25;1,1;gui_hb_bg.png]
		image[1,4.25;1,1;gui_hb_bg.png]
		image[2,4.25;1,1;gui_hb_bg.png]
		image[3,4.25;1,1;gui_hb_bg.png]
		image[4,4.25;1,1;gui_hb_bg.png]
		image[5,4.25;1,1;gui_hb_bg.png]
		image[6,4.25;1,1;gui_hb_bg.png]
		image[7,4.25;1,1;gui_hb_bg.png]
	]], true)

See above (methods section) for more options.

### Customising themes

Simply override this function to change the navigation:

	function sfinv.get_nav_fs(player, context, nav, current_idx)
		return "navformspec"
	end

And override this function to change the layout:

	function sfinv.make_formspec(player, context, content, show_inv, size)
		local tmp = {
			size or "size[8,8.6]",
			theme_main,
			sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
			content
		}
		if show_inv then
			tmp[4] = theme_inv
		end
		return table.concat(tmp, "")
	end
