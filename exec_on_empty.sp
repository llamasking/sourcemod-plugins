#include <sourcemod>

#define MAX_ID_STRING 6
#define VERSION "1.5"

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

int g_players;          // Player count
Handle g_clients;       // List of clients connected

public void OnPluginStart()
{
    // Create ConVars
    g_enabled = CreateConVar("sm_empty_enabled", "1", "Whether or not the plugin is enabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_config  = CreateConVar("sm_empty_config", "", "The config to run when the server emptys.", FCVAR_PROTECTED);
    CreateConVar("sm_empty_version", VERSION, "Plugin version.", FCVAR_DONTRECORD);

    // Create table of IDs
    g_clients = CreateTrie();

    // Register the "it's broken" command
    RegAdminCmd("sm_empty_thefuck", Command_TheFuck, ADMFLAG_GENERIC, "It's broken! What's going on?!");

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "exec_on_empty.cfg");
}

public void OnClientAuthorized(int client, const char[] auth)
{
    char client_s[MAX_ID_STRING];

    // Filter fake clients
    if(!client || IsFakeClient(client) || StrEqual(auth, "BOT"))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), client_s, sizeof(client_s));

    // Check if player is already in the list of IDs
    if(SetTrieValue(g_clients, client_s, 1, false))
    {
        g_players++;
    }

    return;
}

public OnClientDisconnect(int client)
{
    char client_s[MAX_ID_STRING];

    // Filter fake clients
    if(!client || IsFakeClient(client))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), client_s, sizeof(client_s));

    // Try to remove the player ID from the list of IDs
    if(RemoveFromTrie(g_clients, client_s))
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

public Action Command_TheFuck(int client, int args)
{
    char g_players_s[4];
    IntToString(g_players, g_players_s, sizeof(g_players_s));
    ReplyToCommand(client, "Count: %s", g_players_s);
}