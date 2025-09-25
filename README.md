🎮 Session Recall for R36S
A Bash script to quickly relaunch saved games on your R36S system, integrating with RetroArch and RetroArch32.

🚀 Features
- Detects recent save files across multiple ROM directories.
- Automatically identifies the system/console for each save.
- Finds the correct ROM and core/emulator to launch.
- Supports automatic (.state.auto) and manual (.state*) save states.
- Launch the game from the save file 

🛠️ Installation
Copy the Session_Recall script to roms/tools or to roms2/tools if you have 2 SD cards

⚠️ Important Notes
Testing: Only tested on emulators defined by default in RetroArch or RetroArch32. Compatibility with other setups is not guaranteed.
Fixed.

[MANE Constraint] 
Resolved an issue preventing the backup process from being launched immediately.
The core must now be fully loaded before the backup procedure can be executed.

Nintendo DS is not supported by this script since it relies on the Drastic core, which is currently incompatible.

📄 License
MIT License – see License for details.

# A coffee to offer?
https://ko-fi.com/jason3x
