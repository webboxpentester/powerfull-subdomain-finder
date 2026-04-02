#for_settings_up 10101010
# Universal Installer for Feroxbuster & Subfinder
# Works on Termux (Android) and Linux (Ubuntu/Debian/Arch/Fedora/CentOS)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Banner
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Feroxbuster & Subfinder Universal Installer              ║"
echo "║          Works on Termux & Linux                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect environment
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] || command -v termux-info >/dev/null 2>&1; then
    IS_TERMUX=true
    echo -e "${GREEN}[✓] Termux environment detected${NC}"
else
    echo -e "${GREEN}[✓] Linux environment detected${NC}"
fi

# Function to detect package manager (Linux only)
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install system dependencies
install_system_deps() {
    echo -e "\n${YELLOW}[*] Installing system dependencies...${NC}"
    
    if [ "$IS_TERMUX" = true ]; then
        # Termux dependencies
        pkg update -y
        pkg install -y python git wget curl unzip
        pkg install -y rust cargo binutils
        pkg install -y build-essential
        
    else
        # Linux dependencies
        PKG_MANAGER=$(detect_package_manager)
        
        case $PKG_MANAGER in
            apt)
                sudo apt update -y
                sudo apt install -y python3 python3-pip git wget curl unzip
                sudo apt install -y build-essential
                # Install Rust for Feroxbuster
                if ! command -v cargo >/dev/null 2>&1; then
                    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                    source "$HOME/.cargo/env"
                fi
                ;;
            dnf|yum)
                sudo $PKG_MANAGER install -y python3 python3-pip git wget curl unzip
                sudo $PKG_MANAGER groupinstall -y "Development Tools"
                if ! command -v cargo >/dev/null 2>&1; then
                    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                    source "$HOME/.cargo/env"
                fi
                ;;
            pacman)
                sudo pacman -Syu --noconfirm
                sudo pacman -S --noconfirm python python-pip git wget curl unzip
                sudo pacman -S --noconfirm base-devel rust cargo
                ;;
            zypper)
                sudo zypper refresh
                sudo zypper install -y python3 python3-pip git wget curl unzip
                sudo zypper install -y -t pattern devel_basis
                if ! command -v cargo >/dev/null 2>&1; then
                    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                    source "$HOME/.cargo/env"
                fi
                ;;
            *)
                echo -e "${RED}[!] Unknown package manager. Please install manually:${NC}"
                echo "  - Python 3, Git, Wget, Curl, Unzip"
                echo "  - Rust and Cargo"
                exit 1
                ;;
        esac
    fi
    
    echo -e "${GREEN}[+] System dependencies installed${NC}"
}

# Function to install Feroxbuster
install_feroxbuster() {
    echo -e "\n${YELLOW}[*] Installing Feroxbuster...${NC}"
    
    if command -v feroxbuster >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Feroxbuster already installed: $(feroxbuster --version 2>/dev/null | head -n1)${NC}"
        return 0
    fi
    
    if [ "$IS_TERMUX" = true ]; then
        # Termux installation via cargo
        echo -e "${CYAN}[*] Installing via Cargo...${NC}"
        
        # Update rust
        rustup update 2>/dev/null || true
        
        # Install feroxbuster
        cargo install feroxbuster
        
        # Add to PATH if needed
        if ! grep -q "export PATH=\$PATH:\$HOME/.cargo/bin" ~/.bashrc 2>/dev/null; then
            echo 'export PATH=$PATH:$HOME/.cargo/bin' >> ~/.bashrc
            echo -e "${GREEN}[+] Added Cargo bin to PATH${NC}"
        fi
        
        export PATH=$PATH:$HOME/.cargo/bin
        
    else
        # Linux installation via cargo
        echo -e "${CYAN}[*] Installing via Cargo...${NC}"
        
        # Ensure Rust is installed
        if ! command -v cargo >/dev/null 2>&1; then
            echo -e "${YELLOW}[*] Installing Rust...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        
        # Install feroxbuster
        cargo install feroxbuster
        
        # Add to PATH if needed
        SHELL_CONFIG="$HOME/.bashrc"
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        fi
        
        if ! grep -q "export PATH=\$PATH:\$HOME/.cargo/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo 'export PATH=$PATH:$HOME/.cargo/bin' >> "$SHELL_CONFIG"
            echo -e "${GREEN}[+] Added Cargo bin to PATH in $SHELL_CONFIG${NC}"
        fi
        
        export PATH=$PATH:$HOME/.cargo/bin
    fi
    
    # Verify installation
    if command -v feroxbuster >/dev/null 2>&1; then
        echo -e "${GREEN}[+] Feroxbuster installed successfully!${NC}"
        feroxbuster --version 2>/dev/null | head -n1 || echo "Version: latest"
    else
        echo -e "${RED}[!] Feroxbuster installation failed${NC}"
        return 1
    fi
}

# Function to install Subfinder
install_subfinder() {
    echo -e "\n${YELLOW}[*] Installing Subfinder...${NC}"
    
    if command -v subfinder >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Subfinder already installed: $(subfinder -version 2>/dev/null | head -n1)${NC}"
        return 0
    fi
    
    if [ "$IS_TERMUX" = true ]; then
        # Termux installation - download pre-compiled binary
        echo -e "${CYAN}[*] Downloading Subfinder binary...${NC}"
        
        # Create subfinder directory
        mkdir -p "$HOME/subfinder"
        cd "$HOME/subfinder"
        
        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            aarch64)
                SUBFINDER_URL="https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_arm64.zip"
                ;;
            armv7l|armv8l)
                SUBFINDER_URL="https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_armv7.zip"
                ;;
            *)
                SUBFINDER_URL="https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_arm64.zip"
                ;;
        esac
        
        # Download and extract
        wget -q --show-progress "$SUBFINDER_URL" -O subfinder.zip
        unzip -o subfinder.zip
        chmod +x subfinder
        
        # Move to bin directory
        if [ -d "$HOME/../usr/bin" ]; then
            cp subfinder "$HOME/../usr/bin/"
        elif [ -d "$HOME/bin" ]; then
            cp subfinder "$HOME/bin/"
        fi
        
        # Add alias
        if ! grep -q "alias subfinder=" ~/.bashrc 2>/dev/null; then
            echo "alias subfinder='~/subfinder/subfinder'" >> ~/.bashrc
        fi
        
        cd "$HOME"
        
    else
        # Linux installation via Go
        echo -e "${CYAN}[*] Installing via Go...${NC}"
        
        # Install Go if not present
        if ! command -v go >/dev/null 2>&1; then
            echo -e "${YELLOW}[*] Installing Go...${NC}"
            
            PKG_MANAGER=$(detect_package_manager)
            case $PKG_MANAGER in
                apt)
                    sudo apt install -y golang
                    ;;
                dnf|yum)
                    sudo $PKG_MANAGER install -y golang
                    ;;
                pacman)
                    sudo pacman -S --noconfirm go
                    ;;
                zypper)
                    sudo zypper install -y go
                    ;;
                *)
                    # Download Go binary
                    wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
                    sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
                    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                    export PATH=$PATH:/usr/local/go/bin
                    ;;
            esac
        fi
        
        # Setup Go environment
        export GOPATH=$HOME/go
        export PATH=$PATH:$GOPATH/bin
        
        # Install subfinder
        go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        
        # Add to PATH if needed
        SHELL_CONFIG="$HOME/.bashrc"
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        fi
        
        if ! grep -q "export PATH=\$PATH:\$HOME/go/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo 'export PATH=$PATH:$HOME/go/bin' >> "$SHELL_CONFIG"
            echo -e "${GREEN}[+] Added Go bin to PATH in $SHELL_CONFIG${NC}"
        fi
        
        export PATH=$PATH:$HOME/go/bin
    fi
    
    # Verify installation
    if command -v subfinder >/dev/null 2>&1 || [ -f "$HOME/subfinder/subfinder" ]; then
        echo -e "${GREEN}[+] Subfinder installed successfully!${NC}"
        if command -v subfinder >/dev/null 2>&1; then
            subfinder -version 2>/dev/null | head -n1 || echo "Version: latest"
        fi
    else
        echo -e "${RED}[!] Subfinder installation failed${NC}"
        return 1
    fi
}

# Function to install SecLists wordlists (optional)
install_seclists() {
    echo -e "\n${YELLOW}[?] Install SecLists wordlists? (y/n): ${NC}"
    read -r install_seclists
    
    if [[ $install_seclists == "y" || $install_seclists == "Y" ]]; then
        echo -e "${CYAN}[*] Installing SecLists wordlists...${NC}"
        
        if [ "$IS_TERMUX" = true ]; then
            WORDLIST_DIR="/sdcard/x/sec/SecLists"
        else
            WORDLIST_DIR="$HOME/wordlists/SecLists"
        fi
        
        mkdir -p "$WORDLIST_DIR/Discovery/DNS"
        mkdir -p "$WORDLIST_DIR/Discovery/Web-Content"
        
        # Download DNS wordlist
        echo -e "${YELLOW}[*] Downloading DNS wordlist...${NC}"
        wget -q --show-progress -O "$WORDLIST_DIR/Discovery/DNS/subdomains-top1million-5000.txt" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
        
        # Download common wordlist
        echo -e "${YELLOW}[*] Downloading common wordlist...${NC}"
        wget -q --show-progress -O "$WORDLIST_DIR/Discovery/Web-Content/common.txt" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
        
        # Download raft medium directories
        echo -e "${YELLOW}[*] Downloading raft medium directories...${NC}"
        wget -q --show-progress -O "$WORDLIST_DIR/Discovery/Web-Content/raft-medium-directories.txt" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-medium-directories.txt"
        
        echo -e "${GREEN}[+] SecLists wordlists installed to: $WORDLIST_DIR${NC}"
    fi
}

# Function to verify installations
verify_installations() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    INSTALLATION SUMMARY                        ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    
    # Check Feroxbuster
    if command -v feroxbuster >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Feroxbuster: Installed${NC}"
        feroxbuster --version 2>/dev/null | head -n1 | sed 's/^/  /'
    else
        echo -e "${RED}✗ Feroxbuster: Not installed${NC}"
    fi
    
    # Check Subfinder
    if command -v subfinder >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Subfinder: Installed${NC}"
        subfinder -version 2>/dev/null | head -n1 | sed 's/^/  /'
    elif [ -f "$HOME/subfinder/subfinder" ]; then
        echo -e "${GREEN}✓ Subfinder: Installed (in ~/subfinder)${NC}"
    else
        echo -e "${RED}✗ Subfinder: Not installed${NC}"
    fi
    
    # Check PATH
    echo -e "\n${YELLOW}[*] PATH Configuration:${NC}"
    if echo "$PATH" | grep -q ".cargo/bin"; then
        echo -e "  ${GREEN}✓ Cargo bin in PATH${NC}"
    else
        echo -e "  ${YELLOW}⚠ Cargo bin not in PATH (restart terminal to fix)${NC}"
    fi
    
    if echo "$PATH" | grep -q "go/bin"; then
        echo -e "  ${GREEN}✓ Go bin in PATH${NC}"
    else
        echo -e "  ${YELLOW}⚠ Go bin not in PATH (restart terminal to fix)${NC}"
    fi
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# Function to create test script
create_test_script() {
    cat > "$HOME/test_tools.sh" << 'EOF'
#!/bin/bash
# Test script for Feroxbuster and Subfinder

echo "Testing Feroxbuster..."
feroxbuster --version 2>/dev/null || echo "Feroxbuster not found"

echo -e "\nTesting Subfinder..."
subfinder -version 2>/dev/null || echo "Subfinder not found"

echo -e "\nIf tools are not found, restart your terminal or run:"
echo "source ~/.bashrc"
EOF
    
    chmod +x "$HOME/test_tools.sh"
    echo -e "${GREEN}[+] Test script created: ~/test_tools.sh${NC}"
}

# Main installation process
main() {
    # Install system dependencies
    install_system_deps
    
    # Install Feroxbuster
    install_feroxbuster
    
    # Install Subfinder
    install_subfinder
    
    # Optional: Install SecLists
    install_seclists
    
    # Verify installations
    verify_installations
    
    # Create test script
    create_test_script
    
    # Final instructions
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    INSTALLATION COMPLETE!                       ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    echo -e "\n${YELLOW}[*] To use the tools:${NC}"
    echo -e "  1. Restart your terminal or run: ${CYAN}source ~/.bashrc${NC}"
    echo -e "  2. Test installation: ${CYAN}~/test_tools.sh${NC}"
    echo -e "  3. Run feroxbuster: ${CYAN}feroxbuster -u https://example.com -w wordlist.txt${NC}"
    echo -e "  4. Run subfinder: ${CYAN}subfinder -d example.com${NC}"
    
    if [ "$IS_TERMUX" = true ]; then
        echo -e "\n${YELLOW}[*] Termux Notes:${NC}"
        echo -e "  • If feroxbuster not found, run: ${CYAN}export PATH=\$PATH:\$HOME/.cargo/bin${NC}"
        echo -e "  • Make sure you have storage permission: ${CYAN}termux-setup-storage${NC}"
    fi
    
    echo -e "\n${GREEN}Happy Hacking! 🔥${NC}"
}

# Run main with error handling
trap 'echo -e "\n${RED}[!] Installation interrupted${NC}"; exit 1' INT TERM
main "$@"