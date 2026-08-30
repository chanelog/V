#!/bin/bash
# ============================================================
#   CHANELOG VPN SCRIPT - SHADOWSOCKS MENU
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SLINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ss_header() {
  clear
  local domain=$(get_domain)
  local count=$(count_ss)
  local xray_st
  systemctl is-active --quiet xray \
    && xray_st="${GREEN}● RUNNING${NC}" || xray_st="${RED}● STOPPED${NC}"

  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}            ⚡  SHADOWSOCKS WEBSOCKET MENU  ⚡${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Domain       ${NC}: ${WHITE}$domain${NC}"
  echo -e "  ${YELLOW}Status Xray  ${NC}: $xray_st"
  echo -e "  ${YELLOW}WS TLS       ${NC}: ${WHITE}443${NC}   Path: ${WHITE}/ss-ws${NC}"
  echo -e "  ${YELLOW}gRPC TLS     ${NC}: ${WHITE}443${NC}   Service: ${WHITE}ss-grpc${NC}"
  echo -e "  ${YELLOW}Method       ${NC}: ${WHITE}aes-128-gcm${NC}"
  echo -e "  ${YELLOW}Total Akun   ${NC}: ${WHITE}$count akun${NC}"
  echo -e "${CYAN}$LINE${NC}"
}

ss_menu() {
  ss_header
  echo ""
  echo -e "  ${WHITE}SHADOWSOCKS WS & gRPC — TLS${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[1]${NC}  Buat Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[2]${NC}  Info Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[3]${NC}  Detail Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${RED}[4]${NC}  Hapus Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[5]${NC}  Perpanjang Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${CYAN}[6]${NC}  List Semua Akun Shadowsocks"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[7]${NC}  Edit Limit Device/IP & Kuota"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${DIM}[0]${NC}  Kembali ke Menu Utama"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${WHITE}Pilih [0-7]${NC}: "
  read -r choice

  case "$choice" in
    1) do_create_ss ;;
    2) do_info_ss ;;
    3) do_detail_ss ;;
    4) do_delete_ss ;;
    5) do_renew_ss ;;
    6) do_list_ss ;;
    7) do_edit_limit_ss ;;
    0) bash $SCRIPT_DIR/menu.sh ;;
    *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}"; sleep 1; ss_menu ;;
  esac
}

do_create_ss() {
  ss_header
  echo ""
  echo -e "  ${WHITE}BUAT AKUN SHADOWSOCKS BARU${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Username     ${NC}: "; read -r username
  [[ -z "$username" ]] && { echo -e "  ${RED}[!] Username kosong!${NC}"; sleep 2; ss_menu; return; }
  grep -q "^$username|" "$DB_SS" 2>/dev/null && { echo -e "  ${RED}[!] Username sudah ada!${NC}"; sleep 2; ss_menu; return; }
  echo -ne "  ${YELLOW}Masa aktif (hari)${NC}: "; read -r days; days=${days:-30}
  [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}[!] Harus angka!${NC}"; sleep 2; ss_menu; return; }

  echo -ne "  ${YELLOW}Limit Device/IP${NC} [default: ${IP_LIMIT_DEFAULT:-2}, 0=unlimited]: "
  read -r ip_limit; ip_limit="${ip_limit:-${IP_LIMIT_DEFAULT:-2}}"
  [[ ! "$ip_limit" =~ ^[0-9]+$ ]] && ip_limit="${IP_LIMIT_DEFAULT:-2}"

  echo -ne "  ${YELLOW}Limit Kuota (GB)${NC} [default: $(fmt_quota "$QUOTA_DEFAULT_MB"), 0=unlimited]: "
  read -r quota_gb
  local quota_mb
  if [[ -z "$quota_gb" ]]; then quota_mb="${QUOTA_DEFAULT_MB:-0}"
  elif [[ "$quota_gb" =~ ^[0-9]+$ ]]; then quota_mb=$(( quota_gb * 1024 ))
  else quota_mb="${QUOTA_DEFAULT_MB:-0}"; fi

  local pass=$(create_ss "$username" "$days" "$ip_limit" "$quota_mb")
  local domain=$(get_domain)
  local exp=$(get_exp_date "$days")
  local link_ws=$(gen_ss_link "$username" "$pass" "$domain" "ws")
  local link_grpc=$(gen_ss_link "$username" "$pass" "$domain" "grpc")

  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}         ✓  AKUN SHADOWSOCKS BERHASIL DIBUAT${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Username        ${NC}: ${WHITE}$username${NC}"
  echo -e "  ${YELLOW}Password        ${NC}: ${WHITE}$pass${NC}"
  echo -e "  ${YELLOW}Method          ${NC}: ${WHITE}aes-128-gcm${NC}"
  echo -e "  ${YELLOW}Domain          ${NC}: ${WHITE}$domain${NC}"
  echo -e "  ${YELLOW}Dibuat          ${NC}: ${WHITE}$(date +"%Y-%m-%d")${NC}"
  echo -e "  ${YELLOW}Expired         ${NC}: ${WHITE}$exp${NC}"
  echo -e "  ${YELLOW}Masa Aktif      ${NC}: ${WHITE}$days hari${NC}"
  echo -e "  ${YELLOW}Limit Device/IP ${NC}: ${WHITE}$(fmt_limit "$ip_limit")${NC}"
  echo -e "  ${YELLOW}Limit Kuota     ${NC}: ${WHITE}$(fmt_quota "$quota_mb")${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}WS TLS     ${NC}: Host ${WHITE}$domain${NC}  Port ${WHITE}443${NC}  Path ${WHITE}/ss-ws${NC}  TLS ${GREEN}ON${NC}"
  echo -e "  ${WHITE}gRPC TLS   ${NC}: Host ${WHITE}$domain${NC}  Port ${WHITE}443${NC}  Service ${WHITE}ss-grpc${NC}  TLS ${GREEN}ON${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}Link WS:${NC}"
  echo -e "  ${GREEN}$link_ws${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}Link gRPC:${NC}"
  echo -e "  ${GREEN}$link_grpc${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  ss_menu
}

do_info_ss() {
  ss_header
  echo ""
  echo -e "  ${WHITE}INFO AKUN SHADOWSOCKS${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Username${NC}: "; read -r username
  local info=$(get_ss_info "$username")
  [[ -z "$info" ]] && { echo -e "  ${RED}[!] Akun tidak ditemukan!${NC}"; sleep 2; ss_menu; return; }

  local pass=$(echo "$info" | cut -d'|' -f2)
  local method=$(echo "$info" | cut -d'|' -f3)
  local exp=$(echo "$info"  | cut -d'|' -f4)
  local created=$(echo "$info" | cut -d'|' -f5)
  local ip_limit=$(echo "$info" | cut -d'|' -f6); ip_limit="${ip_limit:-${IP_LIMIT_DEFAULT:-2}}"
  local quota_mb=$(echo "$info" | cut -d'|' -f7); quota_mb="${quota_mb:-0}"
  local online=$(get_xray_user_online "$username")
  local used_mb=$(get_xray_user_traffic_mb "$username")
  local remaining=$(days_until_exp "$exp")
  local sc="${GREEN}"; local st="AKTIF"
  [[ $remaining -lt 0 ]] && { sc="${RED}";     st="EXPIRED"; }
  [[ $remaining -le 3 && $remaining -ge 0 ]] && { sc="${YELLOW}"; st="SEGERA EXPIRED"; }
  is_quota_disabled "ss" "$username" && { sc="${RED}"; st="SUSPENDED (kuota habis)"; }

  echo ""
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Username        ${NC}: ${WHITE}$username${NC}"
  echo -e "  ${YELLOW}Password        ${NC}: ${WHITE}$pass${NC}"
  echo -e "  ${YELLOW}Method          ${NC}: ${WHITE}$method${NC}"
  echo -e "  ${YELLOW}Dibuat          ${NC}: ${WHITE}$created${NC}"
  echo -e "  ${YELLOW}Expired         ${NC}: ${WHITE}$exp${NC}"
  echo -e "  ${YELLOW}Sisa            ${NC}: ${WHITE}$remaining hari${NC}"
  echo -e "  ${YELLOW}Status          ${NC}: ${sc}● $st${NC}"
  echo -e "  ${YELLOW}Device Aktif    ${NC}: ${WHITE}$online${NC} / ${WHITE}$(fmt_limit "$ip_limit")${NC}"
  echo -e "  ${YELLOW}Kuota Terpakai  ${NC}: ${WHITE}$(fmt_quota "$used_mb")${NC} / ${WHITE}$(fmt_quota "$quota_mb")${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  ss_menu
}

do_edit_limit_ss() {
  ss_header
  echo ""
  echo -e "  ${WHITE}EDIT LIMIT DEVICE/IP & KUOTA${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Username${NC}: "; read -r username
  local info=$(get_ss_info "$username")
  [[ -z "$info" ]] && { echo -e "  ${RED}[!] Akun tidak ditemukan!${NC}"; sleep 2; ss_menu; return; }

  local cur_ip=$(echo "$info" | cut -d'|' -f6); cur_ip="${cur_ip:-${IP_LIMIT_DEFAULT:-2}}"
  local cur_quota=$(echo "$info" | cut -d'|' -f7); cur_quota="${cur_quota:-0}"

  echo -ne "  ${YELLOW}Limit Device/IP baru${NC} [saat ini: $(fmt_limit "$cur_ip")]: "
  read -r new_ip; new_ip="${new_ip:-$cur_ip}"; [[ ! "$new_ip" =~ ^[0-9]+$ ]] && new_ip="$cur_ip"

  echo -ne "  ${YELLOW}Limit Kuota baru (GB)${NC} [saat ini: $(fmt_quota "$cur_quota")]: "
  read -r new_gb
  local new_quota
  if [[ -z "$new_gb" ]]; then new_quota="$cur_quota"
  elif [[ "$new_gb" =~ ^[0-9]+$ ]]; then new_quota=$(( new_gb * 1024 ))
  else new_quota="$cur_quota"; fi

  edit_ss_limits "$username" "$new_ip" "$new_quota"
  echo -e "  ${GREEN}[✓] Limit '$username' diperbarui: device/IP=$(fmt_limit "$new_ip"), kuota=$(fmt_quota "$new_quota")${NC}"
  sleep 2
  ss_menu
}

do_detail_ss() {
  ss_header
  echo ""
  echo -e "  ${WHITE}DETAIL AKUN SHADOWSOCKS${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${YELLOW}Username${NC}: "; read -r username
  local info=$(get_ss_info "$username")
  [[ -z "$info" ]] && { echo -e "  ${RED}[!] Akun tidak ditemukan!${NC}"; sleep 2; ss_menu; return; }

  local pass=$(echo "$info" | cut -d'|' -f2)
  local method=$(echo "$info" | cut -d'|' -f3)
  local exp=$(echo "$info"  | cut -d'|' -f4)
  local created=$(echo "$info" | cut -d'|' -f5)
  local domain=$(get_domain)
  local remaining=$(days_until_exp "$exp")
  local link_ws=$(gen_ss_link "$username" "$pass" "$domain" "ws")
  local link_grpc=$(gen_ss_link "$username" "$pass" "$domain" "grpc")

  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}            ◈  DETAIL AKUN SHADOWSOCKS  ◈${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Username   ${NC}: ${WHITE}$username${NC}"
  echo -e "  ${YELLOW}Password   ${NC}: ${WHITE}$pass${NC}"
  echo -e "  ${YELLOW}Method     ${NC}: ${WHITE}$method${NC}"
  echo -e "  ${YELLOW}Dibuat     ${NC}: ${WHITE}$created${NC}"
  echo -e "  ${YELLOW}Expired    ${NC}: ${WHITE}$exp${NC}"
  echo -e "  ${YELLOW}Sisa       ${NC}: ${WHITE}$remaining hari${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}WS TLS     ${NC}: Host ${WHITE}$domain${NC}  Port ${WHITE}443${NC}  Path ${WHITE}/ss-ws${NC}  TLS ${GREEN}ON${NC}"
  echo -e "  ${WHITE}gRPC TLS   ${NC}: Host ${WHITE}$domain${NC}  Port ${WHITE}443${NC}  Service ${WHITE}ss-grpc${NC}  TLS ${GREEN}ON${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}Link WS:${NC}"
  echo -e "  ${GREEN}$link_ws${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${WHITE}Link gRPC:${NC}"
  echo -e "  ${GREEN}$link_grpc${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  ss_menu
}

do_delete_ss() {
  ss_header
  echo ""
  echo -e "  ${RED}HAPUS AKUN SHADOWSOCKS${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  do_list_ss_simple
  echo ""
  echo -ne "  ${YELLOW}Username yang dihapus${NC}: "; read -r username
  [[ -z "$(get_ss_info "$username")" ]] && { echo -e "  ${RED}[!] Akun tidak ditemukan!${NC}"; sleep 2; ss_menu; return; }
  echo -ne "  ${RED}Konfirmasi hapus '$username'? [y/N]${NC}: "; read -r c
  [[ ! "$c" =~ ^[Yy]$ ]] && { echo -e "  ${YELLOW}Dibatalkan${NC}"; sleep 1; ss_menu; return; }
  delete_ss "$username"
  echo -e "  ${GREEN}[✓] Akun '$username' dihapus!${NC}"; sleep 2; ss_menu
}

do_renew_ss() {
  ss_header
  echo ""
  echo -e "  ${YELLOW}PERPANJANG AKUN SHADOWSOCKS${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  do_list_ss_simple
  echo ""
  echo -ne "  ${YELLOW}Username${NC}: "; read -r username
  local info=$(get_ss_info "$username")
  [[ -z "$info" ]] && { echo -e "  ${RED}[!] Akun tidak ditemukan!${NC}"; sleep 2; ss_menu; return; }
  local old_exp=$(echo "$info" | cut -d'|' -f4)
  echo -e "  ${YELLOW}Expired saat ini${NC}: ${WHITE}$old_exp${NC}"
  echo -ne "  ${YELLOW}Perpanjang (hari)${NC}: "; read -r days; days=${days:-30}
  renew_ss "$username" "$days"
  echo -e "  ${GREEN}[✓] Diperpanjang hingga ${WHITE}$(get_exp_date "$days")${NC}"; sleep 2; ss_menu
}

do_list_ss_simple() {
  local count=0
  printf "  ${CYAN}%-20s %-20s %-12s %-8s${NC}\n" "USERNAME" "PASSWORD" "EXPIRED" "LIMIT"
  echo -e "  ${CYAN}$LINE${NC}"
  while IFS='|' read -r user pass method exp created ip_limit quota_mb; do
    [[ -z "$user" ]] && continue
    local r=$(days_until_exp "$exp")
    local c="${WHITE}"
    [[ $r -lt 0 ]] && c="${RED}"
    [[ $r -le 3 && $r -ge 0 ]] && c="${YELLOW}"
    printf "  ${c}%-20s %-20s %-12s %-8s${NC}\n" "$user" "$pass" "$exp" "$(fmt_limit "$ip_limit")"
    ((count++))
  done < <(list_ss)
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Total${NC}: ${WHITE}$count akun${NC}"
}

do_list_ss() {
  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}            ◈  DAFTAR AKUN SHADOWSOCKS  ◈${NC}"
  echo -e "${CYAN}$LINE${NC}"
  echo ""
  do_list_ss_simple
  echo ""
  echo -ne "  ${DIM}Tekan Enter untuk kembali...${NC}"; read -r
  ss_menu
}

ss_menu
