/**
 * ======================================================================
 * Auto Hostname
 * Copyright (C) 2020-2021 llamasking
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
#include <sourcemod>

#define VERSION "1.1.2"

public Plugin myinfo =
{
    name = "Auto Hostname",
    author = "llamasking",
    description = "Automatically generates the server's hostname after each map change.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins",
}

ConVar g_enabled;
ConVar g_prefix;
ConVar g_suffix;

public void OnPluginStart()
{
    // Create ConVars
    g_enabled = CreateConVar("sm_hostname_enabled", "1", "Whether or not the plugin is enabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_prefix  = CreateConVar("sm_hostname_prefix", "", "Everything before the map in the hostname.", FCVAR_PROTECTED);
    g_suffix  = CreateConVar("sm_hostname_suffix", "", "Everything after the map in the hostname.", FCVAR_PROTECTED);
    CreateConVar("sm_hostname_version", VERSION, "Plugin version.", FCVAR_NOTIFY);

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "auto_hostname.cfg");

    // Hook for Convar Changes
    HookConVarChange(g_prefix, OnConVarChange);
    HookConVarChange(g_suffix, OnConVarChange);
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    // Wait a little bit before updating the hostname. That way other configs can make their changes to the convars.
    CreateTimer(0.5, UpdateHostname);
}

public void OnConfigsExecuted()
{
    // Because copy paste.
    CreateTimer(0.5, UpdateHostname);
}

public Action UpdateHostname(Handle timer)
{
    // Check if plugin is enabled
    if (GetConVarBool(g_enabled))
    {
        // Get map name.
        char g_map[512];
        GetCurrentMap(g_map, sizeof(g_map));
        // Strip off suffix that exists on workshop maps.
        GetMapDisplayName(g_map, g_map, sizeof(g_map));

        // Split name across underscores
        int i = StrContains(g_map, "_") + 1;
        char exploded[8][32];
        ExplodeString(g_map[i], "_", exploded, 8, 32);

        // Capitalize things!
        for (i = 0; i < sizeof(exploded); i++)
        {
            exploded[i][0] = CharToUpper(exploded[i][0]);
        }

        // Recombine the map name
        ImplodeStrings(exploded, 8, " ", g_map, strlen(g_map));

        // Remove "final" and "rc" from suffix if it's there.
        SplitString(g_map, " Final", g_map, strlen(g_map));
        SplitString(g_map, " Rc", g_map, strlen(g_map));

        // Trim whitespace
        TrimString(g_map);

        // Declare some stuff before changing the hostname
        char pfx[256];
        char sfx[256];

        // Finally, actually change the hostname.
        GetConVarString(g_prefix, pfx, sizeof(pfx));
        GetConVarString(g_suffix, sfx, sizeof(sfx));
        ServerCommand("hostname \"%s %s %s\"", pfx, g_map, sfx);
    }
}