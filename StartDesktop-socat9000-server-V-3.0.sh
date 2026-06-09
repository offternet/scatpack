#!/bin/bash
# StartDesktop-socat9000-server-V2.4.sh - COMPLETE WORKING VERSION
# MIT LICENSE 2026 (c) ROBERT J.COOPER http://startdesktop.com
# This file receives commands (unformated) that are sent from Scatpack UI via socat port 9000
# Unformated commands are parsed, filtered, and executed.
# HTTP Referrer script is created at /tmp/URL-responder.sh
# Command side stream STDOUT is by appedning to file /tmp/termialOut.txt using | tee -a /tmp/terminalOut.txt
# All commands; gui apps, bash regular, bash sudo, open websites can be processed by this same bash script.
# Example commands: http://localhost:9000/ls | http://localhost:9000/ls | http://localhost:9000/sudo apt update && sudo apt upgrade
# http://localhost:9000/cd ~/ && cp ./index.html ./my-website.html | http://localhost:9000/xdg-open http://yahoo.com 
# http://localhost:9000/vlc 

PORT=9000

#!/bin/bash

if [ ! -f /usr/bin/socat ]; then
    yad --question \
        --text="socat is not installed. Install it now?" \
        --width=400 --height=100 --on-top --center \
        --button="Install:0" --button="Cancel:1"
   
    if [ $? -eq 0 ]; then
        sudo apt update
        sudo apt-get install socat -y
        
        # Verify installation worked
        if [  -f /usr/bin/socat ]; then
            yad --info --text="socat has been installed successfully!" \
                --width=400 --height=100 --timeout=5 --on-top --center
        else
            yad --error --text="Failed to install socat" \
                --width=400 --height=100 --on-top --center
        fi
    else
        yad --info --text="Ya can't play with socat until ya install it buddy" \
            --width=500 --height=100 --timeout=10 --on-top --center --button="Close:1" &
    fi
fi
mkdir -p /tmp/scatpack

touch /tmp/scatpack/s9000.log

LOGDIR="/tmp/scatpack"

export S9000_LOG="$LOGDIR/s9000.log"

# Function to run commands in a new terminal window (for bash_ prefixed commands)
runBash_cmd() {
    local cmd="$1"
    local OUT="/tmp/terminalOut.txt"

    gnome-terminal --window --title="Bash: $cmd" -- bash -c "
        echo '=========================================' | tee -a $OUT
        echo 'Now executing: $cmd' | tee -a $OUT
        echo '=========================================' | tee -a $OUT
        sleep 1

        echo '' | tee -a $OUT
        echo \"$cmd\" | tee -a $OUT
        echo '' | tee -a $OUT

        echo '--- OUTPUT ---' | tee -a $OUT

        # ✅ SINGLE SOURCE STREAM
        $cmd 2>&1 | tee -a $OUT

        echo '' | tee -a $OUT
        echo '=========================================' | tee -a $OUT
        echo 'Done. Press any key to close.' | tee -a $OUT
        echo '=========================================' | tee -a $OUT

        read -n 1
    " 2>/dev/null &
}

# Function to run commands with sudo
runSudo_cmd() {
    local cmd="$1"
    local OUT="/tmp/terminalOut.txt"

    gnome-terminal --window --title="Sudo: $cmd" -- bash -c "
        echo '=========================================' | tee -a $OUT
        echo 'Now executing (sudo): $cmd' | tee -a $OUT
        echo '=========================================' | tee -a $OUT
        sleep 1

        echo '' | tee -a $OUT
        echo \"$cmd\" | tee -a $OUT
        echo '' | tee -a $OUT

        echo '--- OUTPUT ---' | tee -a $OUT

        # ✅ SINGLE SOURCE STREAM
        sudo bash -c \"$cmd\" 2>&1 | tee -a $OUT

        echo '' | tee -a $OUT
        echo '=========================================' | tee -a $OUT
        echo 'Done. Press any key to close.' | tee -a $OUT
        echo '=========================================' | tee -a $OUT

        read -n 1
    " 2>/dev/null &
}

# Function to run regular commands
runRegular_cmd() {
    local cmd="$1"
    
    # Remove quotes if present
   # cmd="${cmd%\"}"
   # cmd="${cmd#\"}"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" > /dev/null 2>&1 &
        echo "[$(date +%H:%M:%S)] ✓ Regular: $cmd"
    else
        echo "[$(date +%H:%M:%S)] ✗ Command not found: $cmd"
    fi
}

# Main parse function
# Main parse function
parse_and_execute() {
    local cmd="$1"
    
    echo "[$(date +%H:%M:%S)] Processing: $cmd"
    

    
    # Regular command
    echo "[$(date +%H:%M:%S)]   Regular: $cmd"
    runBash_cmd "$cmd"
}

# Export all functions
export -f runBash_cmd
export -f runSudo_cmd
export -f runRegular_cmd
export -f parse_and_execute

# Create the responder script
cat > /tmp/url-responder.sh << 'EOF'
#!/bin/bash

OUT="/tmp/terminalOut.txt"

# Read the HTTP request
read -r request

# Extract the path and strip query parameters
full_path=$(echo "$request" | awk '{print $2}')
clean_path="${full_path%%\?*}"

echo "[$(date +%H:%M:%S)] Request: $request" >&2
echo "[$(date +%H:%M:%S)] Clean path: $clean_path" >&2

# Extract command from /launch/ or /exec/
cmd=""
if [[ "$clean_path" =~ ^/(.+)$ ]]; then
    cmd="${BASH_REMATCH[1]}"
fi

if [ -n "$cmd" ]; then

# 🔥 BETTER DECODING: Specific chars first, then general %XX → space
cmd=$(echo "$cmd" | sed -E '
    # === Specific important characters first ===
    s/%3E/>/gi
    s/%26/&/gi
    s/%22/"/gi
    s/%3C/</gi
    s/%7C/|/gi
    s/%24/\$/gi
    s/%27/'\''/gi
    s/%3B/;/gi
    s/%3D/=/gi
    s/%5C/\\/gi
    s/%60/`/gi
    s/%7B/{/gi
    s/%7D/}/gi
    s/%28/(/gi
    s/%29/)/gi
    s/%2A/*/gi
    s/%2B/+/gi
    s/%2F/\//gi
' | sed -E 's/%[0-9A-Fa-f]{2}/ /g; s/%+/ /g' | tr -s ' ' | sed 's/^ *//; s/ *$//')

    # 🔥 STRIP ALL %* → SINGLE SPACE
	cmd=$(echo "$cmd" | sed -E 's/%[0-9A-Fa-f]{2}/ /g; s/%+/ /g' | tr -s ' ' | sed 's/^ *//; s/ *$//')
    echo "[$(date +%H:%M:%S)] Command: $cmd" >&2

    # ==============================
    # ✅ SEND RESPONSE FIRST (KEY FIX)
    # ==============================
    echo -e "HTTP/1.0 200 OK\r"
    echo -e "Content-Type: text/html\r"
    echo -e "Connection: close\r"
    echo -e "\r"
    echo -e "<html><body><b>OK</b></body></html>\r"

    # ==============================
    # ✅ EXECUTE ASYNC (NO PIPE BREAK)
    # ==============================
    parse_and_execute "$cmd" &

else
    echo -e "HTTP/1.0 200 OK\r\n\r\nNo command"
fi

# Send response
echo -e "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r"
echo -e "<!DOCTYPE html><html><head><script>window.close();</script></head><body>Done</body></html>\r"
EOF

chmod +x /tmp/url-responder.sh

# Get local IP
get_ip() {
    ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1
}

SERVER_IP=$(get_ip)
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        SOCAT COMMAND SERVER (FIXED VERSION)                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Server:"
echo "  http://localhost:$PORT"
echo ""
echo "TEST THESE URLS:"
echo "  http://localhost:$PORT/launch/bash_\"ls -l\""
echo "  http://localhost:$PORT/launch/gocat_bash_\"ls -l\""
echo "  http://localhost:$PORT/launch/sudo_\"apt list --upgradable\""
echo "  http://localhost:$PORT/launch/gnome-calculator"
echo ""
echo "================================================================"
echo ""

# ==============================
# START SOCAT (STABLE)
# ==============================
stdbuf -oL socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:/tmp/url-responder.sh 2>>"$S9000_LOG"
