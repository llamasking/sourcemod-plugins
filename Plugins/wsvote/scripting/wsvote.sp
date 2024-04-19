/**
 * ======================================================================
 * Workshop Map Vote
 * Copyright (C) 2020-2022 llamasking
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

#include <SteamWorks>
#include <multicolors>
#include <nativevotes>
#include <sourcemod>

#pragma newdecls required

//#define DEBUG
#define VERSION    "1.2.1"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/wsvote/updatefile.txt"

#if !defined DEBUG
    #undef REQUIRE_PLUGIN
    #include <updater>
#endif

public Plugin myinfo =
{
        name        = "Workshop Map Vote",
        author      = "llamasking",
        description = "Allows players to call votes to change to workshop maps.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins"
}

/* This is a datapack that contains information on the active vote and is only ever set while a vote is active. */
DataPack g_active_vote_info = null;

/* Regex to get map ID out of url */
Regex r_get_map_id = null;

/* ConVars */
ConVar g_minsubs;
ConVar g_mapchange_delay;
ConVar g_notify;
ConVar g_notifydelay;

/* Current Map Info */
char g_cmap_name[64] = "Unknown";
char g_cmap_id[64]   = "Unknown";
bool g_cmap_stock;

public void OnPluginStart()
{
    char game[16];
    GetGameFolderName(game, sizeof(game));

    // Throw error if running any game other than tf2.
    if (!StrEqual(game, "tf"))
        SetFailState("This game is not supported! Stopping.");

    // Fail if the game does not support a change level vote.
    // Useful if I add support for other games in the future.
    /*
    if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_ChgLevel))
        SetFailState("This game does not support a change level vote! Stopping.");
    */

    // ConVars
    CreateConVar("sm_workshop_version", VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
    g_minsubs         = CreateConVar("sm_workshop_min_subs", "50", "The minimum number of current subscribers for a workshop map.");
    g_mapchange_delay = CreateConVar("sm_workshop_delay", "10", "The delay between the vote passing and the map changing.", _, true, 0.0);
    g_notify          = CreateConVar("sm_workshop_notify", "1", "Whether or not to notify joining players about the map's Workshop name and ID.'", _, true, 0.0, true, 1.0);
    g_notifydelay     = CreateConVar("sm_workshop_notify_delay", "60", "How many seconds to wait after a client joins before notifying them.'", _, true, 0.0);

    // Compile regex
    char error[256];
    r_get_map_id = new Regex("https?://(?:www\\.)?steamcommunity\\.com/sharedfiles/filedetails/.*[?&]id=(\\d+)", PCRE_CASELESS, error, sizeof(error));
    if (strlen(error) != 0)
    {
        LogError(error);
        r_get_map_id = null;
    }

    // Load config values.
    AutoExecConfig();

    // Load translations.
    LoadTranslations("wsvote.phrases.txt");

    // Register commands.
    RegConsoleCmd("sm_workshop", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_workshopmap", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_wsmap", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_wsvote", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_wsm", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_ws", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_cmap", Command_CurrentMap, "Shows information about the current map.");
    RegConsoleCmd("sm_currentmap", Command_CurrentMap, "Shows information about the current map.");

// Updater
#if !defined DEBUG
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
#endif
}

#if !defined DEBUG

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}
#endif

// Current Map Functionality
public void OnMapStart()
{
    char cmap_name[64];
    GetCurrentMap(cmap_name, sizeof(cmap_name));

    // Workshop maps will end in .ugc[id]
    // Ex: workshop/ctf_applejack_rc1.ugc3219571335
    // By checking for that, we can tell if the current map is from the workshop or not.

    int ugc_idx  = StrContains(cmap_name, ".ugc");
    g_cmap_stock = ugc_idx == -1;

    if (!g_cmap_stock)
    {
        // Get map ID out of it's name
        strcopy(g_cmap_id, sizeof(g_cmap_id), cmap_name[ugc_idx + 4]);

        // Query SteamAPI for more information.
        // Format body of request.
        char reqBody[64];
        Format(reqBody, sizeof(reqBody), "itemcount=1&publishedfileids[0]=%s&format=vdf", g_cmap_id);

        // Query SteamAPI.
        Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
        SteamWorks_SetHTTPRequestRawPostBody(req, "application/x-www-form-urlencoded", reqBody, strlen(reqBody));
        SteamWorks_SetHTTPCallbacks(req, UpdateCurrentMapCallback);
        SteamWorks_SendHTTPRequest(req);
    }
    else
    {
        strcopy(g_cmap_name, sizeof(g_cmap_name), cmap_name);
    }
}

public void UpdateCurrentMapCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode)
{
    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        LogError("Error updating current map info!");
        delete req;  // See notice below.
        return;
    }

    // Read response.
    int size;
    SteamWorks_GetHTTPResponseBodySize(req, size);
    char[] data = new char[size];
    SteamWorks_GetHTTPResponseBodyData(req, data, size);

    // Turn response into keyvalues.
    KeyValues kv = new KeyValues("response");
    kv.SetEscapeSequences(true);
    kv.ImportFromString(data);

    // Move into item's subkey.
    kv.JumpToKey("publishedfiledetails");
    kv.JumpToKey("0");

    // Get map name!
    kv.GetString("title", g_cmap_name, sizeof(g_cmap_name));

    // NOTICE: FOR THE LOVE OF ALL THINGS YOU CARE ABOUT, DELETE HANDLES.
    // OTHERWISE IT WILL LEAK SO BADLY THAT THE SERVER WILL ALMOST IMMEDIATELY CRASH.
    delete req;
    delete kv;
}

// Provides players with the name and ID of the map they're on when they join.
public void OnClientPutInServer(int client)
{
    if (!g_cmap_stock && GetConVarBool(g_notify) && IsClientValid(client))
        CreateTimer(GetConVarFloat(g_notifydelay), Timer_NotifyPlayer, GetClientUserId(client));
}

public Action Timer_NotifyPlayer(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Workshop", g_cmap_name, g_cmap_id);

    return Plugin_Handled;
}

// Current Map Command
public Action Command_CurrentMap(int client, int args)
{
    if (g_cmap_stock)
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Stock", g_cmap_name);
    else
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Workshop", g_cmap_name, g_cmap_id);

    return Plugin_Handled;
}

// WsVote / WsMap Command
public Action Command_WsVote(int client, int args)
{
#if defined DEBUG
    CReplyToCommand(client, "{fullred}[Workshop]{default} %t", "WsVote_DebugMode_Enabled");
#endif

    // Ignore console/rcon and spectators.
    if (client == 0 || GetClientTeam(client) < 2)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} %t", "WsVote_Spectator");
        return Plugin_Handled;
    }

    // Get workshop map id
    char map_id[16];
    GetCmdArg(1, map_id, sizeof(map_id));

    // If the user provided a link instead of the id directly, attempt to dig it out using regex.
    if (StrContains(map_id, "http") == 0 && r_get_map_id != null)
    {
        // Note: For a command such as 'sm_wsmap https://steamcommunity.com/sharedfiles/filedetails/?id=3219571335',
        // Arg 1 is just 'https'. It used to be the entire url, but it changed at some point.

        char cmd_buff[128];
        GetCmdArgString(cmd_buff, sizeof(cmd_buff));                                          // Read entire command into buffer
        if (r_get_map_id.Match(cmd_buff) <= 0)                                                // Run regex on buffer.
        {                                                                                     // If regex fails to find id, error
            CReplyToCommand(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_NoId");  //
            return Plugin_Handled;                                                            //
        }                                                                                     //
        r_get_map_id.GetSubString(1, map_id, sizeof(map_id));                                 // Regex found id
    }

    // Map ID must be stored as a string because StringToInt(map_id) will int overflow,
    // but this works to test if the map_id string is a number.
    if (StringToInt(map_id) == 0)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_NoId");
        return Plugin_Handled;
    }

    // Format body of request.
    char reqBody[64];
    Format(reqBody, sizeof(reqBody), "itemcount=1&publishedfileids[0]=%s&format=vdf", map_id);

    // Bundle datapack with information about this request
    DataPack pack = CreateDataPack();
    pack.WriteCell(GetClientUserId(client));  // Cell 1: User ID of player initiating vote
    pack.WriteString(map_id);                 // Cell 2: Map ID as a string

    // Query SteamAPI.
    Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
    SteamWorks_SetHTTPRequestRawPostBody(req, "application/x-www-form-urlencoded", reqBody, strlen(reqBody));
    SteamWorks_SetHTTPRequestContextValue(req, pack);
    SteamWorks_SetHTTPCallbacks(req, ReqCallback);
    SteamWorks_SendHTTPRequest(req);

    return Plugin_Handled;
}

public void ReqCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, DataPack pack)
{
    // Unpack datapack
    pack.Reset();
    char map_id[16];
    int user_id = pack.ReadCell();            // Cell 1: User ID of player initiating vote
    pack.ReadString(map_id, sizeof(map_id));  // Cell 2: Map ID as a string
                                              // Cell 3: Map name (unknown right now, but will be added later)

    int client = GetClientOfUserId(user_id);

    // Check client is still valid
    if (!IsClientValid(client))
    {
        delete req;
        delete pack;
        return;
    }

    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_ApiFailure");
        LogError("Error on request for id: '%s'", map_id);
        delete req;
        delete pack;
        return;
    }

    // Read response.
    int size;
    SteamWorks_GetHTTPResponseBodySize(req, size);
    char[] data = new char[size];
    SteamWorks_GetHTTPResponseBodyData(req, data, size);
    delete req;  // We don't need this anymore.

    // Turn response into keyvalues.
    KeyValues kv = new KeyValues("response");
    kv.SetEscapeSequences(true);
    kv.ImportFromString(data);

    // Move into item's subkey.
    kv.JumpToKey("publishedfiledetails");
    kv.JumpToKey("0");

    // Verify the item is actually for TF2 and has enough subscribers.
    // Also accidentally verifies that the id is actually a map since apparently only maps can have subscriptions.
    if (kv.GetNum("consumer_app_id") != 440 || (kv.GetNum("lifetime_subscriptions") < GetConVarInt(g_minsubs)))
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_InvalidItem");

        delete kv;
        delete pack;

        return;
    }

    // Get map name and save to to DataPack.
    char map_name[64];
    kv.GetString("title", map_name, sizeof(map_name));
    pack.WriteString(map_name);  // Cell 3: Map name
    delete kv;                   // We don't need this anymore.

    // Abort if a vote is already in progress.
    if (NativeVotes_IsVoteInProgress())
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_ExistingVote");
        delete pack;
        return;
    }

    // Initialize vote.
    NativeVote vote = new NativeVote(Nv_Vote_Handler, NativeVotesType_ChgLevel);
    vote.SetDetails(map_name);
    vote.Initiator = client;

    // Gets a list of players that are actually in game - not spectators.
    // Based off code from nativevotes.inc
    int total;
    int[] players = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientValid(i) || (GetClientTeam(i) < 2))
            continue;
        players[total++] = i;
    }

    // Returns true if vote has been initiated and false otherwise
    if (vote.DisplayVote(players, total, 20, VOTEFLAG_NO_REVOTES))
    {
        g_active_vote_info = pack;  // A bit of a hack to get around the fact that NativeVotes_Handler doesn't have a way to pass arbitrary data.
    }
    else
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_ExistingVote");
        delete pack;
        vote.Close();
    }
}

public int Nv_Vote_Handler(NativeVote vote, MenuAction action, int param1, int param2)
{
    // Taken from one of the comments on the NativeVotes thread on AM.
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            if (param1 == NATIVEVOTES_VOTE_YES)
            {
                // Unpack datapack
                char map_id[16];
                char map_name[64];
                g_active_vote_info.Reset();
                int user_id = g_active_vote_info.ReadCell();                // Cell 1: User ID of player initiating vote
                g_active_vote_info.ReadString(map_id, sizeof(map_id));      // Cell 2: Map ID as a string
                g_active_vote_info.ReadString(map_name, sizeof(map_name));  // Cell 3: Map name

                // Attempt to preload map ahead of time.
                ServerCommand("tf_workshop_map_sync \"%s\"", map_id);

                vote.DisplayPass(map_name);

                float delay = GetConVarFloat(g_mapchange_delay);

                // Warn the person who initiated the vote that sometimes the map fails to change
                // I'm not 100% certain why this happens but it looks to be downloads failing for some reason.
                // Either way, warn them so that they know to give it a second try if it happens.
                //
                // I also think its fine if they left or leave after this point, too, since the vote passed.
                int initiator_client = GetClientOfUserId(user_id);
                if (IsClientValid(initiator_client))
                    PrintHintText(initiator_client, "%t", "WsVote_CallVote_FailWarning");

                CPrintToChatAll("{gold}[Workshop]{default} %t", "WsVote_CallVote_VotePass", map_name, RoundToNearest(delay));

                // Create a new DataPack containing just the map id to pass through the timer.
                // This allows g_active_vote_info to always be cleared when vote ends and not be worried about any further.
                // Otherwise, clearing is complicated. It's not untennable by any means, but this is less easy to screw up.
                // See: How to use CreateDataTimer: https://discord.com/channels/335290997317697536/335290997317697536/1154405516546686996
                DataPack newpack;
                CreateDataTimer(delay, Timer_ChangeLevel, newpack);
                newpack.WriteString(map_id);
            }
            else
            {
                vote.DisplayFail(NativeVotesFail_Loses);
            }
        }

        case MenuAction_VoteCancel:
        {
            if (param1 == VoteCancel_NoVotes)
                vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
            else
                vote.DisplayFail(NativeVotesFail_Generic);
        }

        case MenuAction_End:
        {
            vote.Close();
            delete g_active_vote_info;
        }
    }

    return 0;
}

public Action Timer_ChangeLevel(Handle timer, DataPack pack)
{
    char map_id[16];
    pack.Reset();
    pack.ReadString(map_id, sizeof(map_id));

    ServerCommand("changelevel \"workshop/%s\"", map_id);

    return Plugin_Handled;
}

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) &&
           IsClientInGame(client) &&
           !IsFakeClient(client) &&
           !IsClientInKickQueue(client);
}
