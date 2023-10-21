#!/bin/sh
rm -f luacov*.out
busted --coverage && luacov "^init" "^api" "^crafting"
# Keep above in sync with github workflows
luacheck .
