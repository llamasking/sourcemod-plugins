/**
 * ======================================================================
 * Phaseout Notification
 * Copyright (C) 2024 llamasking
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

#include <multicolors>
#include <sourcemod>

#define VERSION "1.1.0"

/* ConVars */
ConVar g_cMessage;
ConVar g_cMessage2;
ConVar g_cIP;

/* Variables: Cached Data */
char g_sMessage[240];
char g_sMessage2[240];
char g_sIP[22];
bool g_bIsActive = false;

public Plugin myinfo =
{
        name        = "Phaseout Notification",
        author      = "llamasking",
        description = "Notify players of a server phaseout.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins",
};

public void OnPluginStart()
{
    g_cMessage  = CreateConVar("sm_phaseout_message", "", "The message to be sent to players notifying them the server is being phased out.", FCVAR_PROTECTED);
    g_cMessage2 = CreateConVar("sm_phaseout_message2", "", "A second message to be sent.", FCVAR_PROTECTED);
    g_cIP       = CreateConVar("sm_phaseout_new_ip", "", "IP and port to reconnect players to.", FCVAR_PROTECTED);

    g_cMessage.AddChangeHook(Callback_ConvarChanged);
    g_cMessage2.AddChangeHook(Callback_ConvarChanged);
    g_cIP.AddChangeHook(Callback_ConvarChanged);

    RegConsoleCmd("sm_hop", Command_Hop, "Reconnect player to new server IP.");
}

// Cache convar data to strings so that they do not need to be read repeatedly.
public void Callback_ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bIsActive = strlen(newValue) > 0;  // Plugin is active if convar is set to any value.

    if (convar == g_cMessage)
        strcopy(g_sMessage, sizeof(g_sMessage), newValue);
    else if (convar == g_cMessage2)
        strcopy(g_sMessage2, sizeof(g_sMessage2), newValue);
    else
        strcopy(g_sIP, sizeof(g_sIP), newValue);
}

public void OnClientPutInServer(int client)
{
    if (g_bIsActive)
        CreateTimer(30.0, Timer_NotifyPlayer, GetClientUserId(client));
}

public Action Timer_NotifyPlayer(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (IsClientValid(client))
    {
        CPrintToChat(client, g_sMessage);

        if (strlen(g_sMessage2) != 0)
            CPrintToChat(client, g_sMessage2);
    }

    return Plugin_Handled;
}

public Action Command_Hop(int client, int args)
{
    if (g_bIsActive)
        ClientCommand(client, "redirect %s", g_sIP);
    return Plugin_Handled;
}

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) &&
           IsClientInGame(client) &&
           !IsFakeClient(client) &&
           !IsClientInKickQueue(client);
}
