#!/bin/bash
# StartDesktop-socat9001-server-V2.5.sh - FIXED + STABLE
# MIT LICENSE 2026 (c) ROBERT J.COOPER http://startdesktop.com
# This file receives commands (unformated) that are sent from Scatpack UI via socat port 9000
# Unformated commands are parsed, filtered, and executed.
# HTTP Referrer script is created at /tmp/URL-responder.sh
# Command side stream STDOUT is by appedning to file /tmp/termialOut.txt using | tee -a /tmp/terminalOut.txt
# All commands; gui apps, bash regular, bash sudo, open websites can be processed by this same bash script.
# Example commands: http://localhost:9000/ls | http://localhost:9000/ls | http://localhost:9000/sudo apt update && sudo apt upgrade
# http://localhost:9000/cd ~/ && cp ./index.html ./my-website.html | http://localhost:9000/xdg-open http://yahoo.com 
# http://localhost:9000/vlc 


PORT=9001

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

LOGDIR="/tmp/scatpack"
mkdir -p "$LOGDIR"

touch /tmp/scatpack/s9001

export OUT="/tmp/terminalOut.txt"
S9001_LOG="$LOGDIR/s9001.log"



# ==============================
# Command Execution (FIXED)
# ==============================
parse_and_execute() {
    local cmd="$1"

    echo "[$(date +%H:%M:%S)] Processing: $cmd" >> "$OUT"

    # Clear + header
    {
        echo ""
        echo "======================================"
        echo "NOW LAUNCHING: $cmd"
        echo "======================================"
        echo ""
    } > "$OUT"

    # Run command safely
    bash -c "$cmd" >> "$OUT" 2>&1
}

export -f parse_and_execute

# ==============================
# HTTP Responder (FIXED)
# ==============================
cat > /tmp/url-responder9001.sh << 'EOF'
#!/bin/bash

OUT="/tmp/terminalOut.txt"

# Read HTTP request
read -r request

# Extract path
full_path=$(echo "$request" | awk '{print $2}')
clean_path="${full_path%%\?*}"

echo "[$(date +%H:%M:%S)] Request: $request" >&2
echo "[$(date +%H:%M:%S)] Path: $clean_path" >&2

# Extract command
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

EOF

chmod +x /tmp/url-responder9001.sh

# ==============================
# Get Local IP
# ==============================
get_ip() {
    ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1
}

SERVER_IP=$(get_ip)
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"

# ==============================
# Startup Banner
# ==============================
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        SOCAT COMMAND SERVER (FIXED VERSION)                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Server:"
echo "  http://localhost:$PORT"
echo ""
echo "Examples:"
echo "  http://localhost:$PORT/ls"
echo "  http://localhost:$PORT/ls%20-l"
echo "  http://localhost:$PORT/xdg-open%20https://google.com"
echo "  http://localhost:$PORT/sudo%20apt%20update"
echo ""
echo "Output file:"
echo "  $OUT"
echo ""
echo "Logs:"
echo "  $S9001_LOG"
echo ""
echo "=============================================================="
echo ""

# ==============================
# START SOCAT (STABLE)
# ==============================
stdbuf -oL socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:/tmp/url-responder9001.sh 2>>"$S9001_LOG"
