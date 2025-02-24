/**
 * ======================================================================
 * Gag me Harder
 * Copyright (C) 2025 llamasking
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

#include <basecomm>
#include <multicolors>
#include <sourcemod>

#define VERSION "1.0"

enum messageType
{
    // Spectators are always considered dead
    // Bit 1: Is Dead
    // Bit 2: Is Spectator
    // Bit 3: Is Team Chat
    TF_Chat_All       = 0b000,
    TF_Chat_AllDead   = 0b001,
    TF_Chat_AllSpec   = 0b011,
    TF_Chat_Team      = 0b100,
    TF_Chat_Team_Dead = 0b101,
    TF_Chat_Spec      = 0b111,
};

public Plugin myinfo =
{
        name        = "Gag Me Harder",
        author      = "llamasking",
        description = "Allows gagged players to continue to chat, but only with text replaced with hearts.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins",
};

public void OnPluginStart()
{
    LoadTranslations("gag_me_harder.phrases.txt");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (IsClientInGame(client) && BaseComm_IsClientGagged(client))
    {
        // Client is gagged

        // Converts message to just hearts
        char sMsg[MAX_MESSAGE_LENGTH];
        for (int i = 0; i < strlen(sArgs); i++)
        {
            if (IsCharSpace(sArgs[i]))
                StrCat(sMsg, sizeof(sMsg), " ");
            else
                StrCat(sMsg, sizeof(sMsg), "♥");
        }

        // Name of message author
        char sName[32];
        GetClientName(client, sName, sizeof(sName));

        // Figure out what type of chat this is.
        int type = 0;
        type |= view_as<int>(!IsPlayerAlive(client)) << 0;
        type |= view_as<int>(GetClientTeam(client) <= 1) << 1;  // TFTeam_Unassigned, TFTeam_Spectator
        type |= view_as<int>(StrEqual(command, "say_team", false)) << 2;

        // Enum becomes translation key.
        char tKey[18];
        switch (type)
        {
            case TF_Chat_All:
                strcopy(tKey, sizeof(tKey), "TF_Chat_All");
            case TF_Chat_AllDead:
                strcopy(tKey, sizeof(tKey), "TF_Chat_AllDead");
            case TF_Chat_AllSpec:
                strcopy(tKey, sizeof(tKey), "TF_Chat_AllSpec");
            case TF_Chat_Team:
                strcopy(tKey, sizeof(tKey), "TF_Chat_Team");
            case TF_Chat_Team_Dead:
                strcopy(tKey, sizeof(tKey), "TF_Chat_Team_Dead");
            case TF_Chat_Spec:
                strcopy(tKey, sizeof(tKey), "TF_Chat_Spec");
            default:
                strcopy(tKey, sizeof(tKey), "TF_Chat_All");
        }

        // Prints out message
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientValid(i))
                CPrintToChatEx(i, client, "%t", tKey, sName, sMsg);

        return Plugin_Handled;
    }

    return Plugin_Continue;
}

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) &&
           IsClientInGame(client) &&
           !IsFakeClient(client) &&
           !IsClientInKickQueue(client);
}
