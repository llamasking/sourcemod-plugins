/*
    Private Analytics -
    Copyright (C) 2020 - llamasking

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, as per version 3 of the license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

/* -- Data Logging --
When a player joins, player_analytics is updated with the following.
- Server IP
- Unix Timestamp
- Player Count
- Map
- Country

When a player BOTH joins AND leaves, player_count is updated with the following.
- Server IP
- Unix Timestamp
- Player Count
- Map
*/

// This plugin is made to fit my needs. If it does not fit yours, that is not my problem.

#pragma semicolon 1
#include <sourcemod>
#include <geoip>
#undef REQUIRE_PLUGIN
#include <updater>

#define VERSION "0.1.0"
//#define DEBUG
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/updater/PrivateAnalytics/updatefile.txt"

public Plugin myinfo =
{
    name = "Private Analytics",
    author = "llamasking",
    description = "An alternative to Dr. McKay's Player Analytics that does not log identifiable information.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins"
}

/* Database */
Database g_db = null;

/* Etc */
char g_ip[32];

public void OnPluginStart()
{
    // ConVars
    CreateConVar("sm_analytics_version", VERSION, "Plugin version.", FCVAR_NOTIFY);

    if(!SQL_CheckConfig("priv_analytics"))
        SetFailState("Database 'priv_analytics' not found in databases.cfg!");

    // Get server ip and store globally so that it doesn't have to be redetermined each time someone connects.
    int ip = GetConVarInt(FindConVar("hostip"));
    Format(g_ip, sizeof(g_ip), "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >>  8) & 0xFF, ((ip & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    // Create tables if it doesn't already exist.
    Database.Connect(ConnectCallback, "priv_analytics");

    // Updater
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

// Updater
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

// Initial database connection
public void ConnectCallback(Database db, const char[] error, any data)
{
    if(db == null)
    {
        LogError("Could not connect to database: %s", error);
    }
    else
    {
        g_db = db;

        // Create table if it doesn't already exist.
        g_db.Query(SQLCallback, "CREATE TABLE IF NOT EXISTS `player_analytics` (`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,`server_ip` varchar(32) NOT NULL,`connect_time` int NOT NULL,`numplayers` tinyint NOT NULL,`map` varchar(64) NOT NULL,`country` varchar(45) NULL,`country_code` varchar(2) NULL,`country_code3` varchar(3) NULL);");
        g_db.Query(SQLCallback, "CREATE TABLE IF NOT EXISTS `player_count` (`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,`server_ip` varchar(32) NOT NULL,`time` int NOT NULL,`numplayers` tinyint NOT NULL,`map` varchar(64) NOT NULL);");
    }
}

public void OnClientConnected(int client)
{
    // Ignore fake clients, but only when they're connecting.
    if(IsFakeClient(client))
        return;

    // Declare
    char time[11];
    char map[64];
    char country[45];
    char country_code[3];
    char country_code3[4];
    char player_count[2];

    // Get time
    IntToString(GetTime(), time, sizeof(time));

    // Get map
    GetCurrentMap(map, sizeof(map));
    GetMapDisplayName(map, map, sizeof(map));

    // Get country
    char ip[16];
    GetClientIP(client, ip, sizeof(ip));
    GeoipCountry(ip, country, sizeof(country));
    GeoipCode2(ip, country_code);
    GeoipCode3(ip, country_code3);

    // Get player count
    IntToString(GetPlayerCount(), player_count, sizeof(player_count));

    // Query
    char query[512];
    Format(query, sizeof(query), "INSERT INTO `player_analytics` SET server_ip = '%s', connect_time = %s, numplayers = %s, map = '%s', country = '%s', country_code = '%s', country_code3 = '%s';",
        g_ip, time, player_count, map, country, country_code, country_code3);
    g_db.Query(SQLCallback, query);

    #if defined DEBUG
    LogMessage("Query: %s", query);
    #endif

    // Update player count table as well.
    UpdatePlayerCount(false);
}

public void OnClientDisconnect(int client)
{
    UpdatePlayerCount(true);
}

public void UpdatePlayerCount(bool isDisconnecting)
{
    // Declare
    char time[11];
    char map[64];
    char player_count[2];

    // Get time
    IntToString(GetTime(), time, sizeof(time));

    // Get map
    GetCurrentMap(map, sizeof(map));
    GetMapDisplayName(map, map, sizeof(map));

    // Get player count
    if(isDisconnecting)
    {
        // Client is disconnecting
        IntToString(GetPlayerCount() - 1, player_count, sizeof(player_count));
    }
    else
    {
        // Client is connecting
        IntToString(GetPlayerCount(), player_count, sizeof(player_count));
    }

    // Query
    char query[512];
    Format(query, sizeof(query), "INSERT INTO `player_count` SET server_ip = '%s', time = %s, numplayers = %s, map = '%s';",
        g_ip, time, player_count, map);
    g_db.Query(SQLCallback, query);

    #if defined DEBUG
    LogMessage("Query: %s", query);
    #endif
}

// Returns the number of players in game.
public int GetPlayerCount() {
    int players = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
            players++;
    }

    return players;
}

public void SQLCallback(Database db, DBResultSet results, const char[] error, any data)
{
}
