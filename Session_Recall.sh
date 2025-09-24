#!/bin/bash

#----------------------------------#
#     Session Recall for R36S      #
#             By Jason             #
#----------------------------------#

# --- SECTION "WORKER" ---
if [[ "${1:-}" == "--launch" ]]; then
    GAME_CMD="$2"
    CURR_TTY="/dev/tty1"
    WORKER_LOG="/tmp/worker_run.log"

    # Initialisation du journal pour ce lancement
    > "$WORKER_LOG"
    echo "--- Worker started by systemd at $(date) ---" >> "$WORKER_LOG"

    # Nettoie l'écran du TTY
    printf "\033c" > "$CURR_TTY"

    echo "Launching game command: $GAME_CMD" >> "$WORKER_LOG"
    # Exécute la commande du jeu en tant qu'utilisateur 'ark'
    sudo -n -u ark bash -lc ". /home/ark/.profile && $GAME_CMD" \
        >> "$WORKER_LOG" 2>&1 || true

    # Nettoyage du fichier temporaire RetroArch si présent
    rm -f /tmp/retroarch_load_state.cfg 2>/dev/null || true

    echo "--- Worker finished at $(date) ---" >> "$WORKER_LOG"

    # Nettoie l'écran après avoir quitté le jeu
    printf "\033c" > "$CURR_TTY"

    exit 0
fi
# --- FIN DE LA SECTION "WORKER" ---

# S'assure que le script est exécuté en tant que root
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

# --- VARIABLES & CONSTANTES ---
CURR_TTY="/dev/tty1"
BACKTITLE="Session Recall By Jason"
ROMS_DIRS=("/roms" "/roms2")
ES_SYSTEMS_CFG="/etc/emulationstation/es_systems.cfg"
CORES_DIR=("/home/ark/.config/retroarch/cores" "/home/ark/.config/retroarch32/cores")
DEBUG_MODE=1
DEBUG_FILE="/tmp/Session_Recall_debug.log"

# --- Génération automatique des FALLBACK_CORES (classé par système) ---
declare -A FALLBACK_CORES

generate_fallback_cores() {
    for dir in "${CORES_DIR[@]}"; do
        [ -d "$dir" ] || continue
        for core in "$dir"/*.so; do
            [ -f "$core" ] || continue
            core_file=$(basename "$core")

            case "$core_file" in
                # --- Nintendo ---
                nestopia_libretro.so)          FALLBACK_CORES[nes]="$core_file"; FALLBACK_CORES[fds]="$core_file";;
                snes9x_libretro.so)            FALLBACK_CORES[snes]="$core_file"; FALLBACK_CORES[sfc]="$core_file";;
                mgba_libretro.so)              FALLBACK_CORES[gba]="$core_file";;
                gambatte_libretro.so)          FALLBACK_CORES[gb]="$core_file"; FALLBACK_CORES[gbc]="$core_file";;
                mupen64plus_next_libretro.so)  FALLBACK_CORES[n64]="$core_file";;
                desmume_libretro.so)           FALLBACK_CORES[nds]="$core_file";;
                dolphin_libretro.so)           FALLBACK_CORES[gamecube]="$core_file"; FALLBACK_CORES[wii]="$core_file";;

                # --- Sega ---
                genesis_plus_gx_libretro.so)   FALLBACK_CORES[megadrive]="$core_file"; FALLBACK_CORES[gen]="$core_file"; FALLBACK_CORES[md]="$core_file"; FALLBACK_CORES[sms]="$core_file"; FALLBACK_CORES[gg]="$core_file";;
                picodrive_libretro.so)         FALLBACK_CORES[sega32x]="$core_file";;
                flycast_libretro.so)           FALLBACK_CORES[dreamcast]="$core_file"; FALLBACK_CORES[naomi]="$core_file"; FALLBACK_CORES[atomiswave]="$core_file";;
                yabause_libretro.so)           FALLBACK_CORES[saturn]="$core_file";;

                # --- Sony ---
                pcsx_rearmed_libretro.so)      FALLBACK_CORES[psx]="$core_file";;
                ppsspp_libretro.so)            FALLBACK_CORES[psp]="$core_file";;

                # --- Arcade ---
                fbneo_libretro.so)             FALLBACK_CORES[arcade]="$core_file"; FALLBACK_CORES[fbneo]="$core_file"; FALLBACK_CORES[fba]="$core_file"; FALLBACK_CORES[neogeo]="$core_file";;
                mame2003_plus_libretro.so)     FALLBACK_CORES[mame]="$core_file";;

                # --- Ordinateurs ---
                dosbox_pure_libretro.so)       FALLBACK_CORES[dos]="$core_file"; FALLBACK_CORES[msdos]="$core_file";;
                puae_libretro.so)              FALLBACK_CORES[amiga]="$core_file";;
                vice_x64_libretro.so)          FALLBACK_CORES[c64]="$core_file";;
                bluemsx_libretro.so)           FALLBACK_CORES[msx]="$core_file"; FALLBACK_CORES[coleco]="$core_file";;
                atari800_libretro.so)          FALLBACK_CORES[atari800]="$core_file"; FALLBACK_CORES[atari5200]="$core_file";;
                stella_libretro.so)            FALLBACK_CORES[atari2600]="$core_file";;
                prosystem_libretro.so)         FALLBACK_CORES[atari7800]="$core_file";;
                hatari_libretro.so)            FALLBACK_CORES[atarist]="$core_file";;

                # --- NEC / Autres consoles ---
                mednafen_pce_fast_libretro.so) FALLBACK_CORES[pcengine]="$core_file"; FALLBACK_CORES[pce]="$core_file"; FALLBACK_CORES[tg16]="$core_file";;
                mednafen_wswan_libretro.so)    FALLBACK_CORES[wonderswan]="$core_file"; FALLBACK_CORES[ws]="$core_file"; FALLBACK_CORES[wsc]="$core_file";;
                handy_libretro.so)             FALLBACK_CORES[lynx]="$core_file";;
                mednafen_ngp_libretro.so)      FALLBACK_CORES[ngp]="$core_file"; FALLBACK_CORES[ngpc]="$core_file";;
                vecx_libretro.so)              FALLBACK_CORES[vectrex]="$core_file";;
                81_libretro.so)                FALLBACK_CORES[zx81]="$core_file";;
                fuse_libretro.so)              FALLBACK_CORES[zxspectrum]="$core_file";;
            esac
        done
    done
}

# Exécution dès l’initialisation
generate_fallback_cores

# --- Log regroupé par familles ---
{
    echo "=== NINTENDO ==="
    for sys in nes fds snes sfc gba gb gbc n64 nds 3ds gamecube wii switch; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done

    echo "=== SEGA ==="
    for sys in megadrive gen md sms gg sega32x dreamcast naomi atomiswave saturn; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done

    echo "=== SONY ==="
    for sys in psx psp ps2; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done

    echo "=== ARCADE ==="
    for sys in arcade fbneo fba neogeo mame; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done

    echo "=== ORDINATEURS ==="
    for sys in dos msdos amiga c64 msx coleco atari800 atari5200 atari2600 atari7800 atarist; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done

    echo "=== NEC & AUTRES ==="
    for sys in pcengine pce tg16 wonderswan ws wsc lynx ngp ngpc vectrex zx81 zxspectrum; do
        [[ -n "${FALLBACK_CORES[$sys]}" ]] && echo "  [$sys] -> ${FALLBACK_CORES[$sys]}"
    done
} >> "$DEBUG_FILE"

# --- ExitMenu ---
ExitMenu() {
    printf "\033c" > "$CURR_TTY"; printf "\e[?25h" > "$CURR_TTY"
    pkill -f "gptokeyb -1 Session_Recall.sh" || true
    if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
        setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
    fi
    exit 0
}

# --- Log_debug ---
log_debug() {
    [[ $DEBUG_MODE -eq 1 ]] && echo "[$(date +'%T')] $1" >> "$DEBUG_FILE"
}

# --- Show_dialog ---
show_dialog() {
    dialog --backtitle "$BACKTITLE" --title "$2" --"$1" "$3" 10 70 2>"$CURR_TTY"
}

# --- Detection du systeme ---
detect_system() {
    local save_path="$1" system="Unknown"
    for roms_dir in "${ROMS_DIRS[@]}"; do
        if [[ "$save_path" == "$roms_dir"* ]]; then
            local relative_path="${save_path#$roms_dir/}"; system="${relative_path%%/*}"; break
        fi
    done
    log_debug "[DETECTED] $save_path -> $system"; echo "$system"
}

# --- Trouve le chemin complet de la ROM correspondante à une sauvegarde ---
find_rom_path() {
    local save_basename="$1" system="$2" rom_path=""
    declare -a extensions
    case "$system" in
        nes|fds) extensions=("nes" "fds" "zip");; snes|sfc) extensions=("smc" "sfc" "zip");;
        gba) extensions=("gba" "zip");; gb|gbc) extensions=("gbc" "gb" "zip");;
        n64) extensions=("n64" "z64" "v64" "zip");; nds) extensions=("nds" "zip");;
        megadrive|gen|md) extensions=("md" "gen" "bin" "zip");;
        mastersystem|sms|gg) extensions=("sms" "gg" "zip");;
        psx) extensions=("cue" "bin" "iso" "chd" "pbp");; psp) extensions=("iso" "cso" "pbp");;
        *) extensions=("zip" "*");;
    esac
    for roms_dir in "${ROMS_DIRS[@]}"; do
        local search_dir="$roms_dir/$system"
        if [ -d "$search_dir" ]; then
            for ext in "${extensions[@]}"; do
                rom_path=$(find "$search_dir" -type f -iname "$save_basename.$ext" -print -quit)
                [ -n "$rom_path" ] && break 2
            done
        fi
    done
    log_debug "[ROM_PATH] Found ROM for $system: $rom_path"; echo "$rom_path"
}

# --- Extrait le core et la commande ---
get_core_and_command() {
    local system="$1" core="" command=""
    
    # Si le fichier es_systems.cfg n'existe pas, on retourne fallback direct
    [ ! -f "$ES_SYSTEMS_CFG" ] && { core="${FALLBACK_CORES[$system]}"; command="/usr/local/bin/retroarch -L \"$core\" \"%ROM%\""; echo "$core|$command"; return; }

    # Lecture du bloc système
    local system_block
    system_block=$(sed -n "/<name>$system<\/name>/,/<\/system>/p" "$ES_SYSTEMS_CFG")
    if [ -n "$system_block" ]; then
        # Extraire le core
        core=$(echo "$system_block" | grep '<core>' | head -n1 | sed -e 's/.*<core>//' -e 's/<\/core>.*//' | xargs)
        # Extraire l'émulateur
        local emulator
        emulator=$(echo "$system_block" | grep '<emulator name' | head -n1 | sed -n 's/.*name="\([^"]*\)".*/\1/p' | xargs)
        [ -z "$emulator" ] && emulator="retroarch"
        # Extraire la commande
        local raw_command
        raw_command=$(echo "$system_block" | tr -d '\n\r' | sed 's/>\s*</></g' | sed -n 's:.*<command>\(.*\)</command>.*:\1:p')
        if [ -n "$raw_command" ]; then
            command=$(echo "$raw_command" | grep -o -E '[^;]*%EMULATOR%[^;]*' || echo "$raw_command" | sed -E 's/(sudo perfmax .*?;|; sudo perfnorm)//g')
            command=$(echo "$command" | xargs | sed -E 's/^\s*nice -n -[0-9]+\s*//' | xargs)
            command="${command//\%EMULATOR%/$emulator}"
            command="${command//\%CORE%/$core}"
        fi
    fi

    # Vérifie si le core existe, sinon fallback
    local found_core=""
    if [[ -n "$core" ]]; then
        for dir in "${CORES_DIR[@]}"; do
            [[ -f "$dir/$core" ]] && { found_core="$dir/$core"; break; }
        done
    fi

    if [[ -z "$found_core" ]]; then
        core="${FALLBACK_CORES[$system]}"
        for dir in "${CORES_DIR[@]}"; do
            [[ -f "$dir/$core" ]] && { found_core="$dir/$core"; break; }
        done
        # Choix du binaire RetroArch selon dossier
        if [[ "$found_core" == *retroarch32* ]]; then
            command="/usr/local/bin/retroarch32 -L \"$found_core\" \"%ROM%\""
        else
            command="/usr/local/bin/retroarch -L \"$found_core\" \"%ROM%\""
        fi
        log_debug "Fallback core used for $system: $core from $found_core"
    fi

    echo "$core|$command"
}

# --- Prépare et lance le jeu ---
launch_game() {
    local save_path="$1"
    local save_filename save_extension save_basename system rom_path core_name launch_cmd found_core=""
    save_filename=$(basename "$save_path")
    save_extension="${save_filename##*.}"
    save_basename="${save_filename%.*}"
    system=$(detect_system "$save_path" | tr '[:upper:]' '[:lower:]')
    log_debug "Processing save: $save_filename, System: $system"

    # Trouve la ROM correspondante
    rom_path=$(find_rom_path "$save_basename" "$system")
    if [ -z "$rom_path" ]; then
        show_dialog msgbox "ROM Not Found" "\nNo ROM for:\n\n$save_filename"
        return 0
    fi

    # Récupère core et commande depuis es_systems.cfg
    IFS='|' read -r core_name launch_cmd <<< "$(get_core_and_command "$system")"

    # Vérifie si le savestate a un core spécifique
    detect_state_core() {
        local save_path="$1"
        local meta_file="${save_path}.meta"
        [[ -f "$meta_file" ]] && grep -E '^core=' "$meta_file" | cut -d'=' -f2 || echo ""
    }

    state_core=$(detect_state_core "$save_path")

    if [[ -n "$state_core" ]]; then
        found_core=""
        for dir in "${CORES_DIR[@]}"; do
            if [[ -f "$dir/$state_core" ]]; then
                found_core="$dir/$state_core"
                break
            fi
        done
        if [[ -n "$found_core" ]]; then
            core_name="$state_core"
            if [[ "$found_core" == *retroarch32* ]]; then
                launch_cmd="/usr/local/bin/retroarch32 -L \"$found_core\" \"%ROM%\""
            else
                launch_cmd="/usr/local/bin/retroarch -L \"$found_core\" \"%ROM%\""
            fi
            log_debug "Using core from savestate: $core_name"
        else
            log_debug "Core in savestate not found: $state_core. Will try fallback."
            core_name=""
        fi
    fi

    # Si aucun core trouvé, utilise le fallback
    if [[ -z "$core_name" || ! -f "$found_core" ]]; then
        fallback_core="${FALLBACK_CORES[$system]}"
        if [[ -n "$fallback_core" ]]; then
            for dir in "${CORES_DIR[@]}"; do
                if [[ -f "$dir/$fallback_core" ]]; then
                    core_name="$fallback_core"
                    found_core="$dir/$fallback_core"
                    if [[ "$dir" == *retroarch32* ]]; then
                        launch_cmd="/usr/local/bin/retroarch32 -L \"$found_core\" \"%ROM%\""
                    else
                        launch_cmd="/usr/local/bin/retroarch -L \"$found_core\" \"%ROM%\""
                    fi
                    log_debug "Using fallback core for $system: $core_name from $dir"
                    break
                fi
            done
        else
            log_debug "No fallback core available for $system. Launching without core."
            launch_cmd="/usr/local/bin/retroarch \"%ROM%\""
        fi
    fi

    # Prépare le chemin de la ROM
    safe_rom_path="\"$rom_path\""
    launch_cmd="${launch_cmd//\%ROM%/$safe_rom_path}"

    # Gestion des savestates .state.auto
    if [[ "$save_filename" =~ \.state.*$ ]]; then
        local temp_cfg_file="/tmp/retroarch_load_state.cfg"
        local save_dir=$(dirname "$save_path")
        local auto_save_path="${save_dir}/${save_basename}.state.auto"
        local auto_backup=""
        [[ -f "$auto_save_path" ]] && { auto_backup="${auto_save_path}.bak"; mv -f "$auto_save_path" "$auto_backup"; log_debug "Backup .state.auto -> $auto_backup"; }
        cp -f "$save_path" "$auto_save_path"
        log_debug "Created temporary .state.auto: $auto_save_path"
        echo "savestate_directory = \"$save_dir\"" > "$temp_cfg_file"
        echo "savestate_auto_load = \"true\"" >> "$temp_cfg_file"
        echo "savestate_path = \"$auto_save_path\"" >> "$temp_cfg_file"
        launch_cmd+=" --appendconfig $temp_cfg_file"
        trap 'rm -f "$auto_save_path"; [[ -n "$auto_backup" ]] && mv -f "$auto_backup" "$auto_save_path"' EXIT
    fi

    log_debug "[PREPARED_CMD] ${launch_cmd}"

    local core_display="${core_name:-N/A}"
    [[ -n "$found_core" ]] && core_display="$(basename "$found_core")"

    # Barre de lancement
    (
        for i in {1..100}; do
            echo $i
            sleep 0.02
        done
    ) | dialog --backtitle "$BACKTITLE" \
        --title "Launching game" \
        --gauge "\n$(basename "$rom_path")\nSystem: $system\nCore: $core_display" 10 60 0

    log_debug "Stopping gptokeyb before launching the game..."
    pkill -f "gptokeyb -1 Session_Recall.sh" || true
    sleep 0.2 

    # Lancement via systemd-run
    systemd-run --scope --unit="session-recall-worker" "$0" --launch "$launch_cmd"
    log_debug "Worker launched via systemd-run."

    ExitMenu
}

# --- Sous-Menu ---
show_action_menu() {
    local selected_path="$1"
    
    while true; do
        local SUB_CHOICE
        SUB_CHOICE=$(dialog --output-fd 1 --backtitle "$BACKTITLE" --title "Save Action" \
            --cancel-label "Back" --menu "\nAction for:\n$(basename "$selected_path")" 12 60 12 \
            1 "Launch Game" \
            2 "Delete Save" \
            3 "Back to Menu" 2>"$CURR_TTY") || true
        
        [ -z "$SUB_CHOICE" ] && return

        case $SUB_CHOICE in
            1) launch_game "$selected_path"; return ;;
            2)
                if dialog --backtitle "$BACKTITLE" --title "Current save" --yesno "\nDelete this save?\n\n$(basename "$selected_path")" 9 50 2>"$CURR_TTY"; then
                    rm -f "$selected_path"
                    dialog --backtitle "$BACKTITLE" --title "Current save" --infobox "\nFile deleted.\n" 6 40 2>"$CURR_TTY"
                    sleep 1
                fi
                return
                ;;
            3) return ;;
        esac
    done
}

# --- Menu Principal ---
main_loop() {
    while true; do
        local existing_dirs=()
        for dir in "${ROMS_DIRS[@]}"; do [ -d "$dir" ] && existing_dirs+=("$dir"); done
        [ ${#existing_dirs[@]} -eq 0 ] && { dialog --backtitle "$BACKTITLE" --title "Detect ROM" --msgbox "\nNo ROM directories found." 10 60 2>"$CURR_TTY"; return; }

        dialog --backtitle "$BACKTITLE" --title "Detect Saves" --infobox "\nScanning saves..." 5 50 2>"$CURR_TTY"
        local files_found=()
        mapfile -d '' files_found < <(find "${existing_dirs[@]}" -type f \( -iname "*.srm" -o -iname "*.sav" -o -iname "*.state*" \) -print0)

        if (( ${#files_found[@]} == 0 )); then
            dialog --backtitle "$BACKTITLE" --title "Detect Saves" --msgbox "\nNo save files found." 8 40 2>"$CURR_TTY"
            return
        fi

        local SAVELIST_FILE=$(mktemp)
        trap 'rm -f "$SAVELIST_FILE"' EXIT
        ( for i in "${!files_found[@]}"; do
            echo "$(stat -c "%Y|%n" "${files_found[$i]}")" >> "$SAVELIST_FILE"
            echo $(( (i + 1) * 100 / ${#files_found[@]} ))
        done ) | dialog --backtitle "$BACKTITLE" --title "Saves" --gauge "\nAnalyzing saves..." 8 50 0 2>"$CURR_TTY"

        mapfile -t sorted_saves < <(sort -rn "$SAVELIST_FILE" | head -n 10)
        rm -f "$SAVELIST_FILE"; trap - EXIT

        local menu_options=() save_paths=() i=1
        for line in "${sorted_saves[@]}"; do
            local filepath=$(echo "$line" | cut -d'|' -f2-)
            local filename=$(basename "$filepath")
            local formatted_date=$(date -d "@$(echo "$line" | cut -d'|' -f1)" '+%d/%m/%Y')
            
            local save_type_display=""
            if [[ "$filepath" == *.state.auto ]]; then save_type_display="\\Z1Auto Save\\Zn"
            elif [[ "$filepath" == *.state* ]]; then save_type_display="\\Z2Manual Save\\Zn"
            elif [[ "$filepath" == *.srm ]] || [[ "$filepath" == *.sav ]]; then save_type_display="\\Z5In-Game Save\\Zn"
            else save_type_display="\\Z7Unknown\\Zn"; fi

            local system_detected=$(detect_system "$filepath")
            menu_options+=("$i" "$filename - $formatted_date ($save_type_display / \\Z4$system_detected\\Zn)")
            save_paths+=("$filepath"); ((i++))
        done

        local CHOICE
        CHOICE=$(dialog --colors --output-fd 1 --backtitle "$BACKTITLE" --begin 3 0 --title "Recent Saves" \
            --ok-label "Select" --cancel-label "Quit" --menu "\n10 most recent saves" 17 70 12 "${menu_options[@]}" 2>"$CURR_TTY")
        
        ([ $? -ne 0 ] || [ -z "${CHOICE:-}" ]) && ExitMenu
        show_action_menu "${save_paths[$((CHOICE-1))]}"
    done
}

# --- INIT ---
[[ $DEBUG_MODE -eq 1 ]] && : > "$DEBUG_FILE"
printf "\033c" > "$CURR_TTY"; printf "\e[?25l" > "$CURR_TTY"
export TERM=linux; export XDG_RUNTIME_DIR="/run/user/$(id -u)"
if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    setfont /usr/share/consolefonts/Lat7-TerminusBold20x10.psf.gz
else
    setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi
pkill -9 -f gptokeyb || true; pkill -9 -f osk.py || true
printf "\033c" > "$CURR_TTY"; printf "Starting Session Recall...\nPlease wait." > "$CURR_TTY"; sleep 2

# Lancement de gptokeyb pour le contrôle à la manette
if command -v /opt/inttools/gptokeyb &> /dev/null; then
    [[ -e /dev/uinput ]] && chmod 666 /dev/uinput 2>/dev/null || true
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    pkill -f "gptokeyb -1 Session_Recall.sh" || true
    /opt/inttools/gptokeyb -1 "Session_Recall.sh" -c "/opt/inttools/keys.gptk" >/dev/null 2>&1 &
fi

# Gestion des signaux de sortie
trap ExitMenu EXIT SIGINT SIGTERM

# Appel de la fonction principale
main_loop
