#!/bin/bash
# ============================================================
#   CHANELOG VPN SCRIPT - BOT TELEGRAM & LIMIT AKUN (MENU UTAMA)
#   Pengaturan notifikasi Telegram + default limit device/IP
#   + default limit kuota utk semua protokol (SSH-WS & Xray)
# ============================================================

SCRIPT_DIR="/etc/vpn-script"
source "$SCRIPT_DIR/lib.sh"

LINE="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

tg_header() {
  clear
  echo -e "${CYAN}$LINE${NC}"
  echo -e "${WHITE}      🤖  BOT TELEGRAM & LIMIT AKUN (PRO)  🤖${NC}"
  echo -e "${CYAN}$LINE${NC}"
  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    echo -e "  ${YELLOW}Bot Telegram      ${NC}: ${GREEN}● AKTIF${NC}"
    echo -e "  ${YELLOW}Chat ID           ${NC}: ${WHITE}$TELEGRAM_CHAT_ID${NC}"
  else
    echo -e "  ${YELLOW}Bot Telegram      ${NC}: ${DIM}● belum diaktifkan${NC}"
  fi
  echo -e "  ${YELLOW}Notif Akun Baru   ${NC}: $([[ "${TG_NOTIFY_CREATE:-1}" == "1" ]] && echo "${GREEN}ON${NC}" || echo "${RED}OFF${NC}")"
  echo -e "  ${YELLOW}Notif Akun Hapus  ${NC}: $([[ "${TG_NOTIFY_DELETE:-1}" == "1" ]] && echo "${GREEN}ON${NC}" || echo "${RED}OFF${NC}")"
  echo -e "  ${YELLOW}Notif Limit Habis ${NC}: $([[ "${TG_NOTIFY_LIMIT:-1}" == "1" ]] && echo "${GREEN}ON${NC}" || echo "${RED}OFF${NC}")"
  echo -e "${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Default Limit Device/IP (SSH)  ${NC}: ${WHITE}$(fmt_limit "$SESSION_LIMIT_DEFAULT")${NC}"
  echo -e "  ${YELLOW}Default Limit Device/IP (Xray) ${NC}: ${WHITE}$(fmt_limit "$IP_LIMIT_DEFAULT")${NC}"
  echo -e "  ${YELLOW}Default Limit Kuota (semua)    ${NC}: ${WHITE}$(fmt_quota "$QUOTA_DEFAULT_MB")${NC}"
  echo -e "  ${YELLOW}Default Durasi Trial           ${NC}: ${WHITE}${TRIAL_HOURS_DEFAULT:-1} jam${NC}"
  echo -e "${CYAN}$LINE${NC}"
}

tg_menu() {
  tg_header
  echo ""
  echo -e "  ${GREEN}[1]${NC}  Setup / Ubah Bot Token & Chat ID"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[2]${NC}  Test Kirim Notifikasi"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[3]${NC}  Ubah Default Limit Device/IP (SSH & Xray)"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[4]${NC}  Ubah Default Limit Kuota"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}[5]${NC}  Ubah Default Durasi Trial (jam)"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${PURPLE}[6]${NC}  Toggle Notifikasi (Akun Baru / Hapus / Limit)"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${RED}[7]${NC}  Matikan Bot Telegram"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${DIM}[0]${NC}  Kembali ke Menu Utama"
  echo -e "  ${CYAN}$LINE${NC}"
  echo ""
  echo -ne "  ${WHITE}Pilih [0-7]${NC}: "
  read -r choice

  case "$choice" in
    1) do_setup_bot ;;
    2) do_test_notify ;;
    3) do_edit_limit_default ;;
    4) do_edit_quota_default ;;
    5) do_edit_trial_default ;;
    6) do_toggle_notify ;;
    7) do_disable_bot ;;
    0) bash "$SCRIPT_DIR/menu.sh" ;;
    *) echo -e "  ${RED}[!] Pilihan tidak valid${NC}"; sleep 1; tg_menu ;;
  esac
}

do_setup_bot() {
  tg_header
  echo ""
  echo -e "  ${WHITE}SETUP BOT TELEGRAM${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${DIM}1. Chat @BotFather di Telegram -> /newbot -> ikuti instruksi -> dapat TOKEN${NC}"
  echo -e "  ${DIM}2. Chat @userinfobot -> catat 'Id' kamu -> itu CHAT ID${NC}"
  echo ""
  echo -ne "  ${YELLOW}Bot Token${NC} [Enter = biarkan '${TELEGRAM_BOT_TOKEN:-kosong}']: "
  read -r bot_token
  bot_token="${bot_token:-$TELEGRAM_BOT_TOKEN}"
  echo -ne "  ${YELLOW}Chat ID${NC}  [Enter = biarkan '${TELEGRAM_CHAT_ID:-kosong}']: "
  read -r chat_id
  chat_id="${chat_id:-$TELEGRAM_CHAT_ID}"

  TELEGRAM_BOT_TOKEN="$bot_token"
  TELEGRAM_CHAT_ID="$chat_id"
  save_pro_config

  echo ""
  if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
    echo -ne "  ${CYAN}[*]${NC} Test kirim notifikasi... "
    if tg_notify "✅ <b>Setup Berhasil</b>

Bot Telegram utk domain <code>$(get_domain)</code> sudah aktif."; then
      echo -e "${GREEN}terkirim, cek Telegram kamu.${NC}"
    else
      echo -e "${RED}GAGAL${NC} -- cek lagi Bot Token/Chat ID-nya, mungkin salah."
    fi
  else
    echo -e "  ${YELLOW}[!] Bot Telegram dimatikan (token/chat id kosong).${NC}"
  fi
  echo -ne "  ${DIM}Tekan Enter...${NC}"; read -r
  tg_menu
}

do_test_notify() {
  tg_header
  if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
    echo -e "  ${RED}[!] Bot Telegram belum di-setup!${NC}"; sleep 2; tg_menu; return
  fi
  echo -ne "  ${CYAN}[*]${NC} Mengirim test notifikasi... "
  if tg_notify "🔔 <b>Test Notifikasi</b>

Domain: <code>$(get_domain)</code>
Waktu: <code>$(date +"%Y-%m-%d %H:%M:%S")</code>"; then
    echo -e "${GREEN}terkirim!${NC}"
  else
    echo -e "${RED}gagal terkirim.${NC}"
  fi
  echo -ne "  ${DIM}Tekan Enter...${NC}"; read -r
  tg_menu
}

do_edit_limit_default() {
  tg_header
  echo ""
  echo -e "  ${WHITE}DEFAULT LIMIT DEVICE/IP${NC} ${DIM}(0 = unlimited, dipakai kalau saat buat akun dikosongkan)${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -ne "  ${YELLOW}SSH / SSH-WS${NC} [saat ini: ${SESSION_LIMIT_DEFAULT:-2}]: "
  read -r s; s="${s:-$SESSION_LIMIT_DEFAULT}"; [[ "$s" =~ ^[0-9]+$ ]] || s="$SESSION_LIMIT_DEFAULT"
  echo -ne "  ${YELLOW}Xray (VMess/VLess/Trojan/SS)${NC} [saat ini: ${IP_LIMIT_DEFAULT:-2}]: "
  read -r x; x="${x:-$IP_LIMIT_DEFAULT}"; [[ "$x" =~ ^[0-9]+$ ]] || x="$IP_LIMIT_DEFAULT"

  SESSION_LIMIT_DEFAULT="$s"
  IP_LIMIT_DEFAULT="$x"
  save_pro_config
  echo -e "  ${GREEN}[✓] Default limit device/IP diperbarui.${NC}"; sleep 2; tg_menu
}

do_edit_quota_default() {
  tg_header
  echo ""
  echo -e "  ${WHITE}DEFAULT LIMIT KUOTA${NC} ${DIM}(berlaku semua protokol, 0 = unlimited)${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Saat ini${NC}: ${WHITE}$(fmt_quota "$QUOTA_DEFAULT_MB")${NC}"
  echo -ne "  ${YELLOW}Kuota baru dalam GB${NC} [0 = unlimited]: "
  read -r gb
  [[ "$gb" =~ ^[0-9]+$ ]] || { echo -e "  ${RED}[!] Harus angka!${NC}"; sleep 2; tg_menu; return; }
  QUOTA_DEFAULT_MB=$(( gb * 1024 ))
  save_pro_config
  echo -e "  ${GREEN}[✓] Default limit kuota diperbarui ke $(fmt_quota "$QUOTA_DEFAULT_MB").${NC}"; sleep 2; tg_menu
}

do_edit_trial_default() {
  tg_header
  echo ""
  echo -e "  ${WHITE}DEFAULT DURASI TRIAL${NC} ${DIM}(dalam jam, dipakai kalau saat buat akun dikosongkan)${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${YELLOW}Saat ini${NC}: ${WHITE}${TRIAL_HOURS_DEFAULT:-1} jam${NC}"
  echo -ne "  ${YELLOW}Durasi trial baru (jam)${NC}: "
  read -r h
  [[ "$h" =~ ^[0-9]+$ ]] || { echo -e "  ${RED}[!] Harus angka!${NC}"; sleep 2; tg_menu; return; }
  [[ "$h" -eq 0 ]] && h=1
  TRIAL_HOURS_DEFAULT="$h"
  save_pro_config
  echo -e "  ${GREEN}[✓] Default durasi trial diperbarui ke ${h} jam.${NC}"; sleep 2; tg_menu
}

do_toggle_notify() {
  tg_header
  echo ""
  echo -e "  ${WHITE}TOGGLE NOTIFIKASI${NC}"
  echo -e "  ${CYAN}$LINE${NC}"
  echo -e "  ${GREEN}[1]${NC} Notif Akun Baru   : $([[ "${TG_NOTIFY_CREATE:-1}" == "1" ]] && echo ON || echo OFF)"
  echo -e "  ${GREEN}[2]${NC} Notif Akun Hapus  : $([[ "${TG_NOTIFY_DELETE:-1}" == "1" ]] && echo ON || echo OFF)"
  echo -e "  ${GREEN}[3]${NC} Notif Limit Habis : $([[ "${TG_NOTIFY_LIMIT:-1}" == "1" ]] && echo ON || echo OFF)"
  echo -e "  ${DIM}[0]${NC} Kembali"
  echo ""
  echo -ne "  ${WHITE}Toggle mana [0-3]${NC}: "
  read -r c
  case "$c" in
    1) [[ "$TG_NOTIFY_CREATE" == "1" ]] && TG_NOTIFY_CREATE=0 || TG_NOTIFY_CREATE=1 ;;
    2) [[ "$TG_NOTIFY_DELETE" == "1" ]] && TG_NOTIFY_DELETE=0 || TG_NOTIFY_DELETE=1 ;;
    3) [[ "$TG_NOTIFY_LIMIT" == "1" ]] && TG_NOTIFY_LIMIT=0 || TG_NOTIFY_LIMIT=1 ;;
    0) tg_menu; return ;;
    *) echo -e "  ${RED}[!] Tidak valid${NC}"; sleep 1; do_toggle_notify; return ;;
  esac
  save_pro_config
  do_toggle_notify
}

do_disable_bot() {
  tg_header
  echo -ne "  ${RED}Yakin matikan Bot Telegram? [y/N]${NC}: "; read -r c
  [[ ! "$c" =~ ^[Yy]$ ]] && { echo -e "  ${YELLOW}Dibatalkan${NC}"; sleep 1; tg_menu; return; }
  TELEGRAM_BOT_TOKEN=""
  TELEGRAM_CHAT_ID=""
  save_pro_config
  echo -e "  ${GREEN}[✓] Bot Telegram dimatikan.${NC}"; sleep 2; tg_menu
}

tg_menu
