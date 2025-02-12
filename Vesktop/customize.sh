#!/usr/bin/env bash

WARN='\033[0;33m'
INFO='\033[0;36m'
ERROR='\033[0;31m'
SUCCESS='\033[0;32m'
NC='\033[0m'

echoError() {
    echo -e "${ERROR}Error: $1${NC}\n Exiting..." 1>&2
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
opt_path=""
opt_verbose=0
opt_skip_root_check=0
opt_skip_confirmation=0

path="/usr/lib/vesktop"
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
            echo "  -y  Skip confirmation and customize tray and animation."
            echo "  -t  Skip confirmation and customize tray."
            echo "  -a  Skip confirmation and customize animation."
            echo "  -p  path to the Vesktop app.asar directory."
            echoInfo "      Default path is '$path'."
            echo "  -v  Display verbose information."
            echo "  -r  Skip root check when replacing app.asar."
            exit 0
            ;;
        y)
            opt_tray=1
            opt_animation=1
            opt_skip_confirmation=1
            ;;
        t)
            opt_tray=1
            ;;
        a)
            opt_animation=1
            ;;
        p)
            opt_path=$OPTARG
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
    read -p "Customize tray icon ? [Y/n] " -n 1 -r
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        opt_tray=1
    fi

    read -p "Customize animation ? [Y/n] " -n 1 -r
    echo
    if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        opt_animation=1
    fi

    if [[ "$opt_tray" = 0 ]] && [ "$opt_animation" = 0 ]; then
        echoInfo "No customization selected. Exiting."
        exit 0
    fi

    read -p "Enter path to the Vesktop app.asar directory. Default is '$path': " opt_path
fi

# Path validation
if [[ -z "$opt_path" ]]; then
    echoWarn "No path specified. Will try to use default path '$path'."
fi

if [[ ! -d "$path" ]]; then
    echoError "Path $path does not exist." 
fi

if [[ ! -f "$path/app.asar" ]]; then
    echoError "Path $path does not contain app.asar."
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
asar extract "$path/app.asar" "$tmp_dir/app"

# Customization
if [[ $opt_tray -eq 1 ]]; then
    if [ $opt_verbose -eq 1 ]; then
        echoInfo "Customizing tray..."
    fi
    if [[ ! -f "./tray.png" ]]; then
        echoError "Tray icon not found. File must be named 'tray.ico' and placed in the same directory as the script. Exiting."
    fi
    rm "$tmp_dir/app/static/icon.png"
    cp "./tray.png" "$tmp_dir/app/static/icon.png"
fi

if [[ $opt_animation -eq 1 ]]; then
    if [[ $opt_verbose -eq 1 ]]; then
        echoInfo "Customizing animation..."
    fi

    if [[ ! -f "./animation.gif" ]]; then
        echoError "Animation not found. File must be named 'animation.gif' and placed in the same directory as the script. Exiting."
    fi
    rm "$tmp_dir/app/static/shiggy.gif"
    cp "./animation.gif" "$tmp_dir/app/static/shiggy.gif"
fi

# Pack app.asar
echoInfo "Packing app.asar..."
asar pack "$tmp_dir/app" "$tmp_dir/app.asar"

# Might need root access to replace app.asar
replaceAsar () {
    path=$1
    tmp_dir=$2

    INFO='\033[0;36m'
    NC='\033[0m'

    echo -e "${INFO}Backing up app.asar to app.asar.old...${NC}"
    if [[ -f "$path/app.asar.old" ]]; then
        rm "$path/app.asar.old"
    fi
    mv "$path/app.asar" "$path/app.asar.old"

    if [[ $opt_verbose -eq 1 ]]; then
        echo -e "${INFO}Replacing app.asar...${NC}"
    fi
    mv "$tmp_dir/app.asar" "$path/app.asar"

}

# Execute with root access if necessary
if [[ $opt_skip_root_check -eq 0 && "$EUID" -ne 0 ]]; then
    echo "This section will require root access to replace the app.asar file."
    echo "Please enter your password when prompted."
    sudo bash -c "$(declare -f replaceAsar); replaceAsar $path $tmp_dir" 
else
    replaceAsar $path $tmp_dir
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
