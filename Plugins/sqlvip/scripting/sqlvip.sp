#include <sourcemod>

#define VERSION "0"
#define DEBUG

public Plugin myinfo =
{
    name = "SQL Vip",
    author = "llamasking",
    description = "Loads a SQL database of all VIPs and assigns them to a VIP admin group.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins"
}

ConVar g_group;
Database g_db;
Handle g_interval;

public void OnPluginStart()
{
    // ConVars
    g_interval = CreateConVar("sm_vip_interval", "30", "How often (in minutes) to reload the vip list.", FCVAR_PROTECTED, true, 1.0, false);
    g_group    = CreateConVar("sm_vip_group", "VIPs", "The group to assign VIP users to.", FCVAR_PROTECTED);
    CreateConVar("sm_vip_version", VERSION, "Plugin version.", FCVAR_DONTRECORD);

    // Autogenerate and execute config.
    AutoExecConfig();

    // Load the VIP table now.
    CreateTimer(0.0, UpdateVIPs);

    // Timer to reload VIPs every 30 mins.
    CreateTimer(60.0 * 30, UpdateVIPs, _, TIMER_REPEAT);

    // I mean, timer's already started and I'm not bothered to write a shit load of things around this.
    CloseHandle(g_interval);
}

public void OnRebuildAdminCache(AdminCachePart part)
{
    if (part == AdminCache_Admins)
        CreateTimer(0.0, UpdateVIPs);
}

// Connect to DB and reload VIP group.
public Action UpdateVIPs(Handle timer)
{
    // Check for vip in databases.cfg.
    if(!SQL_CheckConfig("vip"))
    {
        LogError("Could not find 'vip' in databases.cfg.")
        SetFailState("Could not find 'vip' in databases.cfg.");
        return;
    }

    Database.Connect(ConnectCallback, "vip");

    // Since we only need the database once every X interval, I figure it's better to drop the connection and just reconnect next interval.
    CloseHandle(g_db);
}

// Once connected to database, make the global database variable the connection.
public void ConnectCallback(Database db, const char[] error, data)
{
    if(!db)
    {
        LogError("Could not connect to database: %s", error);
        // SetFailState("Could not connect to database: %s", error);
        return;
    }

    g_db = db;

    // Create database table if it doesn't already exist.
    char query[255];
    FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `vips` ( \
        `steamid` varchar(32) NOT NULL, \
        `name` varchar(128) NOT NULL \
        ) ENGINE = InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;"\
    );

    g_db.Query(QueryCallback, query, 1);

    // Query database for users in the vips table.
    FormatEx(query, sizeof(query), "SELECT `steamid` FROM `vips`");
    g_db.Query(QueryCallback, query, 2);
}

public void QueryCallback(Database db, DBResultSet results, const char[] error, data)
{
    // Call out errors.
    if ((!db || !results || error[0] != '\0'))
    {
        LogError("Database Query Failed: %s", error);
        return;
    }

    // Prevent errors if there is no data.
    if(!results.HasResults)
        return;

    #if defined DEBUG
    char rc[4];
    IntToString(results.RowCount, rc, sizeof(rc));
    LogMessage("Table Rows: %s", rc)
    #endif

    // Loop through each row in the table.
    for(int i = 0; i < results.RowCount; i++)
    {
        char rowNum[4];
        IntToString(i + 1, rowNum, sizeof(rowNum));

        // Catch for possible errors if there are more results.
        results.FetchRow()

        // Check if field is null.
        if(results.IsFieldNull(0))
        {
            LogError("Error: Row %s is null.", rowNum);
            continue;
        }

        // Fetch SteamID on this row.
        char id[32];
        results.FetchString(0, id, sizeof(id));

        // Check if field is a Steam2ID.
        if(StrContains(id, "STEAM_0:") == -1)
        {
            LogError("Error: Row %s is not a Steam2ID.", rowNum);
            continue;
        }

        #if defined DEBUG
        LogMessage("Row %s: %s", rowNum, id);
        #endif
    }
}