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

> Above generated via `echo "Sway Inv." | figlet -f larry3d`. `larry3d` font is from the
> official figlet "contributed" collection. `pepper` from the same collection was a close 2nd.

> Lots of changes underway! Not ready yet.
> 
> In the meantime, checkout [i3](https://github.com/minetest-mods/i3). It's almost certianly what you want to use till this starts working.

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

![Sway Screenshot](screenshot.png)

A cleaner, simpler solution to having an advanced inventory in Minetest.

Written by rubenwardy.\\
Modified by Lazerbeak12345 for flow.\\
Code License: MIT

* `sway_crafting_arrow.png` - renamed from a texture by paramat, derived from a texture by BlockMen (CC BY-SA 3.0).
* `sway_hb_bg.png` - renamed from `gui_hb_bg.png`, a texture by BlockMen (CC BY-SA 3.0)
* `sway_bg_full.png` - renamed from `i3_bg_full.png`, a texture by paramat (CC BY-SA 3.0)

<!--TODO Include CC BY-SA 3.0 licence text-->

## API

Based on sfinv, but not compatible with sfinv.

### sway Methods

**Pages**

* sway.set_page(player, pagename) - changes the page
* sway.get_homepage_name(player) - get the page name of the first page to show to a player
* sway.register_page(name, def) - register a page, see section below
* sway.override_page(name, def) - overrides fields of an page registered with register_page.
    * Note: Page must already be defined, (opt)depend on the mod defining it.
* sway.set_player_inventory_formspec(player) - (re)builds page formspec

**Contexts**

> Might be deprecated in the future

* sway.get_or_create_context(player) - gets the player's context
* sway.set_context(player, context)

**Theming**

* sway.make_form(player, context, content, show_inv, size) - adds a theme to a form
    * show_inv, defaults to false. Whether to show the player's main inventory
    * size, defaults to `{ w = 8, h = 8.6 }` if not specified
* sway.get_nav(player, context, nav, current_idx) - creates tabheader or returns a spacer that is 0 by 0 and doesn't expand.

### sway Members

* pages - table of pages[pagename] = def
* pages_unordered - array table of pages in order of addition (used to build navigation tabs).
* contexts - contexts[playername] = player_context
* enabled - set to false to disable. Good for inventory rehaul mods.

### Context

A table with these keys:

* page - current page name
* nav - a list of page names
* nav_titles - a list of page titles
* nav_idx - current nav index (in nav and nav_titles)
* anything from the flow library
* any thing you want to store
    * sway will clear the stored data on log out / log in

### sway.register_page

sway.register_page(name, def)

def is a table containing:

* `title` - human readable page name (required)
* `get(self, player, context)` - returns a flow form. (required)
* `is_in_nav(self, player, context)` - return true to show in the navigation (the tab header, by default)
* `on_enter(self, player, context)` - called when the player changes pages, usually using the tabs.
* `on_leave(self, player, context)` - when leaving this page to go to another, called before other's on_enter

### get formspec

Use sfinv.make_form to apply a layout:

    local gui = flow.widgets
	return sfinv.make_form(player, context, gui.HBox{
			align_h = "center",
			gui.List{
				inventory_location = "current_player",
				list_name = "craft",
				w = 3, h = 3
			},
			gui.Image{
				w = 1, h = 1,
				texture_name = "sway_crafting_arrow.png"
			},
			gui.List{
				inventory_location = "current_player",
				list_name = "craftpreview",
				w = 1, h = 1
			},
			gui.Listring{
				inventory_location = "current_player",
				list_name = "main"
			},
			gui.Listring{
				inventory_location = "current_player",
				list_name = "craft"
			}
    }, true)

See above (methods section) for more options.

### Customising themes

Simply override this function to change the navigation:

    local gui = flow.widgets
	function sfinv.get_nav_gui(player, context, nav_titles, current_idx)
		return gui.Label{ label = "nav gui" }
	end

And override this function to change the layout:

	function sfinv.make_form(player, context, content, show_inv, size)
      return gui.VBox{
          padding = 0,
          sway.get_nav_gui(player, context, context.nav_titles, context.nav_idx),
          gui.VBox{
              min_w = size.w,
              min_h = size.h,
              padding = .3,
              content,
              (show_inv and theme_inv or gui.Spacer{expand=false}),
          }
      }
	end
