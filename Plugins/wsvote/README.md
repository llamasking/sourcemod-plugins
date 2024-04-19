# Workshop Vote

## Changelog

v1.2.1 (2024-04-19) [(Latest)]()

- Fixed an issue where parsing a URL parsing would error.
- Fixed an issue where an incorrect map ID would be displayed in chat.
- Code optimizations.

v1.2.0-1 (2022-12-04) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/8d1e68fd6b06990ffe94a55991bc9e5000bdec06)

- Recompile to be sure it's not mistakenly in debug mode.
- Translation fix.

v1.2.0 (2022-12-04) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/b2035a8711443369fc6170f85b7044f9d4f7414b)

- Allow users to send the map link instead of the id itself. The plugin will try to find the id in the link.

v1.1.10 (2022-09-05) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/402ab06285f80b56c0116d95f16b7114b8b61bbc)

- A few more checks in place to prevent possible runtime errors
- Fix possible memory leak

v1.1.9 (2022-09-05) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/9baf174e5d5384e78b90245a0c19f46a7876b11f)

- Better map id checking
- (Slightly) smarter code
  - Replaced the use of global vars wherever possible.
  - Wherever possible, data is now sent between functions through a datapack
  - More use of methodmaps rather than directly using older APIs
  - Close handle leak that could occur if wsvote was called as another vote was active.
  - Removed unnecessary `client` var being passed to `CReplyToCommand

v1.1.8 (2021-08-19) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/8b2aa4bc047b489b9b7b42a7428bf5ea8638d41b)

- Fix a minor error if a player leaves before getting a map notification.
- Code formatting tweaks.

v1.1.7 (2022-02-11) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/507121f5769e6ee67872ea7d4a1fec213ba6306f)

- Register sm_ws and sm_wsm commands

v1.1.6 (2021-10-29) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/06371b476e49ea2a2f7e25acab325de6ae81e8e4)

- Register sm_workshop and sm_workshopmap commands

v1.1.5 (2021-06-03) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/f4689cf3d5a55588db8f79dd6d05b2571a295be6)

- Translation fixes.

v1.1.4 (2021-05-24) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/4e21026d717f0ca62050d3efd336839d7aaec229)

- Add translation file.

v1.1.3 (2021-02-09) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/d9b38bef8a76ddfb6a228996b70f5f1e294dcf32)

- Fix a bug in which any workshop item with a double quote anywhere in the description (or probably title) would always spit an error.
- Take advantage of (specific) MethodMaps because they're awesome.

v1.1.2 (2021-02-09) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/fa64b28e6a39cdc176c48f40dcf391fa43c7668d)

- Use lifetime subscriptions rather than current subscriptions.

v1.1.1 (2020-11-16) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/a00737294814ab03b8a78d59e819630417cf40b1)

- Better ConVar descriptions.
- Fix tag mismatch warning on compile.

v1.1.0 (2020-11-10) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/fa64b28e6a39cdc176c48f40dcf391fa43c7668d)

- Add cvar 'sm_workshop_delay' to change the delay between a vote passing and the map changing.
- Add cvars 'sm_workshop_notify' and 'sm_workshop_notify_delay' to automatically notify players about the map (only if it's a workshop map).
- Add command 'sm_cmap' and 'sm_currentmap' to get information on the current map.

v1.0.6 (2020-10-28) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/3a3da8e04b4ef9e372b3019fa2fa0530992c3096)

- Change update url to allign with new folder structure.

v1.0.5 (2020-09-28) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/3a3da8e04b4ef9e372b3019fa2fa0530992c3096)

- Attempt to preload map in period between vote passing and map changing

v1.0.4 (2020-09-26) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/4448e7d86ab50e2360838a5061c91832f4e4b573)

- Fix another memory leak

v1.0.3 (2020-09-26) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/a1550dc824bde78e0b8029b97964f50bbc17d276)

- Add notice if debug mode is on
- Fix memory leaks

v1.0.2 (2020-09-26) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/83360b11f14243471ec2f88bcfe7aeb56d1e8a71)

- Oh, fuck! Debug mode is on!

v1.0.1 (2020-09-25) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/85532e19dcf3834ecfa2f5750ac4951f0e453145)

- Fix compilation errors if debug is defined
- Add notice to vote caller about possible issues
- Say '10' rather than 'a few' seconds
- Just use the changelevel command

v1.0.0 (2020-09-15) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/a84ced1bbf07f5fb8c5b9262dcd2d94a66341ea8)

- Initial release on AlliedMods forums
- Updater is now optional rather than required
- Plugin should throw error on loading if not in TF2
- Replace ReplyToCommand with PrintToChat because it used to print to console
- Change some wording
- General code cleanup

v0.0.1 (2020-09-08) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/a2ee4308d56a089662997099fc29a7342dfbc7e4)

- Implement changes recommended by Sikari and Impact from the AlliedMods Discord.

v0.0.0 (2020-09-08) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/e95a336ebd6f4344f0994e742b2557b765a44107)

- Initial test release
