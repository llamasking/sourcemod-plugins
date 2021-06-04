# Workshop Vote

## Changelog

v1.1.5 (2021-06-03) [(Latest)]()

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
