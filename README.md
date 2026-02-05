### 🎮 Session Recall for R36S

A Bash script to quickly relaunch saved games on your R36S system, integrating with RetroArch and RetroArch32.

---

### 🚀 Features

* Detects recent save files across multiple ROM directories.
* Automatically identifies the system/console for each save.
* Finds the correct ROM and core/emulator to launch.
* Supports automatic (`.state.auto`) and manual (`.state*`) save states.
* Launch a game directly from a save file.
* **Backup all saves into a single ZIP archive** (SRM, SAV, STATE).
* **Restore all saves from a ZIP backup** to their original locations.

---

### 🛠️ Installation

1. Copy the script to:

   * `roms/tools/`
   * or `roms2/tools/` if using two SD cards

2. If a previous version exists:

   * delete `Session Recall.sh`
   * rename the new script to **`Session Recall.sh`**

3. Launch the script from the Tools menu.

---

### 💾 Backup & Restore

* Scroll to the bottom of the main menu.

* Select **“Backup all saves zip”** to create a full backup.

* The backup file is created in:

  * `roms/backup/Session_Recall.zip`
  * or `roms2/backup/Session_Recall.zip`

* Use **“Restore all saves”** to extract the backup and overwrite existing saves.

⚠️ Restoring will replace current save files with the versions from the ZIP.

---

### ⚠️ Important Notes

* **Testing**: Tested on emulators defined by default in RetroArch or RetroArch32. Compatibility with other setups is not guaranteed.
* **[MAME Constraint]**
  Resolved an issue preventing the backup process from being launched immediately.
  The core must now be fully loaded before the backup procedure can be executed.
* **Nintendo DS is not supported**, as it relies on the Drastic core, which is currently incompatible.

---

### 📄 License

MIT License – see License for details.

---

### ☕ A coffee to offer?

[https://ko-fi.com/jason3x](https://ko-fi.com/jason3x)

---
