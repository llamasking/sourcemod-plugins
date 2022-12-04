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

#define VERSION "1.1.4"

public Plugin myinfo =
{
    name        = "Auto Hostname",
    author      = "llamasking",
    description = "Automatically generates the server's hostname after each map change.",
    version     = VERSION,
    url         = "https://github.com/llamasking/sourcemod-plugins",


}

ConVar g_enabled;
ConVar g_prefix;
ConVar g_suffix;
Handle g_activeTimer = INVALID_HANDLE;

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
    // Abort a pending update if one exists
    if (g_activeTimer != INVALID_HANDLE)
        CloseHandle(g_activeTimer);

    // Wait a little bit before updating the hostname. That way other configs can make their changes to the convars.
    g_activeTimer = CreateTimer(0.5, UpdateHostname);
}

public void OnConfigsExecuted()
{
    // Abort a pending update if one exists
    if (g_activeTimer != INVALID_HANDLE)
        CloseHandle(g_activeTimer);

    // Because copy paste.
    g_activeTimer = CreateTimer(0.5, UpdateHostname);
}

public Action UpdateHostname(Handle timer)
{
    // Reset timer
    g_activeTimer = INVALID_HANDLE;

    // Check if plugin is enabled
    if (GetConVarBool(g_enabled))
    {
        char s_map[256];
        GetCurrentMap(s_map, sizeof(s_map));               // Get map name. (itemtest, ctf_2fort)
        GetMapDisplayName(s_map, s_map, sizeof(s_map));    // Strip prefix and suffix that exists on workshop maps. (itemtest, ctf_2fort)

        // Split name across underscores
        // Also skips over the first underscore ('ctf_2fort' effectively gets skipped to become '2fort' but maps without an underscore are unaffected)
        int  index = StrContains(s_map, "_") + 1;
        char exploded[8][32];    // 8 strings of 32 length
        ExplodeString(s_map[index], "_", exploded, sizeof(exploded), 32);

        // Note that the above line (ExplodeString) is visually incredibly unusual.
        // It took me two years to notice this, but where you might otherwise expect 's_map[index]' to read the char
        // value off of the 's_map' array and pass it as a literal, its instead passing a reference to the
        // 's_map' array offset by 'index' items. Its vaguely similar to if you did 's_map[index:]' in Python.

        // Capitalize things!
        for (int i = 0; i < sizeof(exploded); i++)
            exploded[i][0] = CharToUpper(exploded[i][0]);

        // Recombine the map name
        ImplodeStrings(exploded, sizeof(exploded), " ", s_map, sizeof(s_map));

        // Remove "final" and "rc" from suffix if it's there.
        SplitString(s_map, " Final", s_map, sizeof(s_map));
        SplitString(s_map, " Rc", s_map, sizeof(s_map));

        // Trim whitespace
        TrimString(s_map);

        // Get hostname prefix and suffix
        char pfx[256];
        char sfx[256];
        GetConVarString(g_prefix, pfx, sizeof(pfx));
        GetConVarString(g_suffix, sfx, sizeof(sfx));

        // Construct final hostname
        char hostname[256];
        Format(hostname, sizeof(hostname), "%s %s %s", pfx, s_map, sfx);

        // Sanitize potentially dangerous hostnames
        // It may not even be possible to have a map name such as `cp_dangerous"; arbitrary_command...`
        // But lets err on the side of caution.
        ReplaceString(hostname, sizeof(hostname), ";", "");

        // Finally, update the hostname.
        ServerCommand("hostname \"%s\"", hostname);
    }

    return Plugin_Stop;
}