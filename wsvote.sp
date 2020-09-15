/*
    Workshop Map Vote
    Copyright (C) 2020 - llamasking

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, as per version 3 of the license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#include <nativevotes>
#include <SteamWorks>

//#define DEBUG
#define VERSION "1.0.0"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/updater/WorkshopVote/updatefile.txt"

#if !defined DEBUG
#undef REQUIRE_PLUGIN
#include <updater>
#endif

public Plugin myinfo =
{
    name = "Workshop Map Vote",
    author = "llamasking",
    description = "Allows players to call votes to change to workshop maps.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins"
}

/* Global Variables */
char g_mapid[16];
char g_mapname[64];

/* ConVars */
ConVar g_minsubs;

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
    CreateConVar("sm_workshop_version", VERSION, "Plugin Version", FCVAR_NOTIFY);
    g_minsubs = CreateConVar("sm_workshop_min_subs", "50", "The minimum number of current subscribers for a workshop item.");

    // Load config values.
    AutoExecConfig();

    // Register commands.
    RegConsoleCmd("sm_wsmap", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_wsvote", Command_WsVote, "Call a vote to change to a workshop map.");

    // Updater
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action Command_WsVote(int client, int args)
{
    // Ignore console/rcon and spectators.
    if (client == 0 || GetClientTeam(client) < 2)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} Spectators may not call votes.");
        return Plugin_Handled;
    }

    // Get workshop id and ignore if none is given.
    if (GetCmdArg(1, g_mapid, sizeof(g_mapid)) == 0 || GetCmdArgInt(1) == 0)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} A workshop map id is required.");
        return Plugin_Handled;
    }

    // Format body of request.
    char reqBody[64];
    Format(reqBody, sizeof(reqBody), "itemcount=1&publishedfileids[0]=%s&format=vdf", g_mapid);

    // Query SteamAPI.
    Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
    SteamWorks_SetHTTPRequestRawPostBody(req, "application/x-www-form-urlencoded", reqBody, strlen(reqBody));
    SteamWorks_SetHTTPRequestContextValue(req, GetClientUserId(client));
    SteamWorks_SetHTTPCallbacks(req, ReqCallback);
    SteamWorks_SendHTTPRequest(req);

    return Plugin_Handled;
}

public void ReqCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any userid)
{
    int client = GetClientOfUserId(userid);

    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        CPrintToChat(client, "{gold}[Workshop]{default} A server error has occurred. Please try again later.");
        LogError("Error on request for id: '%s'", g_mapid);
        delete req; // See notice below.
        return;
    }

    // Read response.
    int size;
    SteamWorks_GetHTTPResponseBodySize(req, size);
    char[] data = new char[size];
    SteamWorks_GetHTTPResponseBodyData(req, data, size);

    // Turn response into keyvalues.
    Handle kv = CreateKeyValues("response");
    StringToKeyValues(kv, data);

    // Move into item's subkey.
    KvJumpToKey(kv, "publishedfiledetails");
    KvJumpToKey(kv, "0");

    // Verify the item is actually for TF2 and has enough subscribers.
    // Also accidentally verifies that the id is actually a map since apparently only maps can have subscriptions.
    if (KvGetNum(kv, "consumer_app_id") != 440 || KvGetNum(kv, "subscriptions") < GetConVarInt(g_minsubs))
    {
        CPrintToChat(client, "{gold}[Workshop]{default} The given id is invalid or does not have enough subscribers.");
        return;
    }

    // Get map name!
    KvGetString(kv, "title", g_mapname, sizeof(g_mapname));

    // Initialize vote.
    Handle vote = NativeVotes_Create(Nv_Vote, NativeVotesType_ChgLevel);
    NativeVotes_SetDetails(vote, g_mapname);
    NativeVotes_SetInitiator(vote, client);

    // Gets a list of players that are actually in game - not spectators.
    // Based off code from nativevotes.inc
    int total;
    int[] players = new int[MaxClients];
    for (int i=1; i<=MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2))
            continue;
        players[total++] = i;
    }

    // Display vote or error if a vote is in progress.
    if (!NativeVotes_Display(vote, players, total, 20, VOTEFLAG_NO_REVOTES))
    {
        CPrintToChat(client, "{gold}[Workshop]{default} A vote is already in progress.");
        //NativeVotes_DisplayFail(vote, NativeVotesFail_Generic);
        return;
    }

    // NOTICE: FOR THE LOVE OF ALL THINGS YOU CARE ABOUT, DELETE HANDLES.
    // OTHERWISE IT WILL LEAK SO BADLY THAT THE SERVER WILL ALMOST IMMEDIATELY CRASH.
    delete req;
    delete kv;
}

public int Nv_Vote(Handle vote, MenuAction action, int param1, int param2)
{
    // Taken from one of the comments on the NativeVotes thread on AM.
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            if (param1 == NATIVEVOTES_VOTE_YES)
            {
                NativeVotes_DisplayPass(vote, g_mapname);

                CPrintToChatAll("{gold}[Workshop]{default} Vote passed. Map will change to '%s' in a few seconds.", g_mapname);
                #if !defined DEBUG
                CreateTimer(10.0, ChangeLevel);
                #endif
            }
            else
            {
                NativeVotes_DisplayFail(vote, NativeVotesFail_Loses);
            }
        }

        case MenuAction_VoteCancel:
        {
            if (param1 == VoteCancel_NoVotes)
            {
                NativeVotes_DisplayFail(vote, NativeVotesFail_NotEnoughVotes);
            }
            else
            {
                NativeVotes_DisplayFail(vote, NativeVotesFail_Generic);
            }
        }

        case MenuAction_End:
        {
            NativeVotes_Close(vote);
        }
    }
}

public Action ChangeLevel(Handle timer)
{
    char mapid[32];
    Format(mapid, sizeof(mapid), "workshop/%s", g_mapid);
    ForceChangeLevel(mapid, "[Workshop] Changed level by vote.");
}