# Auto Hostname

## Changelog

v1.2.0 (2024-04-16) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/b09eedef4d3276435b867ab7562b54c50563cdf9)

- Update hostname immediately upon convar change. Previously, the plugin would pause a moment, expecting multiple convars to change, but this extra complexity is not necessary as it has little to no benefit.
- Improve code comments

v1.1.4 (2022-12-04) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/47127eee90626d0c0d25b7f9d6d3904b480de0d6)

- Coding changes.

v1.1.3 (2022-08-22) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/462be598b77e9e6e5b30dc0285f696c1fd62647b)

- Fix some map names not displaying fully
- Fix a security hole where a malicious map name could potentially execute arbitrary commands through this plugin.

v1.1.2 (2022-09-26) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/cb53c73a6fa80259eaf5a69dd9972a075729f819)

- Increase max length of prefix and suffix

v1.1.1 (2020-08-13) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/2727e5c5b415805e849269033ce06925e5555326)

- Add URL to plugin info
- Make version cvar notify
- Use OnConfigsExecuted instead of OnMapStart
- Add GPL license to top of file

v1.1 (2020-07-13) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/de7fbc031e6968e4ec56fb76d76b74ad4e7a2a24)

- Add hook for when convar changes
- Trim map name
- Wait a little bit before changing the map name to prevent issues

v1.0 (2020-07-13) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/c79144495b6d4c5bc0d71ee27a842d8f81346e7c)

- Initial release
