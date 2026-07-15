# Salty Bay Tools — Updater

One click keeps **every** Salty Bay tool on your computer up to date.

## How to use it

1. Click the green **Code** button above → **Download ZIP**.
2. Open the downloaded ZIP and **double-click `Update Salty Bay Tools.bat`**.
3. Watch it work. It will:
   - find every Salty Bay tool already on your Desktop, Downloads, or Documents,
   - update each one to the latest shared version, and
   - offer to add any tools you don't have yet (just type **Y** to add, or press **Enter** to skip).
4. When it says **[DONE]**, close the window and open your tools the normal way.

Your saved work and logins are **never** touched — comps in the Deals folder,
the court login, downloaded county data, and your output files all stay exactly
as they are.

## What it can install / update

| Tool | What it does |
|------|--------------|
| Comp Tool | Pulls Zillow comps and builds an investor deal summary. |
| E&F Lead Pull | Pulls evictions, foreclosures, and civil suits from the county court and outputs a REI Sift-ready CSV. |

*(To add a future tool, copy one `CALL :process_tool` line in the .bat and fill in
the four values — name, launcher file, repo URL, install folder.)*

## If something looks wrong

Take a screenshot of the window and send it to KG.
