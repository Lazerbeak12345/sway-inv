# Sway

Sway is an experimental beyond-next-gen inventory for minetest.

[![ContentDB](https://content.minetest.net/packages/lazerbeak12345/sway/shields/downloads/)](https://content.minetest.net/packages/lazerbeak12345/sway/)
[![Minetest Forums](https://img.shields.io/badge/Minetest_Forums-Sway-%234faf00?logo=minetest&labelColor=%23161616)](https://forum.minetest.net/viewtopic.php?t=29774)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![busted](https://github.com/Lazerbeak12345/sway-inv/actions/workflows/busted.yml/badge.svg)](https://github.com/Lazerbeak12345/sway-inv/actions/workflows/busted.yml)
[![luacheck](https://github.com/Lazerbeak12345/sway-inv/actions/workflows/luacheck.yml/badge.svg)](https://github.com/Lazerbeak12345/sway-inv/actions/workflows/luacheck.yml)
[![Coverage Status](https://coveralls.io/repos/github/Lazerbeak12345/sway-inv/badge.svg?branch=master)](https://coveralls.io/github/Lazerbeak12345/sway-inv?branch=master)
[![versioned: semantically](https://img.shields.io/badge/versioned-semantically-orange)](https://semver.org)
![image badge containing latest version number](https://img.shields.io/github/v/tag/Lazerbeak12345/sway-inv?filter=*.*.*&label=latest%20version)

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

Much like [SFINV], this mod is a "A cleaner, simpler solution to having an advanced inventory in Minetest." It's intended to be an excellent modding base.

Sway uses [Flow] formspecs for rendering. With Sway, formspec size is no longer a limit to your UI or UX. You can have fully dynamic layouts too!

> Lots of changes are underway! The API is not stable yet.

## Features

- So simple that it doesn't depend on any games in particular.
- Rich API.

## Screenshots

![Sway Screenshot](screenshot.png)

<!-- ## Installation -->

## API Reference

The API is based on [SFINV]'s api, but isn't compatible.

### Pages

#### Change the page

```lua
  sway.set_page(player, pagename)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to set the page for. |
| `pagename` | `string` | **Required**. The name of the page to change to. |

Asserts that the page is valid.

#### Get the name of the homepage

```lua
  sway.get_homepage_name(player)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |

#### Register a page

```lua
sway.register_page(name, def)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `name` | `string` | **Required**. The name of the page. |
| `def` | `table`, see below | **Required**. Page information |

#### Override a page

```lua
sway.override_page(name, def)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `name` | `string` | **Required**. The name of the page. |
| `def` | `table`, see below | **Required**. Page information |

> Note: Page must already be defined, (opt)depend on the mod defining it.


#### Page definition

A `table` for page information.

| Key | Type | Description |
| :-- | :--- | :---------- |
| `title` | `string` | **Required**. Human readable page name. |
| `get` | `function`, see below | **Required**. Return a flow form. |
| `is_in_nav` | `function`, see below | **Optional**. Return true to show in the navigation, which defaults to tabs. |
| `on_enter` | `function`, see below | **Optional**. Called when the player changes pages, usually using the tabs. |
| `on_leave` | `function`, see below | **Optional**. When leaving this page to go to another, called before other's `on_enter` |
| | | **Optional**. Anything else you'd like to add. These other values can, of course, be accessed through the `self` value in the above callbacks as you'd expect. |

##### Page definition function args

```lua
function(self, player, context)
    -- ...
end
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `self` | `table` | A reference to the page `def` table. |
| `player` | Player `ObjectRef` | The player that will be shown the page. |
| `context` | `table` | Context table. See `sway.get_or_create_context` |

Return a `flow` page. Sway makes use of `flow_extras.set_wrapped_context` internally. This ensures that `flow_extras.get_context` works if you need to share code between multiple forms.

#### Refresh form with new changes

```lua
sway.set_player_inventory_formspec(player, context)
```

(Re)builds page formspec with optional context defalting to a new context.

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player that will be affected. |
| `context` | `table` | **Optional**. Context table. See `sway.get_or_create_context` |

### Contexts

#### Get the player's context

```lua
sway.get_or_create_context(player)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**(Outside of form generation)/**Optional**(Inside of form generation) The player to get the context for. |

Returns: Context table.

| Key | Type | Description |
| :-- | :--- | :---------- |
| `page` | `string` | Current page name. |
| `nav` | `table` | A list of page names. |
| `nav_titles` | `table` | A list of human readable page names. |
| `nav_idx` | `number` | current nav index (in `nav` and `nav_titles`) |
| `player` | Player `ObjectRef` | The player that owns this context. |
| | | Anything from the [Flow] library's context object |
| | | Anything you'd like to store. _Sway will clear this stored data on log out / log in_ |

#### Set the player's context

```lua
local player, context = sway.get_player_and_context(player, context)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Optional**. The player. |
| `context` | `table` | **Optional**. Context table. See `sway.get_or_create_context` |

Returns same as arguments (as a tuple), but guarantees that the value is not `nil`.

#### Set the player's context

```lua
sway.set_context(player, context)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to set the context for. |
| `context` | `table` | **Required**. Context table. See `sway.get_or_create_context` |

### Theming

#### Add a theme to a form

```lua
sway.Form{
    show_inv = show_inv,
    size = size
    ...children_elements...
}
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `show_inv` | `boolean` | **Optional**. Whether to show the player's main inventory |
| `size` | `table` | **Optional**. **Deprecated**. Sets the size of the formspec. Defaults to `{ w = 8, h = 8.6 }` |
| `...children_elements...` (numbered indexes) | [Flow] elements. | **Required**. The content of the page to show. |

Returns a [Flow] form.

Wraps content in a Flow `VBox` named `"content"`.

#### Create tab navigation

```lua
sway.NavGui{
    nav_titles = nav_titles,
    current_idx = current_idx
}
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `nav_titles` | `table` | A list of human readable page names. 
| `current_idx` | `number` | current nav index (in `nav_titles`) |

Returns a [Flow] form, unless there's only one tab. In that case it returns `gui.Nil{}` from flow.

#### Create Inventory Tiles

```lua
sway.InventoryTiles{
    w = w,
    h = h
}
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `w` | `number` | **Optional** The width of the tiles. Defaults to 8
| `h` | `number` | **Optional** The height of the tiles. Defaults to 4

Returns a [Flow] form

### Members

Members of the `sway` global

| Key | Type | Description |
| :-- | :--- | :---------- |
| `pages` | `table` | Table of pages by pagename. (see `sway.override_page`) |
| `pages_unordered` | `table` | Table of pages indexed by order of registration, used to build navigation tabs. |
| `enabled` | `boolean` | Defaults to `true`. Set to false to disable the entire mod. Good for other inventory mods. |
| | | Anything from the above documentation |

## Usage/Examples

### Use `sway.Form` to apply a basic layout

```lua
    local gui = flow.widgets
	return sway.Form{
      show_inv = true,
      gui.HBox{
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
      }
    }
```

### Customising themes

Simply override this function to change the navigation:

```lua
    local gui = flow.widgets
	function sway.NavGui(fields)
        local nav_titles, current_idx = fields.nav_titles, fields.current_idx
		return gui.Label{ label = "nav gui" }
	end
```

And override this function to change the layout (not the actual code, see api.lua for that):

```lua
	function sway.Form(fields)
      local show_inv, size = fields.show_inv, fields.size
      local context = sway.get_or_create_context()
      return gui.VBox{
          sway.NavGui{
              nav_titles = context.nav_titles,
              current_idx = context.nav_idx
          },
          gui.VBox(fields)
      }
	end
```

## FAQ

#### Why is this forked from sfinv?

Three reasons:

- Sfinv is simple enough in its core that I can spend more time porting and less time worrying about what features really matter.
- The structure should be mostly the same
- I want the core mod to be just as simple as sfinv.

#### How is this mod different from sfinv?

Aside from plenty of API changes (TODO: document these),
the mod uses and interacts with [Flow] forms instead of Minetest formspec strings.

#### How is this mod different from other inventory mods?

Here's some, to make searching easier: sfinv, i3, unified inventory, inventory plus, smart inventory

- This mod _is_ minimal and game-universal, like sfinv.
- This mod _is not_ feature packed and game-specific, like nearly everything else on that list.

To make up that gap, I might make a modpack (or more than one).

#### Why call it "Sway" or "sway-inv?"

This mod is made, in part, to replace the minetest mod called [i3].

I3 seems to be named after a [well known tiling window manager](https://i3wm.org) that is built upon (and limited to) the [X11](https://www.x.org) window system.

The i3 minetest mod is similarally limited to use of (slightly enhanced) formspec strings.

There's a feature compatible competitor to i3wm called _sway_ - where this mod (sway-inv) gets its name. The sway window manager uses a newer, more modern alternative to X11 called _Wayland_.

Sway-inv is like Sway (the window manager) in that it

- Competes with a project called i3.
- Uses a newer rendering framework than its competitor.

In addition, both sfinv and sway start with the same letter.

#### How do I refer to this mod to avoid confusion with other projects?

When it's 100% clear that you are refering to Sway in the context of Minetest, call it "Sway" or its technical name `sway`.

Otherwise, refer to it as either "Sway-inv" or "sway-inv".

#### How do I ensure that my function overrides don't break anything?

In the future I'll reconfigure my unittests to also support integration testing in this manner. Right now it's not really possible.

## Roadmap

1. Full code coverage
    1. Add luacheck workflow.
    2. Add busted workflow.
    3. Start tracking versions in `0.*.*`
2. Finalize documentation
    1. Readme and tutorial must be up-to-date and fully tested
    2. At this point version 1 is ready.
3. Make a modpack that reaches feature parity with I3 (on MTG only)
    - Should be noted that I've already started this, but much of that is throwaway code. I want to see the community's reaction and feedback before I start porting things forrealzies

## Acknowledgements

 - [SFINV] Sway is a fork of SFINV by rubenwardy.
 - [Flow] Sway uses flow to render formspecs.
 - [readme.so] Readme generated by readme.so.
 - [i3] Source of inspiration and some (very small amounts) of properly attributed, licence compatible code.

## License

Code: [MIT](https://choosealicense.com/licenses/mit/) (see <./CODE_LICENSE.txt>)

* `sway_crafting_arrow.png` - renamed from a texture by paramat, derived from a texture by BlockMen (CC BY-SA 3.0).
* `sway_hb_bg.png` - renamed from `gui_hb_bg.png`, a texture by BlockMen (CC BY-SA 3.0)
* `sway_bg_full.png` - renamed from `i3_bg_full.png`, a texture by paramat (CC BY-SA 3.0)

For a copy of CC BY-SA 3.0 see <./MEDIA_LICENSE.txt>

The Sway Inv ascii art was generated via `echo "Sway Inv." | figlet -f larry3d`.
`larry3d` font is from the official figlet "contributed" collection. `pepper`
from the same collection was a close 2nd.

[SFINV]: https://github.com/rubenwardy/sfinv
[Flow]: https://github.com/luk3yx/minetest-flow
[readme.so]: https://readme.so
[i3]: https://github.com/minetest-mods/i3
