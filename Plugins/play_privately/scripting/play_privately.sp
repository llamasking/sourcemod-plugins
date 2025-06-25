/**
 * ======================================================================
 * Plugin
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

#include <multicolors>
#include <sourcemod>

#define VERSION         "1.0.0"
#define PASSWORD_LENGTH 6

public Plugin myinfo =
{
        name        = "Play Privately",
        author      = "llamasking",
        description = "Allows the server to be taken private (password locked).",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins",
};

ConVar g_cIsPrivate;   // Cvar: sm_private_active
ConVar g_cSvPassword;  // Cvar: sv_password
char g_sPassword[PASSWORD_LENGTH + 1] = {'\0', ...};

public void OnPluginStart()
{
    // ConVars
    CreateConVar("sm_play_private_version", VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
    g_cIsPrivate = CreateConVar("sm_private_active", "0", "When enabled, sets the server password to a random set of characters. When disabled, wipes the password.", _, true, 0.0, true, 1.0);

    HookConVarChange(g_cIsPrivate, OnPrivateHook);

    // Password reminder command
    RegConsoleCmd("sm_password", Command_PassReminder, "Get a reminder of the server password.");

    // Retrieve server password if set (for plugin reload)
    g_cSvPassword = FindConVar("sv_password");
    g_cSvPassword.GetString(g_sPassword, sizeof(g_sPassword));

    // Load translations.
    LoadTranslations("play_privately.phrases.txt");
}

void OnPrivateHook(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_cIsPrivate.BoolValue)
    {
        // Generate random password
        for (int i = 0; i < PASSWORD_LENGTH; i++)
            g_sPassword[i] = 'A' + GetRandomInt(0, 25);

        // The array is zero-filled so the final element should always be '\0', but let's be absolutely, positively, completely sure.
        // If this ever actually does something, something must have gone catastrophically wrong.
        g_sPassword[PASSWORD_LENGTH] = '\0';

        // Set password
        g_cSvPassword.SetString(g_sPassword);

        CPrintToChatAll("%t %t", "PP_Prefix", "PP_Server_NowPrivate", g_sPassword);
    }
    else
    {
        // Clear password
        g_cSvPassword.SetString("");
        g_sPassword[0] = '\0';

        CPrintToChatAll("%t %t", "PP_Prefix", "PP_Server_NowPublic");
    }
}

Action Command_PassReminder(int client, int args)
{
    if (g_cIsPrivate.BoolValue)
        CReplyToCommand(client, "%t %t", "PP_Prefix", "PP_Password_Reminder", g_sPassword);
    else
        CReplyToCommand(client, "%t %t", "PP_Prefix", "PP_Password_Reminder_NoPass");

    return Plugin_Handled;
}
