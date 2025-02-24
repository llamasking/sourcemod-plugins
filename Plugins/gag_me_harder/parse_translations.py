#!/usr/bin/python3

# This is almost unreadable. Sorry.
# Maybe ChatGPT can understand it if you ever need to actually figure out how this works.
# Or maybe it'll just make it worse.

import glob
import vdf

TF2_RESOURCE_PATH = "<Fill This In>/common/Team Fortress 2/tf/resource"

# Maps full length name to the shortened version used in the SourceMod translations.
# Taken from /addons/sourcemod/configs/languages.cfg
LANG_MAP = {k.lower(): v for k, v in {
	"Arabic":       "ar",
	"Bulgarian":    "bg",
	"SChinese":     "chi",
	"Czech":        "cze",
	"Danish":       "da",
	"German":       "de",
	"Greek":        "el",
	"English":      "en",
	"Spanish":      "es",
	"Finnish":      "fi",
	"French":       "fr",
	"Hebrew":       "he",
	"Hungarian":    "hu",
	"Italian":      "it",
	"Japanese":     "jp",
	"Korean":       "ko",
 	"KoreanA":      "ko",
	"LatAm":        "las",
	"Lithuanian":   "lt",
	"Latvian":      "lv",
	"Dutch":        "nl",
	"Norwegian":    "no",
	"Polish":       "pl",
	"Brazilian":    "pt",
	"Portuguese":   "pt_p",
	"Romanian":     "ro",
	"Russian":      "ru",
	"Slovak":       "sk",
	"Swedish":      "sv",
	"Thai":         "th",
	"Turkish":      "tr",
	"Ukrainian":    "ua",
	"Vietnamese":   "vi",
	"TChinese":     "zho",
}.items()}

# Extract translation strings from TF2 localization files.
l18n_keys = ["TF_Chat_All" ,"TF_Chat_AllDead" ,"TF_Chat_AllSpec" ,"TF_Chat_Team" ,"TF_Chat_Team_Dead" ,"TF_Chat_Spec"]
l18n_values = {k: dict() for k in l18n_keys}
for file in glob.glob(TF2_RESOURCE_PATH + "/tf_*.txt"):
    with open(file, 'r', encoding="utf-16-le") as f:
        try:
            data = vdf.parse(f)
        except:
            # This is almost certainly fine. Print just in case, though.
            print(f"INFO: Failed to parse {f.name}.")
            continue

        lang = data["lang"]["Language"].lower()

        # Convert lang from full-length to SM short
        if lang not in LANG_MAP:
            print("Language not supported by SourceMod:", lang)
            continue
        lang = LANG_MAP[lang]

        for key in l18n_keys:
            value = data["lang"]["Tokens"][key]

            # Convert TF2 control characters to SourceMod control characters
            value = value.replace("%s1", "{1}")
            value = value.replace("%s2", "{2}")
            value = value.replace("\x01", "{default}")
            value = value.replace("\x03", "{teamcolor}")
            value = value.replace("\x02{1}", "{teamcolor}{1}{default}")

            l18n_values[key][lang] = value

# Sort languages alphabetically
# Also add '#format' key
for k, v in l18n_values.items():
    l18n_values[k]["#format"] = "{1:s},{2:s}"
    l18n_values[k] = dict(sorted(v.items()))

# Print to SourceMod translation format.
with open("translations/gag_me_harder.phrases.txt", "w") as f:
    # Sorts keys alphabetically
    sm_form = {"Phrases": dict(sorted(l18n_values.items()))}
    f.write(vdf.dumps(sm_form))
