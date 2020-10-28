# Sourcemod Plugins

A repo with the source for all my SourceMod plugins. To be honest, this is pretty much just for organization.

Status | Name | Descripton
---    | ---  | ---
:heavy_check_mark: Active | Auto Hostname | A plugin I specifically made for my servers that automatically changes the hostname based on the map the server is currently on.
:arrow_right_hook: Fork | Custom Votes | [This](https://github.com/caxanga334/cvreduxmodified) custom votes plugin with some changes from [Sneak's version](https://github.com/Sneaks-Community/cvreduxmodified) included.
:heavy_check_mark: Active | Exec On Empty ([AlliedMods](https://forums.alliedmods.net/showthread.php?t=325949)) | A very simple plugin that executes a specified config whenever everyone on a server leaves.
:arrow_right_hook: Fork | Little Anti-Cheat - Auto SourceTV Recorder ([AlliedMods](https://forums.alliedmods.net/showpost.php?p=2709181&postcount=8)) | I simply added a convar so that you can specify what directory the demos should go in.
:arrow_right_hook: Fork | Player Analytics ([AlliedMods](https://forums.alliedmods.net/showpost.php?p=2716328&postcount=373)) | A fork of [sneak-it](https://github.com/sneak-it/PlayerAnalytics)'s fork of [Dr. McKay](https://forums.alliedmods.net/showthread.php?t=230832)'s plugin. Yeah, there are quite a few levels to this one. I added support to check for premium TF2 as well as removing the need for GeoIPCity in favor of GeoIP2.
:heavy_check_mark: Active | Private Analytics | An alternative to [Player Analytics](https://forums.alliedmods.net/showpost.php?p=2716328&postcount=373) that logs does not log any personally identifiable information. Only logs the time of connection, the number of players, and the country the player is from. Does not store SteamIDs, IPs, or further region data. It also logs player counts to another table since I found a need for that.
:heavy_check_mark: Active | Please Allow Ads | A plugin that asks players who are not immune to ads, and have blocked html motds to allow html motds.
:x: Incomplete | SqlVIP | An unfinished plugin I created to read a list of Steam2 IDs off a MySQL database and add them to a VIP admin group. I abandoned this after I realized SM has sqladmins already. I may finish it at some point for fun.
:heavy_check_mark: Active | WsVote ([AlliedMods](https://forums.alliedmods.net/showthread.php?p=2717878)) | A plugin I wrote for my TF2 servers (and only supports TF2 at the moment) that allows players to call votes to change to workshop maps. Requires NativeVotes.
