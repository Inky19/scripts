#!/usr/bin/env bash

WARN='\033[0;33m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m'

echoError() {
    echo -e "${ERROR}Error: $1${NC}\nExiting..." 1>&2
    exit 1
}

echoInfo() {
    echo -e "${INFO}$1${NC}"
}

echoWarn() {
    echo -e "${WARN}Warning: $1${NC}"
}

echoSuccess() {
    echo -e "${SUCCESS}$1${NC}"
}

opt_tray=0
opt_animation=0
opt_icon=0
opt_path=""
opt_icon_path=""
opt_verbose=0
opt_skip_root_check=0
opt_skip_confirmation=0

asar_path="/usr/lib/vesktop"
icon_path="/usr/share/icons/hicolor"
skip_confirmation=0


echo -e "Vesktop Customization Script by ${SUCCESS}Inky19${NC}"
echo -e "--------------------------------------"
echoInfo "This script will customize the tray icon and animation of Vesktop."
echoInfo "Use the -h option for help."
echo -e ""

# Parse options
while getopts "hytavp:" opt; do
    case ${opt} in
        h)
            echoInfo "Usage: customize.sh [-hytapv]"
            echo "Options:"
            echo "  -h  Display this help message."
            echo "  -y  Customize everything without confirmation."
            echo "  -t  Skip confirmation of customizing the tray."
            echo "  -a  Skip confirmation of customizing the animation."
            echo "  -i  Skip confirmation of customizing the desktop icon."
            echo "  -p  path to the Vesktop app.asar directory."
            echoInfo "      Default path is '$asar_path'."
            echo "  -d  path to the Vesktop icon parent directory."
            echoInfo "      Default path is '$icon_path'."
            echoInfo "      Icons must placed in assets/icons and have the same name as their dimensions (e.g. 16x16.png, 32x32.png, etc.)."
            echo "  -v  Display verbose information."
            echo "  -r  Skip root check when replacing app.asar."
            exit 0
            ;;
        y)
            opt_tray=1
            opt_animation=1
            opt_icon=1
            opt_skip_confirmation=1
            opt_path=$asar_path
            opt_icon_path=$icon_path
            ;;
        t)
            opt_tray=1
            ;;
        a)
            opt_animation=1
            ;;
        i)
            opt_icon=1
            ;;
        p)
            opt_path=$OPTARG
            ;;
        d)
            opt_icon_path=$OPTARG
            ;;
        v)
            opt_verbose=1
            ;;
        r)
            opt_skip_root_check=1
            ;;
        \?)
            echoError "Invalid option: $OPTARG"
            ;;
    esac
done

# Interactive mode
if [ $skip_confirmation -eq 0 ]; then

    if [[ $opt_tray -eq 0 ]]; then
        read -p "Customize tray icon ? [Y/n] " -n 1 -r
        echo
        if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
            opt_tray=1
        fi
    fi

    if [[ $opt_animation -eq 0 ]]; then
        read -p "Customize animation ? [Y/n] " -n 1 -r
        echo
        if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
            opt_animation=1
        fi
    fi

    if [[ $opt_icon -eq 0 ]]; then
        read -p "Customize desktop icon ? [Y/n] " -n 1 -r
        echo
        if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
            opt_icon=1
        fi
    fi

    if [[ $opt_tray -eq 0 ]] && [[ $opt_animation -eq 0 ]] && [[ $opt_icon -eq 0 ]]; then
        echoInfo "No customization selected. Exiting."
        exit 0
    fi

    if [[ -z "$opt_path" ]]; then
        read -p "Enter path to the Vesktop app.asar directory. Default is '$asar_path': " opt_path
    fi

    if [[ -z "$opt_icon_path" ]]; then
        read -p "Enter path to the Vesktop icon root directory. Default is '$icon_path': " opt_icon_path
    fi     
fi

# Desktop icon customization
# Path confirmation
if [[ -z "$opt_icon_path" ]]; then
    echoWarn "No path specified. Will try to use default path '$icon_path'."
else
    icon_path=$opt_icon_path
    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Using icon path '$icon_path'."
    fi
fi

deleteIcon () {
    icon_file=$1

    if [[ -f "$icon_file" ]]; then
        rm "$icon_file"
    fi
}

copyIcon () {
    icon_file=$1
    target=$2

    WARN='\033[0;33m'
    NC='\033[0m'

    if [[ -f "$icon_file" ]]; then
        cp "$icon_file" "$target"
    else
        echo -e "${WARN}Invalid icon file ${icon_file}. Skipping.${NC}"
    fi
}

# Iterate on sub directories of icon_path
if [[ ! -d "$icon_path" ]]; then
    echoError "Path $icon_path does not exist." 
fi
if [[ $opt_icon -eq 1 ]]; then
    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Customizing desktop icon..."
    fi

    if [[ ! -d "./assets/icons" ]]; then
        echoError "No icons found. Please create a directory named 'assets/icons' and place your icons there."
    fi

    if [[ ! -d "$icon_path" ]]; then
        echoError "Icon path $icon_path does not exist. Exiting."
    fi

    echo "This section will require root access to replace the app.asar file."
    echo "Please enter your password if prompted."

    # For each subdirectory in icon_path check if it contains a in ./apps/vesktop.png
    for dir in "$icon_path"/*; do

    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Checking directory $dir for vesktop.png..."
    fi
    
        if [[ -d "$dir" ]]; then
            icon_file="$dir/apps/vesktop.png"
            if [[ -f "$icon_file" ]]; then
                if [[ $opt_verbose -eq 1 ]]; then
                    echoInfo "Deleting icon in $dir..."
                fi
                if [[ $opt_skip_root_check -eq 0 && "$EUID" -ne 0 ]]; then
                    sudo bash -c "$(declare -f deleteIcon); deleteIcon $icon_file" 
                else
                    deleteIcon $icon_file
                fi
            else
                if [[ $opt_verbose -eq 1 ]]; then
                    echoWarn "No vesktop.png found in $dir. Skipping."
                fi
            fi
        fi
    done

    # Copy new icons
    for icon_file in ./assets/icons/*; do
        if [[ -f "$icon_file" ]]; then
            icon_name=$(basename "$icon_file")
            icon_name_without_ext="${icon_name%.*}"
            icon_dir="$icon_path/$icon_name_without_ext/apps"
            if [[ ! -d "$icon_dir" ]]; then
                echoWarn "Directory $icon_dir does not exist! Skipping copy."
                continue
            fi
            if [[ $opt_verbose -eq 1 ]]; then
                echoInfo "Copying $icon_file to $icon_dir/vesktop.png..."
            fi
            if [[ $opt_skip_root_check -eq 0 && "$EUID" -ne 0 ]]; then
                sudo bash -c "$(declare -f copyIcon); copyIcon $icon_file $icon_dir/vesktop.png" 
            else
                copyIcon $icon_file "$icon_dir/vesktop.png"
            fi
        else
         if [[ $opt_verbose -eq 1 ]]; then
                echoWarn "No icon file found in ./assets/icons. Skipping."
            fi
        fi
    done
fi
echoInfo "Desktop icon customization complete."

echoInfo "Starting customization of app.asar..."
# Path validation
if [[ -z "$opt_path" ]]; then
    echoWarn "No path specified. Will try to use default path '$asar_path'."
else
    asar_path=$opt_path
    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Using path '$asar_path'."
    fi
fi

if [[ ! -d "$asar_path" ]]; then
    echoError "Path $asar_path does not exist." 
fi

if [[ ! -f "$asar_path/app.asar" ]]; then
    echoError "Path $asar_path does not contain app.asar."
fi

# Create temporary directory
tmp_dir=$(mktemp -d)

if [[ -z "$tmp_dir" || ! -d "$tmp_dir" ]]; then
    echoError "Failed to create temporary directory. Exiting."
fi

if [[ $opt_verbose -eq 1 ]]; then
    echoInfo "Created temporary directory $tmp_dir."
fi

# Extract app.asar
echoInfo "Extracting app.asar..."
asar extract "$asar_path/app.asar" "$tmp_dir/app"

# Customization
if [[ $opt_tray -eq 1 ]]; then
    if [ $opt_verbose -eq 1 ]; then
        echoInfo "Customizing tray..."
    fi
    if [[ ! -f "./assets/tray.png" ]]; then
        echoError "Tray icon not found. File must be named 'tray.ico' and placed in a subdirectory named "assets". Exiting."
    fi
    rm "$tmp_dir/app/static/icon.png"
    cp "./assets/tray.png" "$tmp_dir/app/static/icon.png"
fi

if [[ $opt_animation -eq 1 ]]; then
    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Customizing animation..."
    fi

    if [[ ! -f "./assets/animation.gif" ]]; then
        echoError "Animation not found. File must be named 'animation.gif' and placed in a subdirectory named "assets". Exiting."
    fi
    rm "$tmp_dir/app/static/shiggy.gif"
    cp "./assets/animation.gif" "$tmp_dir/app/static/shiggy.gif"
fi

# Pack app.asar
echoInfo "Packing app.asar..."
asar pack "$tmp_dir/app" "$tmp_dir/app.asar"

# Might need root access to replace app.asar
replaceAsar () {
    asar_path=$1
    tmp_dir=$2

    INFO='\033[0;36m'
    NC='\033[0m'

    echo -e "${INFO}Backing up app.asar to app.asar.old...${NC}"
    if [[ -f "$asar_path/app.asar.old" ]]; then
        rm "$asar_path/app.asar.old"
    fi
    mv "$asar_path/app.asar" "$asar_path/app.asar.old"

    if [[ $opt_verbose -eq 1 ]]; then
        echo -e "${INFO}Replacing app.asar...${NC}"
    fi
    mv "$tmp_dir/app.asar" "$asar_path/app.asar"

}

# Execute with root access if necessary
if [[ $opt_skip_root_check -eq 0 && "$EUID" -ne 0 ]]; then
    echo "This section will require root access to replace the app.asar file."
    echo "Please enter your password if prompted."
    sudo bash -c "$(declare -f replaceAsar); replaceAsar $asar_path $tmp_dir" 
else
    replaceAsar $asar_path $tmp_dir
fi

echoInfo "Cleaning up..."

# Temporary directory cleanup
# Remove in two steps to prevent accidental deletion of other files in case of a script error.
rm -r "$tmp_dir/app"
if [[ -z "$(ls -A $tmp_dir)" ]]; then
    rm -r "$tmp_dir"
else 
    echoWarn "Unknown files in temporary directory '$tmp_dir'. Please remove manually."
fi

echoSuccess "Customization complete. Please restart Vesktop to see changes."
exit 0
