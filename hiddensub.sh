#for_settings_up 10101010
# Universal Subdomain Scanner - Linux & Termux Compatible
# Advanced subdomain enumeration with subfinder + feroxbuster

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Detect environment
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] || command -v termux-info >/dev/null 2>&1; then
    IS_TERMUX=true
    echo -e "${CYAN}[*] Termux environment detected${NC}"
else
    echo -e "${CYAN}[*] Linux environment detected${NC}"
fi

# Set paths based on environment
if [ "$IS_TERMUX" = true ]; then
    # Termux paths
    BASE_DIR="/storage/emulated/0/x"
    RESULT_DIR="${BASE_DIR}/result"
    SEC_DIR="/sdcard/x/sec"
    DNS_WORDLIST="${SEC_DIR}/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    COMMON_WORDLIST="${SEC_DIR}/SecLists/Discovery/Web-Content/common.txt"
    SUBFINDER_DIR="$HOME/subfinder"
else
    # Linux paths
    BASE_DIR="$HOME/recon"
    RESULT_DIR="${BASE_DIR}/subdomain_results"
    SEC_DIR="$HOME/wordlists"
    DNS_WORDLIST="${SEC_DIR}/SecLists/Discovery/DNS/subdomains-top1million-5000.txt"
    COMMON_WORDLIST="${SEC_DIR}/SecLists/Discovery/Web-Content/common.txt"
    SUBFINDER_DIR="$HOME/subfinder"
fi

# Create directories
mkdir -p "$RESULT_DIR"
mkdir -p "$SEC_DIR"

# Banner
clear
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         ADVANCED SUBDOMAIN SCANNER v2.0                      ║"
echo "║      Subfinder + Feroxbuster - Universal Edition            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check and install dependencies
check_dependencies() {
    echo -e "${YELLOW}[*] Checking dependencies...${NC}"
    
    MISSING=0
    
    # Check subfinder
    if ! command -v subfinder >/dev/null 2>&1 && [ ! -f "$SUBFINDER_DIR/subfinder" ]; then
        echo -e "${RED}[!] Subfinder not found${NC}"
        MISSING=1
    fi
    
    # Check feroxbuster
    if ! command -v feroxbuster >/dev/null 2>&1; then
        echo -e "${RED}[!] Feroxbuster not found${NC}"
        MISSING=1
    fi
    
    # Check wordlists
    if [ ! -f "$DNS_WORDLIST" ]; then
        echo -e "${YELLOW}[!] DNS wordlist not found${NC}"
        MISSING=2
    fi
    
    if [ ! -f "$COMMON_WORDLIST" ]; then
        echo -e "${YELLOW}[!] Common wordlist not found${NC}"
        MISSING=2
    fi
    
    if [ $MISSING -eq 1 ]; then
        echo -e "${YELLOW}[?] Install missing tools? (y/n): ${NC}"
        read -r install_choice
        if [[ $install_choice == "y" || $install_choice == "Y" ]]; then
            install_tools
        else
            echo -e "${RED}[!] Cannot continue without required tools${NC}"
            exit 1
        fi
    elif [ $MISSING -eq 2 ]; then
        echo -e "${YELLOW}[?] Download missing wordlists? (y/n): ${NC}"
        read -r download_choice
        if [[ $download_choice == "y" || $download_choice == "Y" ]]; then
            download_wordlists
        else
            echo -e "${YELLOW}[!] Continuing with available wordlists...${NC}"
        fi
    else
        echo -e "${GREEN}[+] All dependencies satisfied${NC}"
    fi
}

# Function to install tools
install_tools() {
    echo -e "${CYAN}[*] Installing required tools...${NC}"
    
    # Install feroxbuster
    if ! command -v feroxbuster >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Installing feroxbuster...${NC}"
        if command -v cargo >/dev/null 2>&1; then
            cargo install feroxbuster
        else
            echo -e "${YELLOW}[*] Installing Rust...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
            cargo install feroxbuster
        fi
        echo -e "${GREEN}[+] Feroxbuster installed${NC}"
    fi
    
    # Install subfinder
    if ! command -v subfinder >/dev/null 2>&1 && [ ! -f "$SUBFINDER_DIR/subfinder" ]; then
        echo -e "${YELLOW}[*] Installing subfinder...${NC}"
        if [ "$IS_TERMUX" = true ]; then
            mkdir -p "$SUBFINDER_DIR"
            cd "$SUBFINDER_DIR"
            if [ "$(uname -m)" = "aarch64" ]; then
                wget https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_arm64.zip
                unzip -o subfinder_linux_arm64.zip
            else
                wget https://github.com/projectdiscovery/subfinder/releases/latest/download/subfinder_linux_armv7.zip
                unzip -o subfinder_linux_armv7.zip
            fi
            chmod +x subfinder
            cd "$HOME"
        else
            if ! command -v go >/dev/null 2>&1; then
                if command -v apt >/dev/null 2>&1; then
                    sudo apt install -y golang
                elif command -v dnf >/dev/null 2>&1; then
                    sudo dnf install -y golang
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum install -y golang
                elif command -v pacman >/dev/null 2>&1; then
                    sudo pacman -S --noconfirm go
                fi
            fi
            go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
            export PATH=$PATH:$HOME/go/bin
        fi
        echo -e "${GREEN}[+] Subfinder installed${NC}"
    fi
}

# Function to download wordlists
download_wordlists() {
    echo -e "${CYAN}[*] Downloading SecLists wordlists...${NC}"
    mkdir -p "$SEC_DIR/SecLists/Discovery/DNS"
    mkdir -p "$SEC_DIR/SecLists/Discovery/Web-Content"
    
    if [ ! -f "$DNS_WORDLIST" ]; then
        echo -e "${YELLOW}[*] Downloading DNS wordlist...${NC}"
        wget -q --show-progress -O "$DNS_WORDLIST" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
    fi
    
    if [ ! -f "$COMMON_WORDLIST" ]; then
        echo -e "${YELLOW}[*] Downloading common wordlist...${NC}"
        wget -q --show-progress -O "$COMMON_WORDLIST" \
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
    fi
    
    echo -e "${GREEN}[+] Wordlists downloaded${NC}"
}

# Function to run subfinder
run_subfinder() {
    echo -e "\n${GREEN}[+] Running subfinder on $target_url...${NC}"
    
    if command -v subfinder >/dev/null 2>&1; then
        subfinder -d "$target_url" -o "$RESULT_DIR/subfinder_$timestamp.txt" 2>/dev/null
    elif [ -f "$SUBFINDER_DIR/subfinder" ]; then
        "$SUBFINDER_DIR/subfinder" -d "$target_url" -o "$RESULT_DIR/subfinder_$timestamp.txt" 2>/dev/null
    else
        echo -e "${RED}[!] Subfinder execution failed${NC}"
        return 1
    fi
    
    # Save and sort subfinder subdomains
    if [ -f "$RESULT_DIR/subfinder_$timestamp.txt" ]; then
        cat "$RESULT_DIR/subfinder_$timestamp.txt" | sort -u > "$RESULT_DIR/subfinder_subdomains_$timestamp.txt"
        local count=$(wc -l < "$RESULT_DIR/subfinder_subdomains_$timestamp.txt")
        echo -e "${GREEN}[+] Subfinder found: $count subdomains${NC}"
    else
        echo -e "${YELLOW}[!] No subdomains found by subfinder${NC}"
        touch "$RESULT_DIR/subfinder_subdomains_$timestamp.txt"
    fi
}

# Function to run feroxbuster for additional subdomains
run_ferox_subdomains() {
    echo -e "\n${YELLOW}[+] Running feroxbuster for additional subdomains...${NC}"
    
    # Check if DNS wordlist exists
    if [ ! -f "$DNS_WORDLIST" ]; then
        echo -e "${RED}[!] DNS wordlist not found: $DNS_WORDLIST${NC}"
        echo -e "${YELLOW}[*] Using limited subdomain list...${NC}"
        # Create a basic subdomain list
        echo -e "www\nmail\nftp\nadmin\ndev\ntest\napi\nblog" > "$RESULT_DIR/basic_subdomains.txt"
        DNS_WORDLIST="$RESULT_DIR/basic_subdomains.txt"
    fi
    
    # Create temporary file for feroxbuster targets
    > "$RESULT_DIR/temp_ferox_list_$timestamp.txt"
    > "$RESULT_DIR/ferox_found_subdomains_$timestamp.txt"
    
    # Limit to first 1000 subdomains to avoid excessive scanning
    local total_subs=$(wc -l < "$DNS_WORDLIST" 2>/dev/null || echo "0")
    if [ "$total_subs" -gt 1000 ]; then
        echo -e "${CYAN}[*] Limiting to first 1000 subdomains (out of $total_subs)${NC}"
        head -n 1000 "$DNS_WORDLIST" > "$RESULT_DIR/limited_dns_list.txt"
        DNS_WORDLIST="$RESULT_DIR/limited_dns_list.txt"
    fi
    
    # Check each subdomain
    local count=0
    while read -r sub; do
        [ -z "$sub" ] && continue
        if ! grep -q "^$sub$" "$RESULT_DIR/subfinder_subdomains_$timestamp.txt" 2>/dev/null; then
            echo "$sub.$target_url" >> "$RESULT_DIR/temp_ferox_list_$timestamp.txt"
            count=$((count + 1))
        fi
    done < "$DNS_WORDLIST"
    
    echo -e "${CYAN}[*] Testing $count new potential subdomains...${NC}"
    
    # Run feroxbuster if there are targets
    if [ -f "$RESULT_DIR/temp_ferox_list_$timestamp.txt" ] && [ -s "$RESULT_DIR/temp_ferox_list_$timestamp.txt" ]; then
        echo -e "${CYAN}[*] Running feroxbuster for subdomain enumeration...${NC}"
        feroxbuster -u "https://FUZZ.$target_url" \
            -w "$RESULT_DIR/temp_ferox_list_$timestamp.txt" \
            --dont-filter \
            --silent \
            --timeout 5 \
            -o "$RESULT_DIR/ferox_subdomains_$timestamp.txt" \
            2>/dev/null || true
        
        # Extract found subdomains
        if [ -f "$RESULT_DIR/ferox_subdomains_$timestamp.txt" ]; then
            cat "$RESULT_DIR/ferox_subdomains_$timestamp.txt" | \
                grep -Eo 'https?://[^/]+' | \
                sed 's|https\?://||' | \
                sort -u >> "$RESULT_DIR/ferox_found_subdomains_$timestamp.txt"
        fi
        
        local found=$(wc -l < "$RESULT_DIR/ferox_found_subdomains_$timestamp.txt" 2>/dev/null || echo "0")
        echo -e "${GREEN}[+] Feroxbuster found: $found new subdomains${NC}"
    else
        echo -e "${YELLOW}[!] No new subdomains to test${NC}"
    fi
}

# Function to merge subdomains
merge_subdomains() {
    echo -e "\n${BLUE}[+] Merging all unique subdomains...${NC}"
    cat "$RESULT_DIR/subfinder_subdomains_$timestamp.txt" \
        "$RESULT_DIR/ferox_found_subdomains_$timestamp.txt" 2>/dev/null | \
        sort -u > "$RESULT_DIR/all_subdomains_final_$timestamp.txt"
    
    local total=$(wc -l < "$RESULT_DIR/all_subdomains_final_$timestamp.txt")
    echo -e "${GREEN}[+] Total unique subdomains: $total${NC}"
}

# Function to scan for hidden paths
scan_hidden_paths() {
    echo -e "\n${RED}[+] Running feroxbuster on ALL subdomains to find hidden URLs...${NC}"
    
    # Check if common wordlist exists
    if [ ! -f "$COMMON_WORDLIST" ]; then
        echo -e "${YELLOW}[!] Common wordlist not found, using basic wordlist${NC}"
        echo -e "admin\nlogin\napi\ntest\ndev\nbackup\nconfig\nwp-admin" > "$RESULT_DIR/basic_common.txt"
        COMMON_WORDLIST="$RESULT_DIR/basic_common.txt"
    fi
    
    local total_subs=$(wc -l < "$RESULT_DIR/all_subdomains_final_$timestamp.txt")
    local current=0
    
    while read -r subdomain; do
        if [ -n "$subdomain" ]; then
            current=$((current + 1))
            echo -e "\n${CYAN}[*] ($current/$total_subs) Scanning: $subdomain${NC}"
            
            # HTTP scan
            echo -e "${YELLOW}[*] HTTP scan${NC}"
            feroxbuster -u "http://$subdomain" \
                -w "$COMMON_WORDLIST" \
                --dont-filter \
                --silent \
                --timeout 5 \
                -o "$RESULT_DIR/hidden_http_${subdomain}_$timestamp.txt" \
                2>/dev/null || true
            
            # HTTPS scan
            echo -e "${YELLOW}[*] HTTPS scan${NC}"
            feroxbuster -u "https://$subdomain" \
                -w "$COMMON_WORDLIST" \
                --dont-filter \
                --silent \
                --timeout 5 \
                -o "$RESULT_DIR/hidden_https_${subdomain}_$timestamp.txt" \
                2>/dev/null || true
        fi
    done < "$RESULT_DIR/all_subdomains_final_$timestamp.txt"
}

# Function to generate summary
generate_summary() {
    echo -e "\n${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    SCAN COMPLETED                              ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Target: $target_url${NC}"
    echo -e "${CYAN}Timestamp: $timestamp${NC}"
    echo -e "${CYAN}Results directory: $RESULT_DIR${NC}"
    echo ""
    echo -e "${GREEN}[+] Statistics:${NC}"
    
    local subfinder_count=$(wc -l < "$RESULT_DIR/subfinder_subdomains_$timestamp.txt" 2>/dev/null || echo "0")
    local ferox_count=$(wc -l < "$RESULT_DIR/ferox_found_subdomains_$timestamp.txt" 2>/dev/null || echo "0")
    local total_count=$(wc -l < "$RESULT_DIR/all_subdomains_final_$timestamp.txt" 2>/dev/null || echo "0")
    
    echo -e "  • Subfinder found: $subfinder_count"
    echo -e "  • Feroxbuster found new: $ferox_count"
    echo -e "  • Total unique subdomains: $total_count"
    
    echo ""
    echo -e "${GREEN}[+] Output files:${NC}"
    echo -e "  • Subfinder results: subfinder_$timestamp.txt"
    echo -e "  • All subdomains: all_subdomains_final_$timestamp.txt"
    echo -e "  • Hidden paths: hidden_http_*_$timestamp.txt and hidden_https_*_$timestamp.txt"
    
    # Show sample of found subdomains
    if [ "$total_count" -gt 0 ]; then
        echo ""
        echo -e "${GREEN}[+] Sample subdomains found:${NC}"
        head -10 "$RESULT_DIR/all_subdomains_final_$timestamp.txt" | while read -r sub; do
            echo -e "  • $sub"
        done
        if [ "$total_count" -gt 10 ]; then
            echo -e "  • ... and $((total_count - 10)) more"
        fi
    fi
    
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}[*] Cleaning up temporary files...${NC}"
    rm -f "$RESULT_DIR/temp_ferox_list_$timestamp.txt" 2>/dev/null
    rm -f "$RESULT_DIR/limited_dns_list.txt" 2>/dev/null
    rm -f "$RESULT_DIR/basic_subdomains.txt" 2>/dev/null
    rm -f "$RESULT_DIR/basic_common.txt" 2>/dev/null
    echo -e "${GREEN}[+] Cleanup complete${NC}"
}

# Main execution
main() {
    # Get target URL
    echo "----------------------------------------"
    echo "Please input the URL (example: example.com)"
    echo "----------------------------------------"
    read -r target_url
    
    if [ -z "$target_url" ]; then
        echo -e "${RED}[!] No URL provided!${NC}"
        exit 1
    fi
    
    # Clean URL
    target_url=$(echo "$target_url" | sed 's|^https\?://||' | sed 's|/.*$||')
    echo -e "${GREEN}[*] Target: $target_url${NC}"
    
    # Timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Check dependencies
    check_dependencies
    
    # Run scans
    run_subfinder
    run_ferox_subdomains
    merge_subdomains
    
    # Ask if user wants to scan for hidden paths
    echo -e "\n${YELLOW}[?] Scan all subdomains for hidden paths? (y/n): ${NC}"
    read -r scan_hidden
    if [[ $scan_hidden == "y" || $scan_hidden == "Y" ]]; then
        scan_hidden_paths
    fi
    
    # Generate summary
    generate_summary
    
    # Cleanup
    cleanup
    
    cd "$HOME" || true
    echo -e "\n${GREEN}Done!${NC}"
}

# Run with error handling
trap 'echo -e "\n${RED}[!] Script interrupted${NC}"; cleanup; exit 1' INT TERM
main "$@"