/**
 * =============================================================================
 * Votekick Immunity
 * Causes TF2 player kick votes to obey SM immunity levels.
 *
 * (C)2011 Nicholas Hastings
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <multicolors>
#include <sourcemod>

//#define DEBUG
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name        = "Votekick Immunity",
    author      = "psychoninc & llamasking",
    description = "Causes TF2 player kick votes to obey SM immunity levels",
    version     = "1.4",
    url         = "http://nicholashastings.com"
}

int min(int a, int b) { return (((a) < (b)) ? (a) : (b)); }

public void OnPluginStart()
{
    AddCommandListener(callvote, "callvote");
}

public Action callvote(int client, const char[] cmd, int argc)
{
    #if defined DEBUG
    PrintToChatAll("[DEBUG] Vote incoming.");
    #endif

    if (argc < 2)
        return Plugin_Continue;

    // Vote Type
    char voteType[16];
    GetCmdArg(1, voteType, sizeof(voteType));

    #if defined DEBUG
    PrintToChatAll("[DEBUG] Vote type: %s", voteType);
    #endif

    if (!StrEqual(voteType, "kick", false))
    {
        #if defined DEBUG
        PrintToChatAll("[DEBUG] Vote type is not kick!");
        #endif

        return Plugin_Continue;
    }

    // Vote target
    char theRest[256];
    GetCmdArg(2, theRest, sizeof(theRest));

    #if defined DEBUG
    PrintToChatAll("[DEBUG] Vote arg 2: %s", theRest);
    #endif

    int userId   = 0;
    int spacePos = FindCharInString(theRest, ' ');
    if (spacePos > -1)
    {
        char temp[12];
        strcopy(temp, min(spacePos + 1, sizeof(temp)), theRest);
        userId = StringToInt(temp);
    }
    else
    {
        userId = StringToInt(theRest);
    }

    #if defined DEBUG
    PrintToChatAll("[DEBUG] Vote target UID: %i", userId);
    #endif

    int target = GetClientOfUserId(userId);

    #if defined DEBUG
    PrintToChatAll("[DEBUG] Vote target client: %i", target);
    #endif

    if (target == 0)
    {
        #if defined DEBUG
        PrintToChatAll("[DEBUG] Vote target invalid.");
        #endif

        return Plugin_Continue;
    }

    // Check if target is acceptable.
    AdminId callerAdmin = GetUserAdmin(client);
    AdminId targetAdmin = GetUserAdmin(target);

    if (callerAdmin == INVALID_ADMIN_ID && targetAdmin == INVALID_ADMIN_ID)
    {
        #if defined DEBUG
        PrintToChatAll("[DEBUG] Initiator and target are both non-admins. Vote continuing.");
        #endif

        return Plugin_Continue;
    }

    if (CanAdminTarget(callerAdmin, targetAdmin))
    {
        #if defined DEBUG
        PrintToChatAll("[DEBUG] Initiator can target. Vote continuing.");
        #endif

        return Plugin_Continue;
    }

    // Log blocked votekicks
    LogMessage("User '%L' attempted to votekick '%L' but was blocked.", client, target);
    CPrintToChat(target, "{fullred}[Immunity]{default} User '%L' attempted to votekick you but was blocked.", client);

    return Plugin_Handled;
}
