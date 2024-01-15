# VAC Check

Checks a player's VAC and Game Ban status when they join the game.

## ConVars

| ConVar            | Default | Description                                                                               |
| ----------------- | ------- | ----------------------------------------------------------------------------------------- |
| sm_vac_api_key    |         | Your Steam Web API key.                                                                   |
| sm_vac_max_age    | `2555`  | The minimum age (in days) of a VAC/game ban before it is forgiven. (0 = Never)            |
| sm_vac_max_bans   | `2`     | The maximum forgivable number of old bans.                                                |
| sm_vac_ban_length | `-1`    | Duration of server ban for VAC'd accounts. (In days. -1 = until 'max age', 0 = permanent) |

## Description

When a player joins the server, their account is checked for VAC/Game bans. If they have had few enough total VAC + Game bans, and they have not received a new one recently, they may be forgiven and permitted to play. Accounts which do not fall under this exception are removed and banned from the server.

The criteria for an account's bans being forgiven are that they:

1. Have not received a new VAC/Game ban in at least `sm_vac_max_age` days.
2. Have not received more than `sm_vac_max_bans` total VAC + Game bans.
   - Accounts which have received more than this number are permanently server banned, regardless of other settings.

Accounts which do not fall under the above criteria receive a server ban. The duration is set as follows:

1. If `sm_vac_ban_length` is set to `-1`, it will be until `sm_vac_max_age` passes.
2. If `sm_vac_ban_length` is set to `0`, it will be permanent.
3. Otherwise, their server ban will be for `sm_vac_ban_length` days.

## Changelog

v0.0.4 (2024-01-15) [(Latest)]()

- Prevent error if client leaves before VAC check finishes.
- Hopefully fix bans not banning.

v0.0.3 (2023-09-23) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/83e8a3817df3b293d30ed3d1536a8c7197fc89b9)

- Correct plugin not permanently banning if a player has too many vac/game bans to ever be forgivable.
- Write bans to log file.

v0.0.2 (2023-09-22) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/afcd2ed7fad0fe40960063730e78d93d1023088a)

- Add documentation.
- Simplify ConVars.
- Correct banning logic.

v0.0.1 (2023-05-05) [(Commit)](https://github.com/llamasking/sourcemod-plugins/commit/d341334abbb0d3961eb085866e9124e15efaedec)

- Initial release.
