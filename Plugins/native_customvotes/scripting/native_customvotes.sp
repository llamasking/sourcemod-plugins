/**
 * ======================================================================
 * Native Custom Votes
 * Copyright (C) 2023 llamasking
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

// This is nothing but jank. I'm so sorry.

#pragma semicolon 1
#pragma newdecls required
#include <multicolors>
#include <nativevotes>
#include <sourcemod>

//#define DEBUG
#define VERSION    "1.0.1"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/native_customvotes/updatefile.txt"

#if defined DEBUG
    #warning COMPILING IN DEBUG MODE!
#else
    #undef REQUIRE_PLUGIN
    #include <updater>
#endif

public Plugin myinfo =
{
        name        = "Native Custom Votes",
        author      = "llamasking",
        description = "An alternative implementation of Custom Votes that utilizes the NativeVotes system.",
        version     = VERSION,
        url         = "https://github.com/llamasking/sourcemod-plugins"
}

const int MaxVoteKeyLen = 64;
char g_sActiveVoteKeyInfo[MaxVoteKeyLen];
Regex g_reStringBooleanInterp = null;
KeyValues g_kvConfig          = null;

public void OnPluginStart()
{
    // Config values.
    CreateConVar("sm_ncvotes_version", VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
    AutoExecConfig();

    RegConsoleCmd("sm_votemenu", Command_VoteMenu, "Call a vote to change to a workshop map.");
    RegAdminCmd("sm_customvotes_reload", Command_ReloadConfig, ADMFLAG_ROOT, "Reloads the vote configuration file.");

    // Load translations.
    LoadTranslations("native_customvotes.phrases.txt");

    // Compile Regex
    char err[255];
    g_reStringBooleanInterp = new Regex("{(.*?)\\|(.*?)}", _, err, sizeof(err));
    if (strlen(err) != 0)
        SetFailState(err);

    // Check that NativeVotes works here
    if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_Custom_YesNo))
        SetFailState("This game does not support custom yes/no votes!");

    // Init config
    ReloadConfig();

// Updater
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

public Action Command_ReloadConfig(int client, int args)
{
    ReloadConfig();
    return Plugin_Handled;
}

public void ReloadConfig()
{
    if (g_kvConfig != null)
        CloseHandle(g_kvConfig);

    char configFilePath[255];
    BuildPath(Path_SM, configFilePath, sizeof(configFilePath), "configs/native_customvotes.cfg");

    g_kvConfig = new KeyValues("Votes");
    if (!FileToKeyValues(g_kvConfig, configFilePath) || !g_kvConfig.GotoFirstSubKey())
        SetFailState("Configuration file does not exist or is misconfigured.");
}

/**
 * Initial menu listing the voting choices.
 */
public Action Command_VoteMenu(int client, int args)
{
    if (NativeVotes_IsVoteInProgress())
    {
        CPrintToChat(client, "%t", "NCVote_ExistingVote");
        return Plugin_Handled;
    }

    Menu menu = new Menu(Menu_VoteMenuHandler);
    menu.SetTitle("Vote Menu");

    // Loop through each voting option in the config.
    g_kvConfig.Rewind();
    g_kvConfig.GotoFirstSubKey();
    do
    {
        // Get the option's display name and kv id.
        // Name is formatted then displayed to user.
        // The id is used throughout the plugin to jump the kv read 'head' to this option.
        char option_display[64];
        g_kvConfig.GetSectionName(option_display, sizeof(option_display));

        int option_id;
        char option_id_s[16];
        g_kvConfig.GetSectionSymbol(option_id);
        IntToString(option_id, option_id_s, sizeof(option_id_s));

        // Get current status of the cvar associated with this option
        char cvar_name[32];
        g_kvConfig.GetString("cvar", cvar_name, sizeof(cvar_name));
        ConVar cvar = FindConVar(cvar_name);

        // Format the name
        StringInterpolate(option_display, sizeof(option_display), cvar.BoolValue);

        // Add the item to the menu
        menu.AddItem(option_id_s, option_display);

        CloseHandle(cvar);
    } while (g_kvConfig.GotoNextKey());

    menu.Display(client, 20);

    return Plugin_Handled;
}

/**
 * Handler for the initial vote menu that listed the voting choices.
 */
public int Menu_VoteMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            // param1=client, param2=item (kv section id)

            // Move g_kvConfig to read the data for this voting option
            char kv_id[16];
            menu.GetItem(param2, kv_id, sizeof(kv_id));
            char i_kv_id = StringToInt(kv_id);
            g_kvConfig.Rewind();
            g_kvConfig.JumpToKeySymbol(i_kv_id);

            // Formatted vote title
            char vote_title[64];
            g_kvConfig.GetSectionName(vote_title, sizeof(vote_title));
            char cvar_name[32];
            g_kvConfig.GetString("cvar", cvar_name, sizeof(cvar_name));
            ConVar cvar = FindConVar(cvar_name);
            StringInterpolate(vote_title, sizeof(vote_title), cvar.BoolValue);
            CloseHandle(cvar);

            // Vote Type
            char vote_type[16];
            g_kvConfig.GetString("type", vote_type, sizeof(vote_type));

            // Boolean types immediately initiate a vote to toggle a cvar
            if (StrEqual(vote_type, "boolean"))
            {
                InitiateVote(kv_id, vote_title, sizeof(vote_title), param1);
            }
            // Lists have a submenu that gives the caller options
            else if (StrEqual(vote_type, "list"))
            {
                Menu op_menu = new Menu(Menu_OptionsMenuHandler);
                op_menu.SetTitle(vote_title);

                // Get kv id of the "options" parent key
                g_kvConfig.JumpToKey("options");
                int kv_options_id;
                g_kvConfig.GetSectionSymbol(kv_options_id);

                // Display each option
                g_kvConfig.GotoFirstSubKey(false);
                do
                {
                    // Display text
                    char option_display[64];
                    g_kvConfig.GetSectionName(option_display, sizeof(option_display));

                    // Get kv id for this specific option choice
                    int option_id;
                    g_kvConfig.GetSectionSymbol(option_id);
                    char option_id_s[32];
                    // Format: vote option, "options" section, chosen option
                    Format(option_id_s, sizeof(option_id_s), "%i,%i,%i", i_kv_id, kv_options_id, option_id);

                    // Add the item to the menu
                    op_menu.AddItem(option_id_s, option_display);
                } while (g_kvConfig.GotoNextKey(false));

                op_menu.Display(param1, 20);
            }
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }

    return 0;
}

/**
 * Handler for the options menu that is displayed for choices that have such.
 */
public int Menu_OptionsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            // param1=client, param2=item (kv section id)

            // Gets the location of the data for this option on g_kvConfig
            char kv_id_s[32];
            menu.GetItem(param2, kv_id_s, sizeof(kv_id_s));

            // Breaks the string up to get the individual ids.
            const int MaxKvChildCt = 3;
            const int MaxKvIdSize  = 16;
            char kv_id[MaxKvChildCt][MaxKvIdSize];
            ExplodeString(kv_id_s, ",", kv_id, MaxKvChildCt, MaxKvIdSize);

            // Walks through the tree to the specific item
            g_kvConfig.Rewind();

            int kv_id_idx = 0;
            g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[kv_id_idx]));

            // Get vote display text
            char option_vote_text[64];
            g_kvConfig.GetString("vote_text", option_vote_text, sizeof(option_vote_text));

            // Walk through "options", then to specific chosen option.
            g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[++kv_id_idx]));
            g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[++kv_id_idx]));

            // Get display text and cvar value
            char option_display_text[64];
            g_kvConfig.GetSectionName(option_display_text, sizeof(option_display_text));

            char option_cvar_value[64];
            g_kvConfig.GetString(NULL_STRING, option_cvar_value, sizeof(option_cvar_value));

            // Format the string to be displayed on the vote panel.
            StringInterpolate(option_vote_text, sizeof(option_display_text), _, option_display_text, option_cvar_value);

            // Initiate vote
            InitiateVote(kv_id_s, option_vote_text, sizeof(option_vote_text), param1);
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

public void InitiateVote(const char[] kv_id_list, char[] display_text, int title_size, int client)
{
    // Error if a vote is in progress
    if (NativeVotes_IsVoteInProgress())
    {
        CPrintToChat(client, "%t", "NCVote_ExistingVote");
        return;
    }

    NativeVote vote = new NativeVote(Nv_Handler, NativeVotesType_Custom_YesNo);
    ReplaceString(display_text, title_size, "%", "%%");  // Escape percent signs in vote title
    StrCat(display_text, title_size, "?");               // Add question mark to end of vote title.
    vote.SetDetails(display_text);
    vote.Initiator = client;

    // Get list of players to send the vote to.
    int total;
    int[] players = new int[MaxClients];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientValid(i) || (GetClientTeam(i) < 2))
            continue;
        players[total++] = i;
    }

    // Returns true if vote has been initiated and false otherwise
    if (vote.DisplayVote(players, total, 20, VOTEFLAG_NO_REVOTES))
    {
        // It is not easy to discern the option being voted on in the callback
        // with the data that function is provided, so the vote key is copied
        // and used for JumpToKey.
        //
        // This isn't necessarily *required* as long as g_kvConfig does not jump to
        // another section while the vote is running (it shouldn't), but this is
        // to be extra safe.
        strcopy(g_sActiveVoteKeyInfo, MaxVoteKeyLen, kv_id_list);
    }
    else
    {
        CPrintToChat(client, "%t", "NCVote_ExistingVote");
        vote.Close();
    }
}

public int Nv_Handler(NativeVote vote, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            // param1 is index of winning vote item
            // this plugin only does yes/no votes, and 0 is yes with 1 no
            if (param1 == NATIVEVOTES_VOTE_YES)
            {
                // Variables that may be set related to this vote.
                char pass_text[64];            // Text that will display on the vote pass notification.
                char cvar_name[32];            // Name of the cvar that this vote will alter
                char vote_type[16];            // The type of vote this is: "boolean" or "list"
                char option_display_text[64];  // If "list" type, this option's display text
                char option_cvar_value[64];    // If "list" type, this option's cvar value to set

                // Breaks the string up to get the individual ids.
                int kv_id_idx          = 0;
                const int MaxKvChildCt = 3;
                const int MaxKvIdSize  = 16;
                char kv_id[MaxKvChildCt][MaxKvIdSize];
                ExplodeString(g_sActiveVoteKeyInfo, ",", kv_id, MaxKvChildCt, MaxKvIdSize);

                // Move kv to the right vote option
                g_kvConfig.Rewind();
                g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[kv_id_idx]));

                // Displayed pass text
                g_kvConfig.GetString("pass_text", pass_text, sizeof(pass_text));

                // Convar associated with the vote
                g_kvConfig.GetString("cvar", cvar_name, sizeof(cvar_name));
                ConVar cvar = FindConVar(cvar_name);

                // Get vote type. Booleans simply switch the convar on/off, others have more complicated handling.
                g_kvConfig.GetString("type", vote_type, sizeof(vote_type));
                if (StrEqual(vote_type, "boolean"))
                {
                    // Update cvar
                    cvar.SetBool(!cvar.BoolValue);
                }
                else if (StrEqual(vote_type, "list"))
                {
                    // Walk through "options", then to specific chosen option.
                    g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[++kv_id_idx]));
                    g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[++kv_id_idx]));

                    // Get display text and cvar value
                    g_kvConfig.GetSectionName(option_display_text, sizeof(option_display_text));
                    g_kvConfig.GetString(NULL_STRING, option_cvar_value, sizeof(option_cvar_value));

                    cvar.SetString(option_cvar_value);
                }

                // Format pass text and display to clients
                StringInterpolate(pass_text, sizeof(pass_text), !cvar.BoolValue, option_display_text, option_cvar_value);
                ReplaceString(pass_text, sizeof(pass_text), "%", "%%");  // Escape percent signs in vote title
                vote.DisplayPass(pass_text);

                CloseHandle(cvar);
            }
            else
            {
                vote.DisplayFail(NativeVotesFail_Loses);
            }
        }

        case MenuAction_VoteCancel:
        {
            // param1 is cancel reason
            if (param1 == VoteCancel_NoVotes)
            {
                vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
            }
            else
            {
                vote.DisplayFail(NativeVotesFail_Generic);
            }
        }

        case MenuAction_End:
        {
            // param1 is the MenuEnd reason, and if it's MenuEnd_Cancelled, then
            // param2 is the MenuCancel reason from MenuAction_Cancel.
            vote.Close();
        }
    }

    return 0;
}

bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client) && !IsClientInKickQueue(client);
}

/**
 * Formats a given string from the plugin's config file.
 *
 * @param text              String to perform formatting on.
 * @param maxlen            Maximum length of the string.
 * @param is_true_result    For boolean (`{true|false}`) formatting items, this determines if the left or right value should be used.
 * @param option_name       Optional. Contents of `{OPTION_NAME}` if it exists within the string.
 * @param option_value      Optional. Contents of `{OPTION_VALUE}` if it exists within the string.
 */
void StringInterpolate(char[] text, int maxlen, bool is_true_result = true, char[] option_name = "", char[] option_value = "")
{
    ReplaceString(text, maxlen, "{OPTION_NAME}", option_name);
    ReplaceString(text, maxlen, "{OPTION_VALUE}", option_value);

    int match_count = g_reStringBooleanInterp.Match(text);
    if (match_count > 0)
    {
        char to_replace[32];
        g_reStringBooleanInterp.GetSubString(0, to_replace, sizeof(to_replace));

        char result_text[32];
        g_reStringBooleanInterp.GetSubString(is_true_result ? 2 : 1, result_text, sizeof(result_text));

        ReplaceString(text, maxlen, to_replace, result_text);
    }
}

/**
 * This jumps to a specific key on a KV tree by walking from the root through
 * to a specific node as directed by the given list of ids.
 *
 * This is done because kv.JumpToKeySymbol does not allow you to jump
 * directly to a symbol from a level above it. You must instead walk through
 * the parent nodes before you can jump to it.
 *
 * ```
 * "A"
 * {
 *   "B"
 *   {
 *     "key" "val"
 *   }
 * }
 * ```
 *
 * @param ids   String containing a comma delimited list of kv symbols, starting
 *              from the first subchild of the root to (and containing) the desired
 *              end node.
 * @return      True if there were no errors in the traversal. If there were, the
 *              tree is rewound and this returns 0.
 */
/*
bool KV_JumpToSubKeyBySymbol(const char[] ids)
{
    // Breaks the string up to get the individual ids.
    const int MaxKvChildCt = 3;
    const int MaxKvIdSize  = 16;
    char kv_id[MaxKvChildCt][MaxKvIdSize];
    ExplodeString(ids, ",", kv_id, MaxKvChildCt, MaxKvIdSize);

    // Walks through the tree to the specific item
    g_kvConfig.Rewind();
    for (int i = 0; i < MaxKvChildCt; i++)
        if (!g_kvConfig.JumpToKeySymbol(StringToInt(kv_id[i])))
        {
            g_kvConfig.Rewind();
            return false;
        }

    return true;
}
*/
