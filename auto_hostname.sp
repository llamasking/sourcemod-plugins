#include <sourcemod>

#define VERSION "1.0"

public Plugin myinfo =
{
    name = "Auto Hostname",
    author = "llamasking",
    description = "Automatically generates the server's hostname after each map change.",
    version = VERSION,
    url = "none"
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
    CreateConVar("sm_hostname_version", VERSION, "Plugin version.", FCVAR_DONTRECORD);

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "auto_hostname.cfg");
}

public void OnMapStart()
{
    // Check if plugin is enabled
    if(GetConVarBool(g_enabled))
    {
        // Get map name maybe workshops work, too. Idk.
        char g_map[512];
        GetCurrentMap(g_map, sizeof(g_map));
        GetMapDisplayName(g_map, g_map, sizeof(g_map));

        LogMessage("===== MapA: %s =====", g_map);

        // Break apart the map name
        int i = StrContains(g_map, "_") + 1;
        char exploded[8][32];
        ExplodeString(g_map[i], "_", exploded, 8, 32);

        // Capitalize things!
        for(i = 0; i < sizeof(exploded); i++)
        {
            exploded[i][0] = CharToUpper(exploded[i][0]);
        }

        // Recombine the map name
        ImplodeStrings(exploded, 8, " ", g_map, strlen(g_map));

        // Remove "final" and "rc" from suffix if it's there.
        SplitString(g_map, " Final", g_map, strlen(g_map));
        SplitString(g_map, " Rc", g_map, strlen(g_map));

        // Declare some stuff before changing the hostname
        char pfx[32];
        char sfx[32];

        // Finally, actually change the hostname.
        GetConVarString(g_prefix, pfx, sizeof(pfx))
        GetConVarString(g_suffix, sfx, sizeof(sfx))
        ServerCommand("hostname \"%s %s %s\"", pfx, g_map, sfx);
    }
}