/*  Retry On Restart
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define DEBUG
#define VERSION "1.3.1"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/retry_on_restart/updatefile.txt"

#if !defined DEBUG
#undef REQUIRE_PLUGIN
#include <updater>
#endif

ConVar cvar_enabled;
ConVar cvar_delay;
ConVar cvar_restart_time;
ConVar cvar_restart_warn;
Handle timer_auto_restart;

public Plugin myinfo =
{
    name = "Retry On Restart",
    author = "Franc1sco franug, Derek D. Howard, and llamasking",
    version = VERSION,
    description = "Forces clients to attempt to reconnect when the server restarts",
    url = "https://github.com/llamasking/sourcemod-plugins"
};

public void OnPluginStart() {
    CreateConVar("sm_retryonrestart", VERSION, _, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cvar_enabled      = CreateConVar("sm_retryonrestart_enabled", "1", _, _, true, 0.0, true, 1.0);
    cvar_delay        = CreateConVar("sm_retryonrestart_delay", "0.1", _, _, true, 0.0);
    cvar_restart_time = CreateConVar("sm_autorestart_time", "0400", "Automatically restart the server at this time. Formatted as HHMM (24-hour time). Set to -1 to disable.", _, true, -1.0, true, 2359.0);
    cvar_restart_warn = CreateConVar("sm_autorestart_warning_time", "30", "A warning will display this many seconds before the server restarts. Set to 0 to disable.", _, true, -1.0);

    RegServerCmd("quit", OnDown);
    RegServerCmd("_restart", OnDown);
    RegAdminCmd("sm_retryandrestart", RestartServerCmd, ADMFLAG_RCON, "Forces all players to RETRY connection, and restarts the server. Optionally, pass the argument 'false' to NOT recoonect players.");
    RegAdminCmd("sm_schedulerestart", ScheduleRestartCmd, ADMFLAG_RCON, "Schedules a restart to occur in X seconds.");

    // Load config values.
    AutoExecConfig();

    HookConVarChange(cvar_restart_time, CvarChanged);
    HookConVarChange(cvar_restart_warn, CvarChanged);

    #if !defined DEBUG
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    #endif
}

#if !defined DEBUG
public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}
#endif

public Action OnDown(int args)
{
    if(GetConVarBool(cvar_enabled))
    {
        LogAction(-1, -1, "A server restart was initiated. Attempting to reconnect all players.");
        for(int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                ClientCommand(i, "retry"); // force retry
            }
        }
    }
}

public Action RestartServerCmd(int client, int args)
{
    // Ignore any future restart commands.
    SetConVarBool(cvar_enabled, false);

    if (args > 0)
    {
        char arg[4];
        GetCmdArg(1, arg, sizeof(arg));

        if (strcmp(arg, "false"))
        {
            LogAction(client, -1, "\"%L\" restarted the server, and did not try to auto-reconnect all players.", client);
            ServerCommand("_restart");
        }
        else
        {
            RetryAndRestart(client);
        }
    }
    else
    {
        RetryAndRestart(client);
    }

    return Plugin_Handled;
}

public Action ScheduleRestartCmd(int client, int args)
{
    if (args > 0 && GetConVarBool(cvar_enabled))
    {
        char buffer[32];
        GetCmdArg(1, buffer, sizeof(buffer));
        float delay = StringToFloat(buffer);

        LogAction(client, -1, "\"%L\" scheduled a server restart for %.0f seconds from now.", client, delay);
        PrintToChatAll("A restart has been scheduled for %.0f seconds from now. Please do not disconnect. You will automatically be reconnected.", delay);

        CreateTimer(delay, HandleScheduledRestart, client);
    }
    else
    {
        ReplyToCommand(client, "Please specify the delay (in seconds) for the server to restart in.");
    }

    return Plugin_Handled;
}

public Action HandleScheduledRestart(Handle timer, any client)
{
    LogAction(client, -1, "\"%L\"'s scheduled restart has occurred. Attempting to reconnect all players.", client);

    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            ClientCommand(i, "retry"); // force retry
        }
    }

    float delay = GetConVarFloat(cvar_delay);
    if (delay == 0.0)
    {
        ServerCommand("_restart");
    }
    else
    {
        CreateTimer(delay, DoRestart);
    }
}

public void RetryAndRestart(int client)
{
    LogAction(client, -1, "\"%L\" restarted the server. Attempting to reconnect all players.", client);

    for(int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            ClientCommand(i, "retry"); // force retry
        }
    }

    float delay = GetConVarFloat(cvar_delay);
    if (delay == 0.0)
    {
        ServerCommand("_restart");
    }
    else
    {
        CreateTimer(delay, DoRestart);
    }
}

public Action DoRestart(Handle timer)
{
    ServerCommand("_restart");
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CloseHandle(timer_auto_restart);

    InitiateAutoRestartTimer();
}

public void InitiateAutoRestartTimer()
{
    if(GetConVarFloat(cvar_restart_time) >= 0)
    {
        // Get current time and restart time
        char buffer[8];
        FormatTime(buffer, sizeof(buffer), "%H%M", GetTime());
        int currentTime = StringToInt(buffer);
        int restartTime = GetConVarInt(cvar_restart_time);

        // Handle if the restart time is in a future day. (Ex. its 2300 and the server is set to restart at 0400)
        if(currentTime >= restartTime)
            restartTime += 2400;

        // Break time into hours in minuites.
        int currentHour = currentTime / 100;
        int currentMin  = currentTime % 100;
        int restartHour = restartTime / 100;
        int restartMin  = restartTime % 100;

        // Curse whoever decided on the 24 hour day and 60 minute hour.
        // These timestamps are my own special breed of stupid used exclusively to calculate the delay.
        int currentTimestamp = (currentHour * 60) + (currentMin);
        int restartTimestamp = (restartHour * 60) + (restartMin);
        float delay = (restartTimestamp - currentTimestamp) * 60.0;

        float warningTime = GetConVarFloat(cvar_restart_warn);
        if(warningTime != 0.0)
            delay -= warningTime;

        #if defined DEBUG
        PrintToChatAll("---\n\
        Current time: %04i (%04i).\n\
        Restart Time: %04i (%04i).\n\
        Restart In: %.0f seconds.",
        currentTime, currentTimestamp, restartTime, restartTimestamp, delay);
        #endif

        timer_auto_restart = CreateTimer(delay - warningTime, DoAutoRestartWarn, warningTime);
    }
}

// Having these two is unfortunately required. Otherwise, things run out of order which may potentially lead to clients not reconnecting.
public Action DoAutoRestartWarn(Handle timer, any warningTime)
{
    LogAction(0, -1, " The server will automatically restart in %.0f seconds. Connected players should reconnect.", warningTime);
    PrintToChatAll("The server will restart in %.0f seconds. Please do not disconnect. You will automatically be reconnected.", warningTime);
    timer_auto_restart = CreateTimer(warningTime, DoAutoRestart);
}

public Action DoAutoRestart(Handle timer, any warningTime)
{
    RetryAndRestart(0);
}
