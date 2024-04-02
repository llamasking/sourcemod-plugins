/*
 * ======================================================================
 * VAC Check
 * Copyright (C) 2023 llamasking
 * ======================================================================
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, as per version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma semicolon 1
#pragma newdecls required

#include <SteamWorks>
#include <sourcemod>

//#define DEBUG
#define VERSION    "0.0.5"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/vac_check/updatefile.txt"

#if !defined DEBUG
    #undef REQUIRE_PLUGIN
    #include <updater>
#endif

#if defined DEBUG
    #warning COMPILING IN DEBUG MODE!
#endif

/* ConVars */
ConVar g_apiKey;
ConVar g_vacMaxAge;
ConVar g_maxBanCount;
ConVar g_banLength;

public Plugin myinfo =
{
        name        = "VAC Check",
        author      = "llamasking",
        description = "Removes players who have been VAC/Game banned.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins"
}

public void
OnPluginStart()
{
    CreateConVar("sm_vac_version", VERSION, "VAC Check version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_apiKey      = CreateConVar("sm_vac_api_key", "", "Your Steam Web API Key", FCVAR_PROTECTED);
    g_vacMaxAge   = CreateConVar("sm_vac_max_age", "2555", "The minimum age (in days) of a VAC/game ban before it is forgiven. (0 = Never)", FCVAR_PROTECTED, true, 0.0);
    g_maxBanCount = CreateConVar("sm_vac_max_bans", "2", "The maximum forgivable number of old bans.", FCVAR_PROTECTED, true, 0.0);
    g_banLength   = CreateConVar("sm_vac_ban_length", "-1", "Duration of server ban for VAC'd accounts. (In days. -1 = until 'max age', 0 = permanent)", FCVAR_PROTECTED, true, -1.0);

    AutoExecConfig();

#if !defined DEBUG
    // Updater
    if (LibraryExists("updater"))
        Updater_AddPlugin(UPDATE_URL);
#endif
}

// Updater
#if !defined DEBUG

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
        Updater_AddPlugin(UPDATE_URL);
}
#endif

public void OnClientAuthorized(int client, const char[] auth)
{
    char steamId[22];
    GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId));

#if defined DEBUG
    // Random banned accounts since I don't have a banned acc handy.
    // strcopy(steamId, sizeof(steamId), "76561198262728767");    // 1 VAC and 1 Game Ban (Recent)
    // strcopy(steamId, sizeof(steamId), "76561199441703051");    // 1 Game Ban (Recent)
    // strcopy(steamId, sizeof(steamId), "76561198035091056");    // 2 Vac Bans (Recent)
    // strcopy(steamId, sizeof(steamId), "76561199236258744");    // 1 Vac Ban (Recent)

    LogMessage("Sending VAC check for client: '%N' using SteamID '%s'", client, steamId);
#endif

    // Get (and check) web api key
    char apiKey[33];
    g_apiKey.GetString(apiKey, sizeof(apiKey));
    if (StrEqual(apiKey, ""))
    {
        LogError("Web API key is unset!");
        return;
    }

    char reqUrl[256];
    Format(reqUrl, sizeof(reqUrl), "https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=%s&steamids=%s&format=vdf", apiKey, steamId);

    // Query SteamAPI.
    Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, reqUrl);
    SteamWorks_SetHTTPRequestContextValue(req, GetClientUserId(client));
    SteamWorks_SetHTTPCallbacks(req, BanCheckCallback);
    SteamWorks_SendHTTPRequest(req);

#if defined DEBUG
    LogMessage("Sending API request: %s", reqUrl);
#endif
}

public void BanCheckCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any userid)
{
    int client = GetClientOfUserId(userid);

    // Client disconnected before the request returned.
    if (client == 0 || !IsClientAuthorized(client) || !IsClientConnected(client))
    {
        delete req;
        return;
    }

    // Request failed.
    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        LogError("Error on VAC check for client: '%L'", client);
        delete req;
        return;
    }

    // Read response.
    int respSize;
    SteamWorks_GetHTTPResponseBodySize(req, respSize);
    char[] data = new char[respSize];
    SteamWorks_GetHTTPResponseBodyData(req, data, respSize);

    // Turn response into keyvalues.
    bool success = true;
    KeyValues kv = new KeyValues("response");
    kv.SetEscapeSequences(true);
    success &= kv.ImportFromString(data);
    success &= kv.JumpToKey("players");
    success &= kv.JumpToKey("0");

    if (!success)
    {
        LogError("Failed to parse KeyValues for '%L'", client);
        delete req;
        delete kv;
        return;
    }

    // Get data from KV
    int vBanCnt = kv.GetNum("NumberOfVACBans");
    int gBanCnt = kv.GetNum("NumberOfGameBans");
    int banAge  = kv.GetNum("DaysSinceLastBan");
    int tBanCnt = vBanCnt + gBanCnt;

    // Figure out some things
    bool hasVacBan   = vBanCnt != 0;
    bool hasGameBan  = gBanCnt != 0;
    bool hasAnyBan   = hasVacBan || hasGameBan;
    bool tooManyBans = tBanCnt > g_maxBanCount.IntValue;            // Too many bans for forgiveness
    bool bansAreNew  = hasAnyBan && banAge < g_vacMaxAge.IntValue;  // Bans too new
    if (g_vacMaxAge.IntValue == 0)
        bansAreNew = hasAnyBan;  // If forgiveness is disabled

#if defined DEBUG
    LogMessage("%L: hasVacBan: %i, hasGameBan: %i, hasAnyBan: %i", client, hasVacBan, hasGameBan, hasAnyBan);
    LogMessage("%L: NumberOfVACBans: %i, NumberOfGameBans: %i, DaysSinceLastBan: %i", client, vBanCnt, gBanCnt, banAge);
    LogMessage("%L: tooManyBans: %i, bansAreNew: %i", client, tooManyBans, bansAreNew);
#endif

    // If the user has a ban and is not forgivable, ban them.
    if (hasAnyBan && (tooManyBans || bansAreNew))
    {
        // Calculate ban length
        int banDuration = g_banLength.IntValue;           // Default to ban duration set in convar
        if (tooManyBans)                                  // If the player has too many bans to be forgivable, they are
            banDuration = 0;                              // permanently banned.
        else if (g_banLength.IntValue == -1)              // However, if they have a forgivable number of bans and the duration is until
            banDuration = g_vacMaxAge.IntValue - banAge;  // 'max age', calculate how long until the vac/game ban is forgivable.

        banDuration *= 1440;  // Convert days to minutes

#if defined DEBUG
        LogMessage("Would have banned '%L' for '%i' days.", client, banDuration / 1440);
#else
        char reason[] = "[VAC Check] VAC banned accounts are not permitted on this server.";
        BanClient(client, banDuration, BANFLAG_AUTO, reason, reason);
        LogMessage("Banned '%L' for '%i' days.", client, banDuration / 1440);
#endif
    }

    // Cleanup
    delete req;
    delete kv;
}
