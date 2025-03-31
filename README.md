# Docker SSH

このリポジトリは **SSH踏み台サーバ (nogpu)** と **CUDA対応 SSHサーバ (gpu)** の Docker イメージを提供します。

## イメージ一覧

| イメージ名                                               | 説明                     |
|---------------------------------------------------------|--------------------------|
| `ghcr.io/rellab/docker-ssh-nogpu:latest`                | 軽量SSH踏み台サーバ (multi-arch) |
| `ghcr.io/rellab/docker-ssh-gpu:<CUDA_VERSION>`         | CUDA環境付きSSHサーバ (amd64のみ) |

---

## 構成ファイル

- `Dockerfile-ssh` : SSH-only (nogpu) 用 Dockerfile
- `Dockerfile-cuda` : CUDA対応 (gpu) 用 Dockerfile
- `entrypoint.sh` : 共通エントリポイントスクリプト
- `Makefile` : イメージのビルド・push 用

---

## 環境変数

| 変数名                 | 説明                                                        | デフォルト |
|----------------------|------------------------------------------------------------|:--------:|
| SSH_USER            | 作成するSSHユーザ名                                          | sshuser |
| SSH_UID             | SSHユーザ UID                                               | 2000    |
| SSH_GROUP           | SSHグループ名                                                | sshgroup|
| SSH_GID             | SSHグループ GID                                              | 2000    |
| SSH_PASSWORD_ENABLED | パスワードを設定するか (`yes` / `no`)                           | no      |
| SSH_PASSWORD_VALUE  | 設定するパスワード (`SSH_PASSWORD_ENABLED=yes` の場合のみ有効) | (空)    |
| SSH_GRANT_SUDO      | sudo権限付与 (`yes` / `nopass` / `no`)                          | nopass  |
| SSH_PUBLIC_KEY      | 公開鍵 (authorized_keys に登録)                             | (必須)  |

---

## ビルド方法

### 1. GHCRログイン
```bash
export GITHUB_USER=<your-username>
export GITHUB_TOKEN=<your-ghcr-token>
make login
```

### 2. SSH-only イメージビルド・push
```bash
make build-nogpu
```

### 3. CUDA版イメージビルド・push
```bash
make build-gpu
```

### 4. 全てビルド・push
```bash
make build
```

### 5. キャッシュ削除
```bash
make clean
```

---

## docker run の例

SSH-only (nogpu) コンテナを直接起動する例：

```bash
docker run -d \
  -p 2222:22 \
  -e SSH_USER=myuser \
  -e SSH_PUBLIC_KEY="ssh-rsa AAAAB3..." \
  --name ssh \
  ghcr.io/rellab/docker-ssh-nogpu:latest
```

sudo実行時にパスワードを要求させたい場合：

```bash
docker run -d \
  -p 2222:22 \
  -e SSH_USER=myuser \
  -e SSH_PUBLIC_KEY="ssh-rsa AAAAB3..." \
  -e SSH_PASSWORD_ENABLED=yes \
  -e SSH_PASSWORD_VALUE=mysecret \
  -e SSH_GRANT_SUDO=yes \
  --name ssh \
  ghcr.io/rellab/docker-ssh-nogpu:latest
```

---

## docker-compose.yml の例

SSH踏み台サーバと RStudio サーバを同じネットワークで起動する例：

```yaml
version: "3.9"

services:
  ssh:
    image: ghcr.io/rellab/docker-ssh-nogpu:latest
    container_name: ssh
    environment:
      - SSH_USER=youruser
      - SSH_PUBLIC_KEY=ssh-rsa AAAA...
    ports:
      - "2222:22"
    networks:
      - internal

  rstudio:
    image: ghcr.io/rellab/docker-rstudio:latest
    container_name: rstudio-server
    environment:
      - RSTUDIO_PASSWORD=rstudio
    volumes:
      - ./work:/home/rstudio
    networks:
      - internal

networks:
  internal:
    driver: bridge
```

SSHトンネル接続例：

```bash
ssh -L 8787:rstudio-server:8787 youruser@your-server-ip -p 2222
```

ブラウザで `http://localhost:8787` にアクセスすれば、踏み台経由で RStudio Server に接続できます。

---

## CUDA版の利用について

**CUDA版 (gpu) イメージは amd64 プラットフォームのみ対応** しています。  
多くの場合、ssh踏み台用途では **nogpu版** をご利用ください。

---

## 注意

- ログインは常に公開鍵認証のみ
- rootログイン禁止
- 必要に応じて `SSH_GRANT_SUDO` で sudo権限付与
- パスワードログインは無効化されています

---

## ライセンス

MIT License

