/**
 * ======================================================================
 * Source Metrics
 * Copyright (C) 2025 llamasking
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

#include <SteamWorks>
#include <sourcemod>

#define VERSION "1.0.0"
#define HAS_DEBUG

// Interval in seconds between each data push to prometheus.
const float METRICS_PUSH_INTERVAL = 1.0;

// When a server is lagging, it generally doesn't slow down to a consistent lower TPS, but will instead skip processing
// on some frames to make them shorter and still achieve ~66 calls to OnGameFrame per second. In this case, simply
// counting the number of frames each second will still read ~60-70 fps, but the server will be noticeably lagging.
//
// By discarding these shorter frames from calculations, we can get the "real" server TPS.
//
// This controls the minimum length of time that can be between ticks for them to be included in the calculations:
// minimum time = expected time * TICK_MIN_LENGTH_MULTIPLIER
const float TICK_MIN_LENGTH_MULTIPLIER = 0.75;

public Plugin myinfo =
{
        name        = "Source Metrics",
        author      = "llamasking",
        description = "Tickrate metrics for performance monitoring.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins"
}

ConVar g_gateway_endpoint;
#if defined HAS_DEBUG
ConVar g_debug;
#endif

// The terms 'frame' and 'tick' are interchangeable for this plugin.
float tickInterval;     // The delay intended to be between two ticks. I don't believe this can be changed as the server is running, so it's constant for our purposes.
float minGoodInterval;  // The minimum amount of time a tick can take to process before it is considered bad and discarded from calculations.
bool isPluginReady = false;

// Note: Check buffer length is long enough when updating format.
char g_pushgateway_format[] = "\
# TYPE tf_tick_processing counter\n\
# HELP tf_tick_processing Value is 1 if the server is processing or 0 if not.\n\
tf_tick_processing %b\n\
# TYPE tf_tick_count counter\n\
# HELP tf_tick_count The number of real ticks that have occurred within the last 1 second.\n\
tf_tick_count %i\n\
# TYPE tf_tick_worst_duration_seconds counter\n\
# HELP tf_tick_worst_duration_seconds The longest delay between any two ticks that occurred within the last 1 second.\n\
tf_tick_worst_duration_seconds %f\n\
# TYPE tf_tick_average_duration_seconds counter\n\
# HELP tf_tick_average_duration_seconds The average delay between any two ticks that occurred within the last 1 second.\n\
tf_tick_average_duration_seconds %f\n\
# TYPE tf_tick_desired_seconds counter\n\
# HELP tf_tick_desired_seconds The number of seconds intended to be between two ticks.\n\
tf_tick_desired_seconds %f\n\
";
char g_pushgateway_endpoint[128];

public void OnPluginStart()
{
    g_gateway_endpoint = CreateConVar("sm_metrics_endpoint", "", "Prometheus Aggregation Gateway endpoint. Server IP will be appended to the end and used to POST metrics.", FCVAR_PROTECTED);
#if defined HAS_DEBUG
    g_debug = CreateConVar("sm_metrics_debug", "0", "Print frame info to console.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
#endif
    AutoExecConfig();

    tickInterval    = GetTickInterval();
    minGoodInterval = tickInterval * TICK_MIN_LENGTH_MULTIPLIER;
}

public void OnConfigsExecuted()
{
    // Use ConVar to set pushgateway endpoint
    // Ex: "http://localhost:9091/metrics/instance/"
    g_gateway_endpoint.GetString(g_pushgateway_endpoint, sizeof(g_pushgateway_endpoint));
    if (!strlen(g_pushgateway_endpoint))
        SetFailState("sm_metrics_endpoint has not been configured.");

    // Get server IP and append to g_pushgateway_endpoint
    char s_ip[22];
    int ip   = FindConVar("hostip").IntValue;
    int port = FindConVar("hostport").IntValue;
    Format(s_ip, sizeof(s_ip), "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >> 8) & 0xFF, ((ip & 0x000000FF) >> 0) & 0xFF, port);
    StrCat(g_pushgateway_endpoint, sizeof(g_pushgateway_endpoint), s_ip);

    // The first tick(s?) as the server is starting up always have an incredibly long processing time.
    // They're unimportant, so calculations only start after this point.
    isPluginReady = true;
}

public void OnGameFrame()
{
    if (!isPluginReady)
        return;

    static float lastEngineTime;  // Engine timestamp of the last frame. Used to calculate frametime.
    static float lastUpdateTime;  // Engine timestamp as of the last time metrics were POSTed.
    static float worstFrametime;  // The longest delay between frames over the last 1 sec.
    static int frameCountValid;   // Total number of valid ticks over the last 1 sec.
#if defined HAS_DEBUG
    static int frameCountDebug;  // Total number of ticks (including invalid) over the last 1 sec.
#endif

    // GetGameFrameTime() never reports correctly, so the delay between two frames is used instead.

    // Step 1: Get duration it took to process last frame.
    float engineTime    = GetEngineTime();
    float lastFrametime = engineTime - lastEngineTime;

    // Step 2: Increment frame counters.
    if (lastFrametime >= minGoodInterval)
        frameCountValid++;
#if defined HAS_DEBUG
    frameCountDebug++;
#endif

    // Step 3: If the last frame was the worst frame in the last second, remember it's duration.
    if (lastFrametime > worstFrametime)
        worstFrametime = lastFrametime;

#if defined HAS_DEBUG
    // Step 4: (Debug) Logging.
    if (g_debug.BoolValue)
        PrintToServer("tick count=%i valid=%i timestamp=%f interval=%f frametime=%f worst=%f", frameCountDebug, frameCountValid, engineTime, tickInterval, lastFrametime, worstFrametime);
#endif

    // Step 5: If 1 second has passed, push metrics to Prometheus.
    float timeSinceLastUpdate = engineTime - lastUpdateTime;
    if (timeSinceLastUpdate >= METRICS_PUSH_INTERVAL)
    {
        float avgFrametime = timeSinceLastUpdate / frameCountValid;

        static char reqBody[844];
        Format(reqBody, sizeof(reqBody), g_pushgateway_format, IsServerProcessing(), frameCountValid, worstFrametime, avgFrametime, tickInterval);
        Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, g_pushgateway_endpoint);
        SteamWorks_SetHTTPRequestRawPostBody(req, "text/plain", reqBody, strlen(reqBody));
        SteamWorks_SetHTTPCallbacks(req, FreeHttpHandle);
        SteamWorks_SendHTTPRequest(req);

#if defined HAS_DEBUG
        if (g_debug.BoolValue)
            PrintToServer(reqBody);
#endif

        // Reset data.
        frameCountValid = 0;
        worstFrametime  = 0.0;
        lastUpdateTime  = engineTime;
#if defined HAS_DEBUG
        frameCountDebug = 0;
#endif
    }

    // Step 6: Update lastEngineTime for use next frame.
    lastEngineTime = engineTime;
}

void FreeHttpHandle(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    delete hRequest;
}
