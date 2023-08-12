# Sway

Sway is a experimental beyond-next-gen inventory for minetest.

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
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

Much like [SFINV], this mod is a "A cleaner, simpler solution to having an advanced inventory in Minetest." It's intended to be a good modding base.

Sway uses [Flow] formspecs for rendering.

> Lots of changes underway! Not ready yet.
> 
> In the meantime, checkout [i3](https://github.com/minetest-mods/i3). It's almost certianly what you want to use till this starts working.

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

##### Register a page - def - function args

```lua
function(self, player, context)
    -- ...
end
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `self` | `table` | A reference to the page `def` table. |
| `player` | Player `ObjectRef` | The player to get the page name for. |
| `context` | `table` | Context table. See `sway.get_or_create_context` |

#### Refresh form with new changes

```lua
sway.set_player_inventory_formspec(player, context)
```

(Re)builds page formspec with optional context defalting to a new context.

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |
| `context` | `table` | **Optional**. Context table. See `sway.get_or_create_context` |

### Contexts

#### Get the player's context

```lua
sway.get_or_create_context(player)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |

Returns: Context table.

| Key | Type | Description |
| :-- | :--- | :---------- |
| `page` | `string` | Current page name. |
| `nav` | `table` | A list of page names. |
| `nav_titles` | `table` | A list of human readable page names. |
| `nav_idx` | `number` | current nav index (in `nav` and `nav_titles`) |
| | | Anything from the [Flow] library's context object |
| | | Anything you'd like to store. _Sway will clear this stored data on log out / log in_ |


#### Set the player's context

```lua
sway.set_context(player, context)
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |
| `context` | `table` | **Required**. Context table. See `sway.get_or_create_context` |

### Theming

#### Add a theme to a form

```lua
sway.Form{
    player = player,
    context = context,
    show_inv = show_inv,
    size = size
    ...children_elements...
}
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |
| `context` | `table` | **Required**. Context table. See `sway.get_or_create_context` |
| `show_inv` | `boolean` | **Optional**. Whether to show the player's main inventory |
| `size` | `table` | **Optional**. **Deprecated**. Sets the size of the formspec. Defaults to `{ w = 8, h = 8.6 }` |
| `...children_elements...` (numbered indexes) | [Flow] elements. | **Required**. The content of the page to show. |

Returns a [Flow] form.

Wraps content in a Flow `VBox` named `"content"`.

#### Create tab navigation

```lua
sway.NavGui{
    player = player,
    context = context,
    nav_titles = nav_titles,
    current_idx = current_idx
}
```

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `player` | Player `ObjectRef` | **Required**. The player to get the page name for. |
| `context` | `table` | **Required**. Context table. See `sway.get_or_create_context` |
| `nav_titles` | `table` | A list of human readable page names. 
| `current_idx` | `number` | current nav index (in `nav_titles`) |

Returns a [Flow] form, unless there's only one tab. In that case it returns `gui.Nil{}` from flow.

### Members

Members of the `sway` global

| Key | Type | Description |
| :-- | :--- | :---------- |
| `pages` | `table` | Table of pages by pagename. (see `sway.override_page`) |
| `pages_unordered` | `table` | Table of pages indexed by order of registration, used to build navigation tabs. |
| `contexts` | `table` | Table of player contexts by playername. |
| `enabled` | `boolean` | Defaults to `true`. Set to false to disable the entire mod. Good for other inventory mods. |
| | | Anything from the above documentation |

## Usage/Examples

### Use `sway.Form` to apply a basic layout

    local gui = flow.widgets
	return sway.Form{
      player = player,
      context = context,
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

### Customising themes

Simply override this function to change the navigation:

    local gui = flow.widgets
	function sway.NavGui(fields)
        local player, context, nav_titles, current_idx = fields.player, fields.context, fields.nav_titles, fields.current_idx
		return gui.Label{ label = "nav gui" }
	end

And override this function to change the layout (not the actual code, see api.lua for that):

	function sway.Form(fields)
      local player, context, content, show_inv, size = fields.player, fields.context, fields.content, fields.show_inv, fields.size
      return gui.VBox{
          sway.NavGui{
              player = player,
              context = context,
              nav_titles = context.nav_titles,
              current_idx = context.nav_idx
          },
          gui.VBox(fields)
      }
	end

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

## Roadmap

1. Research alternative (faster, but understandable) way(s) of overriding content.
2. Full code coverage
3. Finalize documentation
4. Make a modpack that reaches feature parity with I3 (on MTG only)
    - Should be noted that I've already started this, but much of that is throwaway code. I want to see the community's reaction and feedback before I start porting things forrealzies

## Acknowledgements

 - [SFINV] Sway is a fork of SFINV by rubenwardy.
 - [Flow] Sway uses flow to render formspecs.
 - [readme.so] Readme generated by readme.so.
 - [i3] Source of inspiration and some (very small amounts) of properly attributed, licence compatible code.

## License

Code: [MIT](https://choosealicense.com/licenses/mit/)

* `sway_crafting_arrow.png` - renamed from a texture by paramat, derived from a texture by BlockMen (CC BY-SA 3.0).
* `sway_hb_bg.png` - renamed from `gui_hb_bg.png`, a texture by BlockMen (CC BY-SA 3.0)
* `sway_bg_full.png` - renamed from `i3_bg_full.png`, a texture by paramat (CC BY-SA 3.0)

TODO: Include CC BY-SA 3.0 licence text.

[SFINV]: https://github.com/rubenwardy/sfinv
[Flow]: https://github.com/luk3yx/minetest-flow
[readme.so]: https://readme.so
[i3]: https://github.com/minetest-mods/i3
