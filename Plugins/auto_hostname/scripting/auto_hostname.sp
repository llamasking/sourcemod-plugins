/**
 * ======================================================================
 * Auto Hostname
 * Copyright (C) 2020-2024 llamasking
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

#include <sourcemod>

#define VERSION "1.2.1"

public Plugin myinfo =
{
        name        = "Auto Hostname",
        author      = "llamasking",
        description = "Automatically generates the server's hostname after each map change.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins"
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
    UpdateHostname();
}

public void OnConfigsExecuted()
{
    UpdateHostname();
}

public void UpdateHostname()
{
    // Check if plugin is enabled
    if (GetConVarBool(g_enabled))
    {
        char s_map[128];
        GetCurrentMap(s_map, sizeof(s_map));             // Get map name.
        GetMapDisplayName(s_map, s_map, sizeof(s_map));  // Strip 'workshop/' prefix and '.ugc000000' suffix that exist on workshop maps.

        // Split name across underscores
        // Also skips over the first underscore. (The 'ctf' from 'ctf_2fort' gets skipped over when exploding. Maps without an underscore are unaffected.)
        int index = StrContains(s_map, "_") + 1;
        char exploded[8][32];  // 8 strings of 32 length each
        ExplodeString(s_map[index], "_", exploded, sizeof(exploded), 32);

        // Note that the above line (ExplodeString) is visually incredibly unusual.
        // It took me two years to notice this, but where you might otherwise expect 's_map[index]' to read the char
        // value off of the 's_map' array and pass it as a literal, it's instead passing a reference to the
        // 's_map' array offset by 'index' items. It's vaguely similar to if you did 's_map[index:]' in Python.

        // Capitalize things!
        for (int i = 0; i < sizeof(exploded); i++)
            exploded[i][0] = CharToUpper(exploded[i][0]);

        // Remove "final" and "rc" suffixes if they're used.
        int recombineLen = sizeof(exploded);
        if (StrEqual(exploded[recombineLen - 1], "Final") || StrEqual(exploded[recombineLen - 1], "Rc"))
            recombineLen--;

        // Recombine the map name
        ImplodeStrings(exploded, recombineLen, " ", s_map, sizeof(s_map));

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
        // It is probably not even be possible to have a map name such as `cp_dangerous"; arbitrary_command...`
        // but let's err on the side of caution.
        ReplaceString(hostname, sizeof(hostname), ";", "");
        ReplaceString(hostname, sizeof(hostname), "\"", "");
        ReplaceString(hostname, sizeof(hostname), "\\", "");

        // Finally, update the hostname.
        ServerCommand("hostname \"%s\"", hostname);
    }
}
