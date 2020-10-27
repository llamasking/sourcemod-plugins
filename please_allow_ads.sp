/*
    Please Allow Ads - A plugin that does nothing more than ask that players allow ads.
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

#define VERSION "1.0.0"
#define MAX_ID_STRING 6

public Plugin myinfo =
{
    name = "Please Allow Ads",
    author = "llamasking",
    description = "A plugin that does nothing more than ask that players allow ads.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins"
}

/* ConVars */
ConVar g_time;
ConVar g_message;

public void OnPluginStart()
{
    g_time = CreateConVar("sm_askads_time", "15", "The amount of time to wait before notifying the player.", _, true, 0.0);
    g_message = CreateConVar("sm_askads_message", "{yellow}[Ads]{default} This server is funded through advertisements. Please consider allowing html motds to support us.");
    CreateConVar("sm_askads_version", VERSION, "Plugin version.", FCVAR_NOTIFY);

    AutoExecConfig();
}

public void OnClientPutInServer(int client)
{
    if(IsFakeClient(client))
        return;

    // Ignore players with advertisement immunity.
    if(!CheckCommandAccess(client, "MOTDGD_Immunity", ADMFLAG_RESERVATION))
        QueryClientConVar(client, "cl_disablehtmlmotd", QueryCallback);
}

public void QueryCallback(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    // Ignore if query failed.
    if(result == ConVarQuery_Okay)
    {
        // Timer to ask players with html motds off to turn them on.
        int val = StringToInt(cvarValue);
        if(val == 1)
        {
            CreateTimer(GetConVarFloat(g_time), PleaseAllowAds, GetClientUserId(client));
        }
    }
}

// Send message.
public Action PleaseAllowAds(Handle timer, any data)
{
    int client = GetClientOfUserId(data);

    char msg[MAX_BUFFER_LENGTH];
    GetConVarString(g_message, msg, sizeof(msg));

    CPrintToChat(client, msg);
}