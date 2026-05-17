#!/bin/bash

# --------------------------------------
# MEDAT Timer
# Simulates the official MEDAT exam timer
# using a digital clock display
# --------------------------------------

# --------------------------------------
# Display application header
# --------------------------------------
show_header() {
    clear
    echo "           MEDAT Timer"
    echo "================================="
    echo
}

# --------------------------------------
# Define MEDAT test modules (in seconds)
# --------------------------------------
declare -A MODES=(
    [bi]=1800     # Biology (30 min)
    [ch]=1080     # Chemistry (18 min)
    [ph]=960      # Physics (16 min)
    [ma]=660      # Mathematics (11 min)
    [tv]=2100     # Text Comprehension (35 min)
    [fz]=1200     # Figure Assembly (20 min)
    [gm]="gm"     # Memory section (special case)
    [zf]=900      # Number Sequences (15 min)
    [wf]=1200     # Word Fluency (20 min)
    [ie]=600      # Implication Recognition (10 min)
    [er]=1080     # Emotion Regulation (18 min)
    [ee]=1260     # Emotion Recognition (21 min)
    [se]=1260     # Social Decision Making (21 min)
)

# --------------------------------------
# Check if figlet is installed
# --------------------------------------
check_dependencies() {
    if ! command -v figlet >/dev/null; then
        echo "Error: figlet is not installed."
        echo "Install it with: sudo apt install figlet"
        exit 1
    fi
}

# --------------------------------------
# Display digital clock
# Mimics the MEDAT exam interface
# --------------------------------------
ascii_clock() {
    while true; do
        clear
        date +"%H:%M:%S" | figlet -f big
        sleep 1
    done
}

# --------------------------------------
# Play notification sound
# --------------------------------------
play_notification() {
    if command -v paplay >/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga
    elif command -v afplay >/dev/null; then
        afplay /System/Library/Sounds/Glass.aiff
    else
        echo -e "\a"
    fi
}

# --------------------------------------
# Countdown before test starts
# --------------------------------------
start_countdown() {
    for count in 3 2 1; do
        echo "$count..."
        sleep 1
    done
    echo "Start!"
}

# --------------------------------------
# Run a timer session
# --------------------------------------
run_timer() {
    local total_time=$1

    echo
    echo "Press Enter when you're ready..."
    read -r

    start_countdown

    start_time=$(date +%H:%M:%S)

    echo
    echo "Start time: $start_time"
    echo "Duration: $((total_time / 60)) minutes and $((total_time % 60)) seconds"
    echo
    echo "Memorize the start time. It will disappear in 5 seconds."
    
    sleep 5

    ascii_clock &
    clock_pid=$!

    sleep "$total_time"

    kill "$clock_pid" 2>/dev/null

    echo
    echo "Time is up."

    play_notification
}

# --------------------------------------
# Handle custom timer mode
# --------------------------------------
run_custom_mode() {
    read -p "Minutes: " minutes
    read -p "Seconds: " seconds

    total_time=$((minutes * 60 + seconds))

    run_timer "$total_time"
}

# --------------------------------------
# Handle memory section (GM)
# Special MEDAT structure
# --------------------------------------
run_memory_mode() {
    echo
    echo "Part 1: 8 minutes"
    run_timer 480

    echo
    echo "Waiting period: 35 minutes"
    run_timer 2100

    echo
    echo "Part 2: 20 minutes"
    run_timer 1200
}

# --------------------------------------
# Select test mode
# --------------------------------------
select_mode() {
    echo "Available modes:"
    echo "ie | fz | se | zf | ph | ma | ch | wf | tv | ee | er | gm | bi"
    echo "or type: custom"
    echo

    read -p "Choose a mode: " mode
}

# --------------------------------------
# Main application logic
# --------------------------------------
main() {
    check_dependencies
    show_header
    select_mode

    if [[ "$mode" == "custom" ]]; then
        run_custom_mode

    elif [[ "$mode" == "gm" ]]; then
        run_memory_mode

    elif [[ -n "${MODES[$mode]}" ]]; then
        run_timer "${MODES[$mode]}"

    else
        echo "Invalid mode selected."
        exit 1
    fi
}

# Execute program
main
