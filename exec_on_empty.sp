#include <sourcemod>

#define MAX_ID_STRING 6
#define VERSION "1.1"

public Plugin myinfo =
{
    name = "Execute on Empty",
    author = "llamasking",
    description = "Executes a config whenever the server is empty.",
    version = VERSION,
    url = "none"
}

ConVar g_enabled;       // Whether or not the plugin is on
ConVar g_config;        // Config file to load

new g_players;          // Player count
Handle g_playerIDs;     // List of player IDs

public void OnPluginStart()
{
    // Create ConVars
    g_enabled = CreateConVar("sm_empty_enabled", "1", "Whether or not the plugin is enabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_config  = CreateConVar("sm_empty_config", "", "The config to run when the server is empty.", FCVAR_PROTECTED);
    CreateConVar("sm_empty_version", VERSION, "Plugin version.", FCVAR_DONTRECORD);

    // Create table of IDs
    g_playerIDs = CreateTrie();

    // Hook the disconnect event.
    HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Post);

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "exec_on_empty.cfg");
}

public void OnClientConnected(int client)
{
    char playerID_s[MAX_ID_STRING];

    // Filter fake clients
    if(!client || IsFakeClient(client))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), playerID_s, MAX_ID_STRING);

    // Check if player is already in the list of IDs
    if(SetTrieValue(g_playerIDs, playerID_s, 1, false))
    {
        g_players++;
    }

    return;
}

public Action event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    char playerID_s[MAX_ID_STRING];

    // Get the player ID as an integer then as a string
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    new playerID = GetClientUserId(client);
    IntToString(playerID, playerID_s, MAX_ID_STRING);

    // Filter fake clients
    if (!playerID || IsFakeClient(client))
        return;

    // Try to remove the player ID from the list of IDs
    if(RemoveFromTrie(g_playerIDs, playerID_s))
    {
        g_players--;

        // If there are no players left in the server and plugin is enabled
        if((g_players == 0) && GetConVarBool(g_enabled))
        {
            // Apparently there's issues if you do this immediately.
            CreateTimer(0.5, ExecCfg);
        }
    }
}

public Action ExecCfg(Handle timer)
{
    char cfg[PLATFORM_MAX_PATH];

    GetConVarString(g_config, cfg, sizeof(cfg));
    ServerCommand("exec \"%s\"", cfg);
}