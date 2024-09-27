# Private Analytics

### Note: Sanitization

This plugin uses Database.Format() to escape strings before sending them to the DB. I do believe this is safe enough, however as variables are escaped and added directly to the query instead of using a prepared statement, there is always a potential for SQL injection.

Further note: Usernames, SteamIDs, and IPs are **never** sent to the database. The only data sent to the DB that the end user has any significant sense of control over are the map. All other variables sent to the DB originate from the server itself. This is why I do not believe there is a significant risk of SQL injection.

## Changelog

## v1.1.0 (2024-09-27) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/f5b694bb1ca17e2f3a6a248aaa64fc302d1380de)

- Fixes bug where map name is not updated on change
- Uses map full name instead of display name.
  - This does nothing for builtin maps, but workshops maps will now report as workshop/ctf_2fort_mesa_a3a.ugc3330363468 instead of ctf_2fort_mesa_a3a

v1.0.2 (2022-12-29) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/f003000432c1a48474a0ecbd1865c006b10dbc6d)

- Fix a 'Client X is not connected' exception.

v1.0.1 (2021-05-30) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/7d12a2bc25f1c531f1f440bd27c7b9a22dbef48c)

- Fixed player counts only the first digit
- Increase max length of a country name to 63 characters
- Better string sanitization (See note above)
- General optimization

v1.0.0 (2020-11-03) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/38e66465c8d1a7a5d82d068fec85267a79a28920)

- Initial release on AlliedMods
- Bump version number to 1.0.0

v0.2.1 (2020-10-27) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/90d418e4d4ea61ee5cacf1c3b11e8d65902a5095)

- Change update url to allign with new folder structure.

v0.2.1 (2020-10-27) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/06657c4903ab4234a5308f042ab2b5ab55d90992)

- Turn off debug mode and make the plugin functional

v0.2.0 (2020-10-27) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/2ddca14a7fd6fdd402971a3506463c23517c1b9b)

- Allow logging of html motd status (off by default)
- General code restructuring

v0.1.0 (2020-10-27) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/94931e8698a7471933ae935e99c6800c24097621)

- Initial test release
