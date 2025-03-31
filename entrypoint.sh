#!/bin/bash
set -e

# ホームディレクトリをユーザ名から決定
SSH_HOME="/home/${SSH_USER}"

# グループ作成
if ! getent group "$SSH_GROUP" > /dev/null; then
  groupadd -g "$SSH_GID" "$SSH_GROUP"
fi

# ユーザ作成
if ! id "$SSH_USER" > /dev/null 2>&1; then
  useradd -m -d "$SSH_HOME" -u "$SSH_UID" -g "$SSH_GID" -s /bin/bash "$SSH_USER"

  # パスワード設定 (必要な場合のみ)
  if [ "$SSH_PASSWORD_ENABLED" = "yes" ] && [ -n "$SSH_PASSWORD_VALUE" ]; then
    echo "$SSH_USER:$(echo "$SSH_PASSWORD_VALUE" | openssl passwd -6 -stdin)" | chpasswd
  fi

  # sudo設定
  case "$SSH_GRANT_SUDO" in
    yes)
      echo "$SSH_USER ALL=(ALL) ALL" >> /etc/sudoers.d/$SSH_USER
      ;;
    nopass)
      echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$SSH_USER
      ;;
    no)
      # 何もしない
      ;;
    *)
      echo "Invalid SSH_GRANT_SUDO value: $SSH_GRANT_SUDO"
      exit 1
      ;;
  esac

  # 公開鍵登録
  mkdir -p "$SSH_HOME/.ssh"
  echo "$SSH_PUBLIC_KEY" > "$SSH_HOME/.ssh/authorized_keys"
  chown -R "$SSH_USER:$SSH_GROUP" "$SSH_HOME"
  chmod 700 "$SSH_HOME/.ssh"
  chmod 600 "$SSH_HOME/.ssh/authorized_keys"
fi

# sshd_config セキュリティ設定
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "AllowUsers $SSH_USER" >> /etc/ssh/sshd_config

# SSHサーバ起動
exec /usr/sbin/sshd -D
