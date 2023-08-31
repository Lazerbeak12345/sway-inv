# Sway Tutorial

Everything below is subject to become outdated until I reach my minimum goals. See README.md

---

## Introduction
<!-- TODO omit in toc -->

Sway is a mod found in Minetest Game that is used to create the player's
inventory formspec. It's based upon the earlier SFINV mod, but doesn't have a
compatible API due to it's use of a more modern widget toolkit. Sway comes with
an API that allows you to add and otherwise manage the pages shown.

Whilst Sway by default shows pages as tabs, pages are called pages because it
is entirely possible that a mod or game decides to show them in some other
format instead. For example, multiple pages could be shown in one form.

- [Registering a Page](#registering-a-page)
- [Receiving events](#receiving-events)
- [Conditionally showing to players](#conditionally-showing-to-players)
- [on_enter and on_leave callbacks](#onenter-and-onleave-callbacks)
- [Adding to an existing page](#adding-to-an-existing-page)

## Registering a Page

Sway provides the aptly named `sway.register_page` function to create pages.
Simply call the function with the page's name and its definition:

```lua
local gui = flow.widgets
sway.register_page("mymod:hello", {
    title = "Hello!",
    get = function(self, player, context)
        return sway.Form{
            player = player,
            context = context,
			show_inv = true,
            gui.Label{ label = "Hello world!" }
        }
    end
})
```

The `sway.Form` function surrounds your formspec with Sway's formspec code.
The `show_inv` parameter, currently set as `true`, determines whether the
player's inventory is shown.

Let's make things more exciting; here is the code for the formspec generation
part of a player admin tab. This tab will allow admins to kick or ban players by
selecting them in a list and clicking a button.

```lua
sway.register_page("myadmin:myadmin", {
    title = "Tab",
    get = function(self, player, context)
        local players = {}
        context.myadmin_players = players
        for _ , player in pairs(minetest.get_connected_players()) do
            players[#players + 1] = player:get_player_name()
        end
        return sway.Form{
            player = player,
            context = context,
            show_inv = false,
            -- sway.Form puts all of its children into a gui.VBox.
            -- This is the first child
            gui.Textlist{ w = 7.8, h = 3, name = "playerlist", listelms = players },
            -- And this HBox is the second row.
            -- This way we'll have a horizontal row of buttons
            gui.HBox{
                gui.Button{ label = "Kick" },
                gui.Button{ label = "Kick + Ban" }
            }
        }
    end,
})
```

There's nothing new about the above code; all the concepts are
covered above, in the documentation for `flow`, Formspec AST or minetest
itself.

## Receiving events

You can receive form events just as you would in flow.

```lua
gui.Button{
    label = "Lorem ipsum",
    on_event = function(player, context)
        -- TODO: implement this
    end,
}
```

As in most flow forms, event callbacks are only triggered when an event happens
to that particular element. This means Sway will consume events relevant to
itself, such as navigation tab events, so you won't receive them in this
callback.

Now let's implement the `on_event` functions for our admin mod:

```lua
gui.HBox{
    gui.Button{
        label = "Kick"
        on_event = function(player, context)
            local player_name = context.myadmin_players[context.form.playerlist]
            if player_name then
                minetest.chat_send_player(player:get_player_name(),
                        "Kicked " .. player_name)
                minetest.kick_player(player_name)
            end
        end
    },
    gui.Button{
        label = "Kick + Ban"
        on_event = function(player, context)
            local player_name = context.myadmin_players[context.form.playerlist]
            if player_name then
                minetest.chat_send_player(player:get_player_name(),
                        "Banned " .. player_name)
                minetest.ban_player(player_name)
                minetest.kick_player(player_name, "Banned")
            end
        end
    }
}
```

There's a rather large problem with this, however. Anyone can kick or ban players! You
need a way to only show this to players with the kick or ban privileges.
Luckily Sway allows you to do this!

## Conditionally showing to players

You can add an `is_in_nav` function to your page's definition if you'd like to
control when the page is shown:

```lua
is_in_nav = function(self, player, context)
    local privs = minetest.get_player_privs(player:get_player_name())
    return privs.kick or privs.ban
end,
```

If you only need to check one priv or want to perform an 'and', you should use
`minetest.check_player_privs()` instead of `get_player_privs`.

Note that the `is_in_nav` is only called when the player's inventory formspec is
generated. This happens when a player joins the game, switches tabs, or a mod
requests for SFINV to regenerate.

This means that you need to manually request that Sway regenerates the inventory
formspec on any events that may change `is_in_nav`'s result. In our case, we
need to do that whenever kick or ban is granted or revoked to a player:

```lua
local function on_grant_revoke(grantee, granter, priv)
    if priv ~= "kick" and priv ~= "ban" then
        return
    end

    local player = minetest.get_player_by_name(grantee)
    if not player then
        return
    end

    local context = sway.get_or_create_context(player)
    if context.page ~= "myadmin:myadmin" then
        return
    end

    sway.set_player_inventory_formspec(player, context)
end

minetest.register_on_priv_grant(on_grant_revoke)
minetest.register_on_priv_revoke(on_grant_revoke)
```

## on_enter and on_leave callbacks

A player *enters* a tab when the tab is selected and *leaves* a
tab when another tab is about to be selected.
It's possible for multiple pages to be selected if a custom theme is
used.

Note that these events may not be triggered by the player.
The player may not even have the formspec open at that time.
For example, on_enter is called for the home page when a player
joins the game even before they open their inventory.

It's not possible to cancel a page change, as that would potentially
confuse the player.

```lua
on_enter = function(self, player, context)

end,

on_leave = function(self, player, context)

end,
```

## Adding to an existing page

To add content to an existing page, you will need to override the page
and modify the returned formspec.

I reccomend making use of `flow_extras`' `flow_extras.search` function to insert
things where they go. Because you're modifying a tree strucure that other mods
might also choose to modify, be sure to add any mods that you would like to
play nice with into your `mod.conf` file, when appropriate. This will tell
Minetest that they should run first.

```lua
local old_func = sway.pages["sway:crafting"].get
sway.override_page("sway:crafting", {
    get = function(self, player, context, ...)
        local ret = old_func(self, player, context, ...)

        -- Don't forget to add `flow_extras` as a dependancy in mod.conf too!
        for content_box in flow_extras.search{
            tree = ret,
            key = "name",
            value = "content"
        } do
            -- Since content_box is an element, and all elements are tables, we
            -- can add a child like so:
            content_box[#content_box+1] = gui.Label{ label = "Hello" }
            -- Since `search` found the element we were looking for, we can tell
            -- it to stop searching.
            break
        end

        return ret
    end
})
```

You can simplify that loop down to this, since that code was only getting the first item:

```lua
        --- ...
        local content_box = flow_extras.search{
            tree = ret,
            key = "name",
            value = "content"
        }()
        content_box[#content_box+1] = gui.Label{ label = "Hello" }
        ---...
```

This could be made even faster, though it uses APIs dependant on the mod providing the tab. The search function has to compare every single node to see if it matches. In the case of the `"sway:crafting"` page, and other simmilar apis, they provide functions to override content. This reduces the time complexity from O(n) to O(1). Of course, if we actually cared _exactly_ which element we wanted to modify, we'd still want to do a search, but making use of _both_ apis can make your forms _much_ faster.

The `"sway:crafting"` page provides the `CraftingRow` function that can be overridden.

```lua
local old_func = sway.pages["sway:crafting"].CraftingRow
sway.override_page("sway:crafting", {
    CraftingRow = function(self, player, context, ...)
        local ret = old_func(self, player, context, ...)
        ret[#ret+1] = gui.Label{ label = "Hello" }
        return ret
    end
})
```
