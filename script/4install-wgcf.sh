#!/usr/bin/env bash
set -e

BLUE="\033[34m"
ORANGE="\033[38;5;208m"
RESET="\033[0m"

REPO="ArchiveNetwork/wgcf-cli"
ASSET="wgcf-cli-linux-64.tar.zstd"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"

echo -e "${ORANGE}== 开始安装 wgcf ==${RESET}"

echo -e "${BLUE}==> 创建目录 wgcf${RESET}"
mkdir -p wgcf
cd wgcf

echo -e "${BLUE}==> 下载最新正式版 wgcf-cli${RESET}"
wget -q "${DOWNLOAD_URL}"

echo -e "${BLUE}==> 解压文件${RESET}"
tar -I zstd -xvf "${ASSET}"

echo -e "${BLUE}==> 清理无用文件${RESET}"
rm -f "${ASSET}" LICENSE README.md

echo -e "${BLUE}==> 设置执行权限${RESET}"
chmod 755 wgcf-cli

echo -e "${BLUE}==> 检查版本${RESET}"
./wgcf-cli version

echo -e "${BLUE}==> 注册 Cloudflare WARP 账户${RESET}"
./wgcf-cli register

echo -e "${BLUE}==> 生成 Xray 配置${RESET}"
./wgcf-cli generate --xray

echo -e "${ORANGE}== 安装完成 ==${RESET}"
echo -e "${BLUE}生成文件：wgcf-account.toml、wgcf-profile.conf、wgcf-profile.json${RESET}"
