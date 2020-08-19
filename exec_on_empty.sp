#include <sourcemod>

#define MAX_ID_STRING 6
#define VERSION "1.3"

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
ConVar g_debug;         // Whether or not debug mode is on

int g_players;          // Player count
Handle g_playerIDs;     // List of player IDs

public void OnPluginStart()
{
    // Create ConVars
    g_enabled = CreateConVar("sm_empty_enabled", "1", "Whether or not the plugin is enabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_config  = CreateConVar("sm_empty_config", "", "The config to run when the server emptys.", FCVAR_PROTECTED);
    g_debug   = CreateConVar("sm_empty_debug", "0", "Log extra things to console.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    CreateConVar("sm_empty_version", VERSION, "Plugin version.", FCVAR_DONTRECORD);

    // Create table of IDs
    g_playerIDs = CreateTrie();

    // Hook the disconnect event.
    HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Post);

    // Register the "it's broken" command
    RegAdminCmd("sm_empty_thefuck", Command_TheFuck, ADMFLAG_GENERIC, "It's broken! What's going on?!");

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "exec_on_empty.cfg");
}

public void OnClientConnected(int client)
{
    char playerID_s[MAX_ID_STRING];
    //char auth[MAX_ID_STRING];

    // Filter fake clients
    //GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
    //if(StrEqual(auth, "BOT"))
    if(!client || IsFakeClient(client))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), playerID_s, sizeof(playerID_s));

    // Check if player is already in the list of IDs
    if(SetTrieValue(g_playerIDs, playerID_s, 1, false))
    {
        g_players++;

        // Debug logging
        if(GetConVarBool(g_debug)) {
            char g_players_s[4];
            IntToString(g_players, g_players_s, sizeof(g_players_s));
            LogMessage("Player connected! Count: %s", g_players_s);
        }
    }

    return;
}

public Action event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    char playerID_s[MAX_ID_STRING];

    // Get the client ID
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Filter fake clients
    if(!client || IsFakeClient(client))
        return;

    // Get the client ID as a string
    new playerID = GetClientUserId(client);
    IntToString(playerID, playerID_s, sizeof(playerID_s));

    // Filter fake clients
    if (!playerID || IsFakeClient(client))
        return;

    // Try to remove the player ID from the list of IDs
    if(RemoveFromTrie(g_playerIDs, playerID_s))
    {
        g_players--;

        // Debug logging
        if(GetConVarBool(g_debug)) {
            char g_players_s[4];
            IntToString(g_players, g_players_s, sizeof(g_players_s));
            LogMessage("Player disconnected! Count: %s", g_players_s);
        }

        // If there are no players left in the server and plugin is enabled
        if(GetConVarBool(g_enabled) && (g_players == 0))
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

public Action Command_TheFuck(int client, int args)
{
    char g_players_s[4];
    IntToString(g_players, g_players_s, sizeof(g_players_s));
    ReplyToCommand(client, "Count: %s", g_players_s);
}