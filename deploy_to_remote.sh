#!/bin/bash

function zip_file() {
	local ZIP_FILE=$1
	zip -r ${ZIP_FILE} ./ \
	-i "graph_api_app.sh" \
	-i "user_agent.txt" \
	-i ".profile"
}

function update_env() {

        sed -i s/^PLATFORM\=./PLATFORM\=3/g graph_api_app.sh

	echo -e "$(env | grep CLIENT_ID | awk '{print "export", $0}')" >> .profile
	echo -e "$(env | grep CLIENT_SECRET | awk '{print "export", $0}')" >> .profile
	echo -e "$(env | grep REFESH_TOKEN | awk '{print "export", $0}')" >> .profile
}

function remote_deploy() {
	local HOST_IP=$1
	local SERVER_PORT=$2
	local SRC=$3
	local USER_NAME=$4
	local AUTH=$5
	local SSH_KEY=$6
	local SERVER_PATH=$7

	if [[ ${AUTH} = 1 ]]; then
		local SSH_PWD_CMD="sshpass -p ${SSH_KEY}"
	elif [[ ${AUTH} -eq 2 ]]; then
		echo -e "${SSH_KEY}" >/tmp/rsa_key
		chmod 600 /tmp/rsa_key
		local SSH_KEY_CMD="-i /tmp/rsa_key"
	else
		echo "缺少认证方式"
	fi

	echo -e "开始发送打包文件到服务器"
	${SSH_PWD_CMD} scp -o "StrictHostKeyChecking no" ${SSH_KEY_CMD} \
		-P ${SERVER_PORT} ${SRC} ${USER_NAME}@${HOST_IP}:${SERVER_PATH}

}

function remote_exec() {
	local HOST_IP=$1
	local SERVER_PORT=$2
	local USER_NAME=$3
	local AUTH=$4
	local SSH_KEY=$5
	local REMOTE_CMD=$6

	if [[ ${AUTH} = 1 ]]; then
		local SSH_PWD_CMD="sshpass -p ${SSH_KEY}"
	elif [[ ${AUTH} -eq 2 ]]; then
		echo -e "${SSH_KEY}" >/tmp/rsa_key
		chmod 600 /tmp/rsa_key
		local SSH_KEY_CMD="-i /tmp/rsa_key"
	else
		echo "缺少认证方式"
	fi

	echo -e "远程发送执行命令到服务器"
	${SSH_PWD_CMD} ssh -o "StrictHostKeyChecking no" ${SSH_KEY_CMD} \
		${USER_NAME}@${HOST_IP} -p ${SERVER_PORT} "${REMOTE_CMD}"
	if [[ $? -eq 0 ]]; then
		echo -e "远程命令执行成功"
	else
		echo -e "远程命令执行失败"
	fi
}
update_env
ZIP_FILE='/tmp/tmp.zip'
zip_file ${ZIP_FILE} >/dev/null

HOST_IP=${REMOTE_IP} 
SERVER_PORT=${REMOTE_PORT}
USER_NAME=${REMOTE_USER_NAME}
PASSWORD=${REMOTE_PASSWORD}
SSH_KEY=${REMOTE_SSH_KEY}

SERVER_PATH='/tmp/'

if [[ -z ${PASSWORD} && -z ${SSH_KEY} ]]; then
	echo "缺少SSH密钥或者密码，退出任务"
	exit 1
elif [[ -n ${PASSWORD} ]]; then
	AUTH=1
	SSH_KEY="${PASSWORD}"
elif [[ -n ${SSH_KEY} ]]; then
	AUTH=2
fi

echo -e "推送源码到远程服务器"
remote_deploy ${HOST_IP} ${SERVER_PORT} ${ZIP_FILE} \
	${USER_NAME} ${AUTH} "${SSH_KEY}" "${SERVER_PATH}"

echo -e "开始远程解压缩"
REMOTE_CMD="unzip -u -o -d graph_api ${ZIP_FILE}"
remote_exec ${HOST_IP} ${SERVER_PORT} \
	${USER_NAME} ${AUTH} "${SSH_KEY}" "${REMOTE_CMD}"

echo -e "开始远程添加环境变量"
REMOTE_CMD='cat ~/.bashrc | grep graph_api; if [[ $? -eq 1 ]]; then echo -e "if [ -f ~/graph_api/.profile ]; then . ~/graph_api/.profile; fi" >> ~/.bashrc; fi; . ~/.bashrc'
remote_exec ${HOST_IP} ${SERVER_PORT} \
	${USER_NAME} ${AUTH} "${SSH_KEY}" "${REMOTE_CMD}"

echo -e "开始远程执行任务"
REMOTE_CMD='cd graph_api && ./graph_api_app.sh'
remote_exec ${HOST_IP} ${SERVER_PORT} \
	${USER_NAME} ${AUTH} "${SSH_KEY}" "${REMOTE_CMD}"