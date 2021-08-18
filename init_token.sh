#/bin/bash

function init_rclone() {
	local RCLONE=`which rclone`
	
	if [[ -n $(echo -e "${RCLONE}" | grep "no rclone in") ]]; then
		curl https://rclone.org/install.sh | sudo bash
	fi
	local RCLONE=`which rclone`
	if [[ -n $(echo -e "${RCLONE}" | grep "no rclone in") ]]; then
		echo -e "rclone 安装失败, 请手动安装后再继续"
		return 1
	fi
	echo -e "rclone 已安装完成"
}

function init_refresh_token() {
	rclone authorize "onedrive" "${CLIENT_ID}" "${CLIENT_SECRET}" \
		| sed -n '/{/,/}/p' | sed '$d' \
		| jq -r '.refresh_token'
}

function main() {
	echo '开始检查并安装rclone'
	init_rclone
	if [[ $? -eq 1 ]]; then exit 0; fi

	echo '---按提示输入CLIENT_ID 和 CLIENT_SECRET后继续---'
	read -p 'CLIENT_ID: ' ${CLIENT_ID}
	read -p 'CLIENT_SECRET: ' ${CLIENT_SECRET}
	REFRESH_TOKEN=$(init_refresh_token)
	if [[ -z ${REFRESH_TOKEN} ]]; then
		echo "refresh_token 获取失败"
		exit 0
	fi
	echo -e "REFRESH_TOKEN: ${REFRESH_TOKEN}"
}

main
