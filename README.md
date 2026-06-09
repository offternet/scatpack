# scatpack
Browser based command and control execution system

# Scatpack: Browser-Based Modular Command Execution Platform

![License](https://img.shields.io/badge/license-MIT-green)![Platform](https://img.shields.io/badge/platform-Linux-blue)![Node](https://img.shields.io/badge/node-16+-brightgreen)![Status](https://img.shields.io/badge/status-active-success)> A transparent, modular command execution platform that decouples the browser UI from system execution, enabling powerful Linux workflows without compiled black boxes or cloud dependencies.

Scatpack treats the browser as a dumb button panel—not an interpreter. Execute bash commands, launch GUI apps, and build complex workflows through a clean HTTP/WebSocket interface, all running locally on your machine.

## What Makes Scatpack Different

Traditional Linux GUI tools force you to choose: GTK, Qt, Python GUI libraries, Electron, or massive compiled binaries. Scatpack offers a new approach:

* **Browser as Frontend** - HTML, CSS, and JavaScript provide the UI

* **Bash as Backend** - Local command execution, no cloud dependency

* **Modular Steps** - Each task is independent, replaceable, and testable

* **File-Based Communication** - Simple contracts between steps (no complex APIs)

* **Zero Vendor Lock-in** - Edit, replace, and extend every component

## Features

* ✅ **Dual Execution Methods** - Direct HTTP to socat (port 9000) or WebSocket bridge (port 8080)

* ✅ **20-Button Dashboard** - Customizable Scatpack UI with drag-reorder and profile switching

* ✅ **Terminal & GUI Apps** - Port 9000 for bash commands (spawns gnome-terminal), port 9001 for GUI apps (no terminal)

* ✅ **Optional Node Bridge** - Stream terminal output over WebSocket (port 3001) only when needed

* ✅ **No Dependencies** - Works without Node.js, VPN, or reverse proxy for basic execution

* ✅ **CORS Bypass** - Local HTTP links bypass browser security restrictions entirely

* ✅ **Modular Architecture** - Replace any step with Bash, Python, Node.js, AppImage, or compiled binaries

* ✅ **RiteBrowser Integration** - Use Calamares webview as a structured workflow engine

* ✅ **Profile-Based Workflows** - Save and switch between task-based button configurations

* ✅ **Live Output Streaming** - Watch command execution in real-time through the UI

* ✅ **Transparent Logging** - All output written to `/tmp/terminalOut.txt` and multiple log files for debugging

## Quick Start

Get up and running in 5 minutes:

```bash
# Clone the repository
git clone https://github.com/yourusername/scatpack.git
cd scatpack

# Start the socat backend (port 9000 for bash, 9001 for GUI apps)
./StartDesktop-socat9000-server-V2.4.sh

# In another terminal, start the optional Node bridge (ports 8080 & 3001)
node bridge.js

# Open your browser to the Scatpack UI
# For direct HTTP: http://localhost:9000/ls
# For WebSocket UI: open the HTML file in your browser
```

Visit `http://localhost:9000/ls` to test the socat backend. You should see a terminal window popup.

## Installation

### Prerequisites

* Linux system (Ubuntu, Fedora, Arch, etc.)

* `socat` installed (`sudo apt install socat` or equivalent)

* `gnome-terminal` (or modify the script for your terminal)

* Node.js 16+ (optional, only if using the WebSocket bridge)

* Modern web browser (Firefox, Chrome, Edge, Safari)

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/scatpack.git
cd scatpack
```

### Step 2: Install socat

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install socat

# Fedora/RHEL
sudo dnf install socat

# Arch
sudo pacman -S socat
```

### Step 3: Make Scripts Executable

```bash
chmod +x StartDesktop-socat9000-server-V2.4.sh
chmod +x bridge.js
```

### Step 4: Start the Socat Backend

```bash
./StartDesktop-socat9000-server-V2.4.sh
```

This binds socat to localhost:9000 (bash commands) and localhost:9001 (GUI apps).

### Step 5 (Optional): Start the Node Bridge

If you want WebSocket support and live terminal output streaming:

```bash
node bridge.js
```

This starts:

* Port 8080: WebSocket command endpoint + static file serving

* Port 3001: Terminal output stream

### Step 6: Open the Scatpack UI

**Option A - Direct HTML (no Node required)**

Open `scatpack-ui.html` in your browser. Click any button to execute commands directly via socat.

**Option B - Node Bridge (with output streaming)**

Navigate to `http://localhost:8080` in your browser. The Node bridge serves the UI and streams live output.

## Usage

### Basic Example: Direct HTTP Execution

The simplest method—no Node.js needed:

```bash
# Open a browser link
http://localhost:9000/ls%20-la

# Or from the command line
curl http://localhost:9000/ls

# The command executes in a gnome-terminal window
```

### Scatpack UI: 20-Button Dashboard

The Scatpack UI provides a clickable dashboard for repeated tasks:

```javascript
// Button configuration (stored in localStorage)
{
  "A1": {
    "label": "List Files",
    "url": "http://localhost:9000/ls%20-la",
    "category": "Files"
  },
  "A2": {
    "label": "Open VLC",
    "url": "http://localhost:9001/vlc",
    "category": "Apps"
  },
  "A3": {
    "label": "Update System",
    "url": "http://localhost:9000/sudo%20apt%20update",
    "category": "System"
  }
}
```

**Features:**

* Drag-reorder buttons

* Save/load profiles

* Dark mode toggle

* Category filtering

* Search functionality

### WebSocket Method: Real-Time Output

Send commands over WebSocket and receive live terminal output:

```javascript
// Connect to the WebSocket bridge
const ws = new WebSocket('ws://localhost:8080/shell');

// Send a command
ws.send('ls -la');

// Receive output
ws.onmessage = (event) => {
  console.log('Output:', event.data);
};
```

The Node bridge forwards the command to socat and streams the output back.

### Advanced Usage: Modular Workflows

Build multi-step processes where each step is independent:

```bash
# Step 1: Scan partitions
./steps/01-scan-partitions/run.sh

# Step 2: Select source/build
./steps/02-select-partitions/run.sh

# Step 3: Mount partitions
./steps/03-mount-partitions/run.sh

# Each step writes to shared files:
# /tmp/partSelect (input for next step)
# /tmp/terminalOut.txt (output log)
```

Each step can be:

* Tested independently

* Replaced with a different language

* Debugged without affecting others

* Documented with its own help page

## Architecture

### Port Overview

| Port

 | Purpose

 | Example

 |
|---|---|---|
| 9000

 | Bash commands (spawns terminal)

 | `http://localhost:9000/ls`

 |
| 9001

 | GUI apps (no terminal)

 | `http://localhost:9001/vlc`

 |
| 8080

 | WebSocket command bridge + static files

 | `ws://localhost:8080/shell`

 |
| 3001

 | Terminal output stream

 | `ws://localhost:3001`

 |
| 9500

 | UI router / mode switch (optional)

 | Load dynamic button sets

 |

### Component Overview

```
Browser (UI Layer)
  ├─ Scatpack UI (HTML/CSS/JS)
  │  └─ Fetch to http://localhost:9000
  │
  ├─ WebSocket Client
  │  └─ ws://localhost:8080/shell
  │
  └─ Output Terminal
     └─ ws://localhost:3001
        
Local Machine (Execution Layer)
  ├─ socat (port 9000, 9001)
  │  └─ Converts HTTP → bash commands
  │
  ├─ Node Bridge (port 8080, 3001)
  │  ├─ Forwards WebSocket → HTTP → socat
  │  └─ Streams output from /tmp/terminalOut.txt
  │
  └─ Bash Responder
     ├─ Parses HTTP path as command
     ├─ Executes asynchronously
     └─ Logs to multiple files
```

## Configuration

### Socat Script Configuration

Edit `StartDesktop-socat9000-server-V2.4.sh`:

```bash
# Bind to localhost only (security)
bind=127.0.0.1

# Change port numbers
PORT_BASH=9000
PORT_GUI=9001

# Modify terminal emulator
TERMINAL="gnome-terminal"  # or "xterm", "konsole", etc.
```

### Node Bridge Configuration

Edit `bridge.js`:

```javascript
const TARGET_HOST = '127.0.0.1';
const TARGET_PORT = 9000;
const WS_PORT = 8080;
const OUTPUT_PORT = 3001;
const OUTPUT_FILE = '/tmp/terminalOut.txt';
```

### Scatpack UI Configuration

Edit `scatpack-ui.html`:

```javascript
// Default host (change if running remotely)
const DEFAULT_HOST = 'http://localhost';

// WebSocket ports
const WS_COMMAND_PORT = 8080;
const WS_OUTPUT_PORT = 3001;

// Button grid size
const BUTTON_ROWS = 5;
const BUTTON_COLS = 4;
```

## Security Considerations

### ⚠️ Important: Local-Only Binding

By default, socat listens on `127.0.0.1` (localhost only). **Never bind to \`0.0.0.0\` unless you fully understand the risks.**

```bash
# SAFE (localhost only)
socat TCP-LISTEN:9000,bind=127.0.0.1,reuseaddr,fork ...

# DANGEROUS (network-exposed)
socat TCP-LISTEN:9000,reuseaddr,fork ...
```

### Command Whitelisting

Restrict which commands can execute:

```bash
# In your socat responder script
ALLOWED_COMMANDS=("ls" "apt-update" "vlc" "gimp")

if [[ ! " ${ALLOWED_COMMANDS[@]} " =~ " ${cmd} " ]]; then
  echo "Command not allowed: $cmd"
  exit 1
fi
```

### Authentication (Optional)

Add basic auth to the socat listener:

```bash
# Self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365

# socat with SSL + basic auth
socat TCP-LISTEN:9000,bind=127.0.0.1,reuseaddr,fork \
  OPENSSL:localhost:9001,cert=cert.pem,key=key.pem
```

Or wrap socat with a simple Python auth layer (10 lines).

## Testing

### Test the Socat Backend

```bash
# Start socat
./StartDesktop-socat9000-server-V2.4.sh

# Test bash command (should spawn terminal)
curl http://localhost:9000/ls

# Test GUI app (should launch without terminal)
curl http://localhost:9001/vlc
```

### Test the Node Bridge

```bash
# Start Node bridge
node bridge.js

# Test WebSocket command
wscat -c ws://localhost:8080/shell
> ls -la
< (output from socat)

# Test output stream
wscat -c ws://localhost:3001
< (live terminal output)
```

### Test the Scatpack UI

1. Open `scatpack-ui.html` in your browser

2. Click button A1 (should execute a test command)

3. Verify output appears in the terminal panel

4. Try drag-reordering a button

5. Save a profile and reload the page (should persist)

## Troubleshooting

### "Connection refused" on port 9000

```bash
# Check if socat is running
lsof -i :9000

# Start the socat server
./StartDesktop-socat9000-server-V2.4.sh

# Check logs
tail -f /tmp/scatpack/s9000.log
```

### Terminal window doesn't appear

```bash
# Verify gnome-terminal is installed
which gnome-terminal

# Or use a different terminal
sed -i 's/gnome-terminal/xterm/g' StartDesktop-socat9000-server-V2.4.sh
```

### WebSocket output not streaming

```bash
# Verify Node bridge is running
lsof -i :8080

# Check if /tmp/terminalOut.txt exists
ls -la /tmp/terminalOut.txt

# Restart the bridge
pkill -f "node bridge.js"
node bridge.js
```

### Command injection errors

```bash
# Check socat logs for malformed commands
cat /tmp/socat_live_feed.txt

# URL-decode the command manually
echo "ls%20-la" | sed 's/%20/ /g'
```

## Contributing

Contributions are welcome! This project thrives on modularity and transparency.

### How to Contribute

1. **Fork the repository**

```bash
git clone https://github.com/yourusername/scatpack.git
cd scatpack
git checkout -b feature/your-feature-name
```

20. **Make your changes**

Keep the KISS principle in mind:

* One step = one file

* Each step has input, execution, output, log

* No hidden complexity

* Document your changes

* **Test thoroughly**

```bash
# Test your step independently
./steps/your-step/run.sh

# Check logs
cat /tmp/terminalOut.txt

# Test with the UI
# (open scatpack-ui.html and click your button)
```

40. **Commit and push**

```bash
git add .
git commit -m "Add: your feature description"
git push origin feature/your-feature-name
```

50. **Open a Pull Request**

Include:

* What the change does

* Why it's needed

* Any new dependencies

* Test results

### Code of Conduct

* Be respectful and constructive

* Focus on clarity and simplicity

* Document your code

* Test before submitting

* Explain the "why" behind changes

## Roadmap

* Core socat HTTP-to-bash bridge

* Scatpack UI (20-button dashboard)

* WebSocket command method

* Live output streaming (port 3001)

* Command whitelisting system

* Built-in authentication layer

* RiteBrowser / Calamares webview integration

* Windows PowerShell version

* Mobile-responsive UI

* Step execution history / rollback

* Plugin system for custom steps

* Dry-run mode for dangerous commands

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

* **socat** - The elegant Unix relay that makes this all possible

* **Calamares** - For showing how modular installers can be

* **The Unix Philosophy** - Do one thing and do it well

* **Browser APIs** - For WebSocket and Fetch standards

* **Community feedback** - For pushing toward transparency and modularity

## Support

* 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/scatpack/issues)

* 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/scatpack/discussions)

* 📖 **Documentation**: See `docs/` folder for detailed guides

* 🧪 **Testing**: Run `./test-all.sh` to verify your setup

## Why Scatpack?

Most GUI systems hide their own logic behind compiled binaries or opaque frameworks. Scatpack does the opposite: it invites you in.

* **Edit** the HTML to change the UI

* **Modify** the Bash to change behavior

* **Replace** any step without breaking others

* **Understand** every layer from browser to command execution

* **Learn** by reading simple, modular code

This is the spirit of '93—powerful tools that don't require a PhD to understand or modify.

---

Made with ❤️ by the Scatpack community. Built on the principle that power should be understandable.
