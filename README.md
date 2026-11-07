# Val-Patcher

A tiny pair of Windows batch scripts that put **your own video** in as the VALORANT main-menu background, then restore the original when the game closes, so a normal launch never triggers a Riot repair.

It only copies a video file in the game's `Menu` folder. Nothing is injected into the game, no overlay is drawn, and no game memory is read. The scripts are short and commented, so you can read exactly what they do before running them.

> **Want a full app instead?** [**Veil Launcher**](https://github.com/ChirisaCasey/veil-launcher) does the same job with a desktop UI, a tray icon, a video library, smart detection, optional background mode and an installer. Val-Patcher is the lightweight, script-only version.

## Setup (once)

1. Download this repo (**Code → Download ZIP**) and extract it anywhere.
2. Run **`setup.bat`**. It finds VALORANT automatically, creates the `Custom` and `Backups` folders, backs up the original menu video and opens `Custom` for you.
3. Put the `.mp4` you want as your background into **`Custom`**.

## Usage

Run **`launcher.bat`** instead of starting VALORANT normally.

1. It launches VALORANT through the Riot Client and waits for the game to start.
2. Once Riot's file check is done, it puts your video in place.
3. Play as usual and keep the script window open (minimized is fine).
4. When VALORANT closes, the original video is restored automatically.

If VALORANT is already running when you start `launcher.bat`, it patches the current session instead of launching a new one.

| Command | What it does |
| --- | --- |
| `launcher.bat` | Launch (or attach to) VALORANT with your video |
| `launcher.bat --restore` | Put the original video back right now |
| `launcher.bat --check` | Show the detected folders and files, change nothing |
| `setup.bat` | First-time setup (same as `launcher.bat --setup`) |

## Good to know

- **Closed the window by accident?** Just run `launcher.bat` again. It notices the unfinished session and either keeps waiting (if the game is still running) or restores the original first.
- **VALORANT updated?** Nothing to do. The original is backed up fresh on every run, so a patch that renames the menu file (for example `12_xx_Homescreen.mp4` → `13_06_Homescreen.mp4`) is picked up automatically.
- **Several videos in `Custom`?** The first one by name is used.
- **VALORANT not found?** Put your VALORANT folder (for example `D:\Riot Games\VALORANT`) on the first line of `path.txt`. Normally it's found from Riot's own install records, so `path.txt` can stay empty.
- **"Could not write to the VALORANT folder"?** Your install is in a protected location. Right-click `launcher.bat` → **Run as administrator**.
- **Don't click inside the script window.** Selecting text in a console window pauses the script until you press a key.
- **Only launches through `launcher.bat` get your video.** Starting VALORANT any other way shows the normal menu.
- **Something looks wrong?** Run `launcher.bat --restore`, or use **Repair** in the Riot Client to get the stock files back.

## How it works

```
launcher.bat
 ├─ find VALORANT (path.txt, or Riot's install metadata)
 ├─ restore leftovers from an unfinished session, if any
 ├─ back up the current *Homescreen*.mp4  →  Backups\
 ├─ launch VALORANT via RiotClientServices.exe
 ├─ wait for VALORANT-Win64-Shipping.exe, then a few seconds for Riot's file check
 ├─ copy Custom\<your video>.mp4 over the Homescreen file
 ├─ wait for the game to close
 └─ copy the backup back
```

## Disclaimer

Not affiliated with or endorsed by Riot Games. VALORANT is a trademark of Riot Games, Inc. This only replaces a video file the game ships with, but use it at your own risk.
