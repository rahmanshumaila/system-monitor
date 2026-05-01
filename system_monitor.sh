#!/bin/bash

# COLORS
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Progress bar function
draw_bar() {
    local pct=$1
    local width=30
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    if   [ "$pct" -ge 85 ]; then color=$RED
    elif [ "$pct" -ge 60 ]; then color=$YELLOW
    else                         color=$GREEN
    fi
    printf "${color}["
    printf '%0.s█' $(seq 1 $filled)
    printf '%0.s░' $(seq 1 $empty)
    printf "] ${pct}%%${RESET}"
}

# Section header function
print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}══════════════════════════════════════${RESET}"
    echo -e "${CYAN}${BOLD}  $1${RESET}"
    echo -e "${CYAN}${BOLD}══════════════════════════════════════${RESET}"
}

# SECTION 1: GENERAL INFO
print_header "SYSTEM MONITOR"
echo -e "${BOLD}Date/Time :${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${BOLD}Hostname  :${RESET} $(hostname)"
echo -e "${BOLD}Kernel    :${RESET} $(uname -r)"
UPTIME_STR=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
echo -e "${BOLD}Uptime    :${RESET} up $UPTIME_STR"

# SECTION 2: CPU USAGE
print_header "CPU USAGE"
CPU_LINE=$(grep '^cpu ' /proc/stat)
CPU_IDLE=$(echo $CPU_LINE | awk '{print $5}')
CPU_TOTAL=$(echo $CPU_LINE | awk '{print $2+$3+$4+$5+$6+$7+$8}')
CPU_USED=$(( (CPU_TOTAL - CPU_IDLE) * 100 / CPU_TOTAL ))
echo -e "${BOLD}CPU Used  :${RESET} ${CPU_USED}%"
printf "           "
draw_bar $CPU_USED
echo ""
echo -e "${BOLD}CPU Cores :${RESET} $(nproc)"
LOAD=$(uptime | awk -F'load average:' '{print $2}')
echo -e "${BOLD}Load Avg  :${RESET}$LOAD"

# SECTION 3: RAM USAGE
print_header "RAM USAGE"
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
USED_RAM=$(free -m  | awk '/^Mem:/{print $3}')
FREE_RAM=$(free -m  | awk '/^Mem:/{print $4}')
AVAIL_RAM=$(free -m | awk '/^Mem:/{print $7}')
RAM_PCT=$(( USED_RAM * 100 / TOTAL_RAM ))
echo -e "${BOLD}Total RAM :${RESET} ${TOTAL_RAM} MB"
echo -e "${BOLD}Used      :${RESET} ${USED_RAM} MB"
echo -e "${BOLD}Free      :${RESET} ${FREE_RAM} MB"
echo -e "${BOLD}Available :${RESET} ${AVAIL_RAM} MB"
printf "${BOLD}Usage     :${RESET} "
draw_bar $RAM_PCT
echo ""
SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_USED=$(free -m | awk '/^Swap:/{print $3}')
    SWAP_PCT=$(( SWAP_USED * 100 / SWAP_TOTAL ))
    echo -e "${BOLD}Swap      :${RESET} ${SWAP_USED} MB / ${SWAP_TOTAL} MB"
else
    echo -e "${BOLD}Swap      :${RESET} No swap configured"
fi

# SECTION 4: DISK USAGE
print_header "DISK USAGE"
echo -e "${BOLD}Filesystem        Size   Used  Avail  Use%  Mounted${RESET}"
echo "--------------------------------------------------------------"
df -h | grep -v "tmpfs\|udev\|loop\|Filesystem" | while read -r fs size used avail pct mount; do
    pct_num=${pct//%/}
    printf "%-18s %-6s %-5s %-6s " "$fs" "$size" "$used" "$avail"
    if   [ "$pct_num" -ge 85 ]; then echo -en "${RED}${pct}${RESET}"
    elif [ "$pct_num" -ge 60 ]; then echo -en "${YELLOW}${pct}${RESET}"
    else                              echo -en "${GREEN}${pct}${RESET}"
    fi
    printf "    %s\n" "$mount"
done

# SECTION 5: TOP 10 PROCESSES
print_header "TOP 10 PROCESSES (by CPU)"
echo -e "${BOLD}USER       PID    %CPU  %MEM  COMMAND${RESET}"
echo "---------------------------------------------------"
ps aux --sort=-%cpu | awk 'NR>1 {printf "%-10s %-6s %-5s %-5s %s\n", $1, $2, $3, $4, $11}' | head -10

# SECTION 6: NETWORK
print_header "NETWORK"
echo -e "${BOLD}IP Address:${RESET} $(hostname -I | tr ' ' '\n' | head -5)"
OPEN_PORTS=$(ss -tuln | grep LISTEN | wc -l)
echo -e "${BOLD}Open Ports:${RESET} $OPEN_PORTS listening"

# DONE
echo ""
echo -e "${CYAN}${BOLD}══════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Done! — $(date '+%H:%M:%S')${RESET}"
echo -e "${CYAN}${BOLD}══════════════════════════════════════${RESET}"
echo ""
