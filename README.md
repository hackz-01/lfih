# LFIH - Ultra-Fast LFI Scanner for Bug Bounty Testing (Hacker UI Edition)

## Overview

**LFIH** is an ultra-fast, parallel LFI (Local File Inclusion) vulnerability scanner designed for bug bounty testing and authorized security assessments. The tool leverages GNU Parallel and curl to test thousands of payloads in parallel, providing real-time status updates including the number of payloads tested, percentage completion, and elapsed time.

> **Disclaimer:** This tool is provided for educational and authorized security testing purposes only. Do not use it against systems for which you do not have explicit permission.

## Features

- **Ultra-Fast Scanning:** Uses GNU Parallel to dispatch multiple requests concurrently.
- **Real-Time Updates:** Displays a continuously updated status line showing:
  - Payloads tested (with percentage)
  - Elapsed time in `hh:mm:ss` format
- **Customizable Options:**
  - Custom payload file
  - Proxy support
  - Custom User-Agent string
  - Optional immediate exit on vulnerability detection
- **Hacker-Style UI:** Features a clear screen startup with an ASCII banner and colored output.
- **Logging:** Vulnerabilities are logged to a file (`found.txt`) for later analysis.

## Requirements

- **Bash**
- **GNU Parallel**
- **curl**
- A Unix-like operating system (Linux, macOS, etc.)

## Installation

### Clone the Repository or Download the Script

```bash
git clone https://github.com/yourusername/lfih.git
cd lfih
```

### Install Dependencies

#### On Debian/Ubuntu:
```bash
sudo apt update && sudo apt install -y parallel curl
```

#### On Arch Linux:
```bash
sudo pacman -S parallel curl
```

#### On Fedora:
```bash
sudo dnf install parallel curl
```

### Make the Script Executable
```bash
chmod +x lfih.sh
```

### Prepare a Payload File
Create a file named `lfi.txt` with one payload per line, for example:
```bash
echo "/etc/passwd" > lfi.txt
echo "../../etc/passwd" >> lfi.txt
echo "../../../etc/passwd" >> lfi.txt
# Add more payloads as needed...
```

## Usage
Run the tool using the following syntax:
```bash
./lfih.sh -u "http://target.com/index.php?page="
```

### Options
- `-u <URL>`: (Required) The target URL with the vulnerable parameter.
  - Example: `http://target.com/index.php?page=`
- `-p <file>`: Custom payload file (default: `lfi.txt`).
- `-t <threads>`: Number of parallel requests (default: auto-detect CPU cores).
- `-x <proxy>`: Proxy to use (e.g., `http://127.0.0.1:8080`).
- `-A <user_agent>`: Custom User-Agent string (default is a Chrome UA).
- `-e`: Exit immediately upon finding a vulnerability.
- `-h`: Show the help menu.

### Example
```bash
./lfih.sh -u "http://target.com/index.php?page=" -p custom_payloads.txt -t 100 -x http://127.0.0.1:8080 -A "CustomUA/1.0" -e
```

## Output
The tool continuously updates a one-line status display such as:
```less
[+] Tested: 332/70465 (47%) - Time: 00:12:34
```
If a potential LFI is detected, the tool will print the payload to the console and log the details (including a response snippet) in `found.txt`.

## Disclaimer
Use this tool only for authorized security testing and bug bounty engagements. Unauthorized use is illegal and unethical.

## Author
**FIRE-HACKER**
