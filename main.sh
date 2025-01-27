#!/bin/bash

# Tên file script: titan_autoinstall.sh
# Cách dùng: sudo bash titan_autoinstall.sh

set -e # Dừng script nếu có lỗi

# ---- Phần 1: Cài đặt Multipass ----
install_multipass() {
    echo "===== Kiểm tra cài đặt Snap ====="
    if ! command -v snap &> /dev/null; then
        echo "Snap chưa được cài đặt. Tiến hành cài đặt..."
        
        # Xác định distro Linux
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            case $ID in
                ubuntu|debian)
                    sudo apt update -qq
                    sudo apt install -y snapd
                    ;;
                fedora)
                    sudo dnf install -y snapd
                    ;;
                centos|rhel)
                    sudo yum install -y snapd
                    ;;
                *)
                    echo "Hệ điều hành không được hỗ trợ!"
                    exit 1
                    ;;
            esac
            
            # Kích hoạt snapd
            sudo systemctl enable --now snapd.socket
            sleep 5 # Đợi dịch vụ khởi động
        fi
    fi

    echo "===== Cài đặt Multipass ====="
    sudo snap install multipass

    echo "===== Kiểm tra phiên bản ====="
    multipass --version || {
        echo "Cài đặt Multipass thất bại!";
        exit 1;
    }
}

# ---- Phần 2: Cài đặt Titan Agent ----
install_titan() {
    echo "===== Tải Titan Agent ====="
    INSTALL_DIR="/opt/titanagent"
    ZIP_URL="https://pcdn.titannet.io/test4/bin/agent-linux.zip"
    
    # Tạo thư mục cài đặt
    sudo mkdir -p "$INSTALL_DIR"
    
    # Tải và giải nén
    if ! wget -q "$ZIP_URL" -O /tmp/agent-linux.zip; then
        echo "Lỗi tải file! Kiểm tra kết nối mạng."
        exit 1
    fi
    
    sudo unzip -q /tmp/agent-linux.zip -d "$INSTALL_DIR"
    sudo rm /tmp/agent-linux.zip

    # Nhập thông tin từ user
    read -p "Nhập Titan Key của bạn: " TITAN_KEY
    read -p "Nhập đường dẫn thư mục làm việc [mặc định: $INSTALL_DIR]: " WORK_DIR
    WORK_DIR=${WORK_DIR:-$INSTALL_DIR}

    # Chạy agent
    echo "===== Khởi chạy Titan Agent ====="
    cd "$INSTALL_DIR"
    sudo ./agent \
        --working-dir="$WORK_DIR" \
        --server-url="https://test4-api.titannet.io" \
        --key="$TITAN_KEY" &

    echo "✅ Cài đặt hoàn tất! Kiểm tra trạng thái: systemctl status titan-agent"
}

# ---- Thực thi chính ----
main() {
    # Kiểm tra quyền root
    if [ "$EUID" -ne 0 ]; then
        echo "Vui lòng chạy script với quyền sudo!"
        exit 1
    fi

    install_multipass
    install_titan
}

main
