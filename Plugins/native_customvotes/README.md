# Native Custom Votes

A basic voting system that uses Native Votes. The configuration file is similar to [Custom Votes Redux](https://github.com/caxanga334/cvreduxmodified) but they are not directly compatible with one another.

This was built to replace Custom Votes on my servers and is a complete rewrite, not using any code from the original addon.

## Configuration Example

There are two types of votes allowed. They behave quite differently and have a different set of parameters. Both are shown below.

```
"Votes"
{
                                                                    // 'list' type:
    "Change gravity"                                                // <-- Title displayed in the vote menu.
    {                                                               //
        "type"           "list"                                     // <-- 'list' type displays a submenu with options for the player to select from before initiating a vote.
        "options"                                                   //
        {                                                           //
            "Very Low (200)"      "200"                             // <-- Left value is the text displayed in the submenu.
            "Low (400)"           "400"                             //     Right is the value which 'cvar' gets updated to if the vote passes.
            "Normal (800)"        "800"                             //
            "High (1200)"         "1200"                            //
            "Very High (1600)"    "1600"                            //
        }                                                           //
                                                                    //
        "cvar"           "sv_gravity"                               // <-- If the vote passes, this ConVar's value is updated to the right-hand value of the option selected.
                                                                    //
        "vote_text"      "Change gravity to {OPTION_NAME}."         // <-- Text displayed in the vote panel.
                                                                    //     If used, '{OPTION_NAME}' will be replaced with the left-hand (display) text of the option selected.
                                                                    //     If used, '{OPTION_VALUE}' will be replaced with the right-hand value of the option selected.
                                                                    //
        "pass_text"      "Changing gravity to {OPTION_NAME}."       // <-- Text displayed in the vote panel if it passes. Allows use of {OPTION_NAME} and {OPTION_VALUE} similarly to 'vote_text'.
    }

                                                                    // 'boolean' type:
    "{Enable|Disable} all talk"                                     // <-- 'boolean' type votes may (and probably always should) have their title set as shown here.
    {                                                               //      The text left of the '|' is shown if the ConVar is currently off, and the right hand if the ConVar is on.
                                                                    //      In this example, the title will be "Enable all talk" if alltalk is off or "Disable all talk" it is on.
                                                                    //
        "type"           "boolean"                                  // <-- 'boolean' type does not display a submenu and instead immediately initiates a vote when selected.
                                                                    //      It also does NOT have a 'vote_text' parameter. Instead, the title itself is displayed in the vote panel.
                                                                    //
        "cvar"           "sv_alltalk"                               // <-- If the vote passes, this ConVar's value is toggled. (on becomes off and vice versa)
                                                                    //     It is not possible to update the ConVar to arbitrary values like with the 'list' type.
                                                                    //
        "pass_text"      "{Enabling|Disabling} all talk."           // <-- Already discussed above.
    }
}
```
