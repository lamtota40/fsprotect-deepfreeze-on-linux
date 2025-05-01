#!/bin/bash

if (( $EUID != 0 )); then
    echo "Please run as root"
    echo "You can Try comand 'su root' or 'sudo -i' or 'sudo -'"
    exit 1
fi

FS_CONF="/etc/default/fsprotect"
HOOK_FILE="/etc/initramfs-tools/hooks/fsprotect"
CACHE_DIR="/fsprotect-cache"

check_status() {
    if dpkg -s fsprotect &>/dev/null; then
        if [[ -f $FS_CONF && $(grep -c '^FS_PROTECT_PARTITIONS=' $FS_CONF) -gt 0 ]]; then
            echo "Enabled"
        else
            echo "Installed, but Disabled"
        fi
    else
        echo "Not Installed"
    fi
}

install_fsprotect() {
    echo "=> Menginstal fsprotect..."
    apt update && apt install -y fsprotect
    echo "   fsprotect terinstal."
}

enable_fsprotect() {
    if ! dpkg -s fsprotect &>/dev/null; then
        echo "   fsprotect belum terinstal. Pilih menu Install dulu."
        return
    fi

    echo "=> Mengaktifkan fsprotect..."
    # buat cache di luar overlay
    mkdir -p "$CACHE_DIR"
    chmod 777 "$CACHE_DIR"

    # tulis konfigurasi
    cat <<EOF > "$FS_CONF"
FS_PROTECT_PARTITIONS="/"
FS_PROTECT_USE_TMPFS=no
FS_PROTECT_CACHEDIR="$CACHE_DIR"
EOF

    # regenerasi initramfs, paket hook bawaan akan jalan
    update-initramfs -u
    echo "   fsprotect berhasil di-enable. Silakan reboot."
}

disable_fsprotect() {
    echo "=> Menonaktifkan fsprotect..."
    [[ -f $FS_CONF ]] && rm -f "$FS_CONF"
    update-initramfs -u
    echo "   fsprotect dinonaktifkan. Silakan reboot."
}

uninstall_fsprotect() {
    echo "=> Menghapus fsprotect sepenuhnya..."
    # hapus paket
    apt remove --purge -y fsprotect
    # hapus direktori cache
    rm -rf "$CACHE_DIR"
    # hapus config jika ada
    [[ -f $FS_CONF ]] && rm -f "$FS_CONF"
    # hapus hook yang dibuat manual jika ada
    [[ -f $HOOK_FILE ]] && rm -f "$HOOK_FILE"
    # regenerasi initramfs
    update-initramfs -u
    echo "   fsprotect berhasil di-uninstall."
}

while true; do
    clear
    echo "========================="
    echo "    Menu FS PROTECT"
    echo " (Deepfreeze on Linux)"
    echo "========================="
    echo "Status: $(check_status)"
    echo ""
    echo "1) Install FS PROTECT"
    echo "2) Enable  FS PROTECT"
    echo "3) Disable FS PROTECT"
    echo "4) Uninstall FS PROTECT"
    echo "0) Exit"
    echo ""
    read -p "Pilihan Anda: " opt
    case $opt in
        1) install_fsprotect ;; 
        2) enable_fsprotect ;; 
        3) disable_fsprotect ;; 
        4) uninstall_fsprotect ;; 
        0) exit 0 ;; 
        *) echo "  Opsi tidak dikenal!" ;; 
    esac
    echo ""
    read -p "Tekan [Enter] untuk kembali ke menu..."
done
