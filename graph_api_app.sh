#!/bin/bash

API_LIST_FILE='api_list.conf'
REDIRECT_URI='http://localhost:53682/'
THREADNUMBER=10

function account_env() {
	export CLIENT_ID1=
	export CLIENT_SECRET1=
	export REFESH_TOKEN1=

	export CLIENT_ID2=
	export CLIENT_SECRET2=
	export REFESH_TOKEN2=

	export CLIENT_ID3=
	export CLIENT_SECRET3=
	export REFESH_TOKEN3=
}

function get_client_info() {

	local CLIENT_NAME="$(mktemp)"
	local CLIENT_ID="$(mktemp)"
	local CLIENT_SECRET="$(mktemp)"
	local REFESH_TOKEN="$(mktemp)"

	env | grep 'CLIENT_ID' | cut -d "=" -f1 >${CLIENT_NAME}
	env | grep 'CLIENT_ID' | cut -d "=" -f2 >${CLIENT_ID}
	env | grep 'CLIENT_SECRET' | cut -d "=" -f2 >${CLIENT_SECRET}
	env | grep 'REFESH_TOKEN' | cut -d "=" -f2 >${REFESH_TOKEN}

	paste "${CLIENT_NAME}" "${CLIENT_ID}"  "${CLIENT_SECRET}" "${REFESH_TOKEN}" | grep -v '^$'

	rm -f ${CLIENT_NAME}
	rm -f ${CLIENT_ID}
	rm -f ${CLIENT_SECRET}
	rm -f ${REFESH_TOKEN}
}

function multi_process_kill() {
	local PROCESS_NAME=$1

	local i=0
	while :
	do
		# echo -e "正在退出 当前线程数" $(ps -ef | grep $(basename $0) | grep -v "grep" | wc -l)
		if [[ $(ps -ef | grep ${PROCESS_NAME} | grep -v grep | wc -l) -le 6 ]]; then
			if [[ $[i] -le 5 ]]; then
				sleep 1
				let i++
				continue
			fi
			break
		fi
		sleep 1
	done
}

function update_access_token() {
	local CLIENT_ID=$1
	local CLIENT_SECRET=$2
	local REFESH_TOKEN=$3
	local TOKEN="$(mktemp)"

	local REFESH_TOKEN="${REFESH_TOKEN}"	
	local GRANT_TYPE='refresh_token'
	local TOKEN_URL='https://login.microsoftonline.com/common/oauth2/v2.0/token'
	curl -s \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "grant_type=${GRANT_TYPE}" \
		-d "refresh_token=${REFESH_TOKEN}" \
		-d "client_id=${CLIENT_ID}" \
		-d "client_secret=${CLIENT_SECRET}" \
		-d "redirect_uri=${REDIRECT_URI}" \
		${TOKEN_URL} | jq -r >  ${TOKEN}
	
	cat ${TOKEN} | jq -r '.access_token'
	rm -f ${TOKEN}
}

function api_call() {
	local API=$1
	local ACCESS_TOKEN=$2

	local STATUS=$(curl -s -i \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer ${ACCESS_TOKEN}" \
		-w "%{http_code}" \
		-o /dev/null \
		${API})

	if [[ $[STATUS] -eq 200 ]]; then
		local RE=$(echo -e "API调用成功：	${API}")
		echo -e "${RE}"
		echo -e "${RE}" >>${RESULTS_FILE}
	else
		local RE=$(echo -e "API调用失败:	${API}")
		echo -e "${RE}"
		echo -e "${RE}" >>${RESULTS_FILE}
	fi
}

function api_call_batch() {
	local API_LIST=$1
	local CLIENT_NAME=$2
	local CLIENT_ID=$3
	local CLIENT_SECRET=$4
	local REFESH_TOKEN=$5

	local ACCESS_TOKEN=$(update_access_token \
		"${CLIENT_ID}" "${CLIENT_SECRET}" "${REFESH_TOKEN}")

	# 线程数透传
	[ -e /tmp/fd1 ] || mkfifo /tmp/fd1
	exec 3<>/tmp/fd1
	rm -rf /tmp/fd1
	for ((i=0; i<$[THREADNUMBER]; i++))
	do
		echo >&3
	done
	unset i

	echo -e "${API_LIST}" | while read LINE && [[ -n "${LINE}" ]]
	do
		read -u3
		api_call "${LINE}" "${ACCESS_TOKEN}"  && echo >&3 &
	done
	
	multi_process_kill  "$(basename $0)"

	echo -e "\\n${CLIENT_NAME} CLIENT_ID ${CLIENT_ID} 本轮API调用完成"

	exec 3<&-
	exec 3>&-

	unset LINE
}

function get_api_random() {
	local API_LIST=$(cat "${API_LIST_FILE}")
	local TOTAL_API_COUNT=$(echo -e "${API_LIST}" | wc -l)
	
	local NUM=$((RANDOM % $[TOTAL_API_COUNT] + 1))
	
	for ((i=1; i<=$[NUM]; i++))
	do
		local LINE=$((RANDOM % $[TOTAL_API_COUNT] + 1))	
		echo -e "${API_LIST}" | sed -n "$[LINE]P"
	done
	unset i
}

function update_cron() {
	local H=$1
	local M=$2

	# Github Actions自动任务
	local GITHUB_ACTION=.github/workflows/auto_ms_api.yml
	local CRON="- cron: '${M} ${H} * * *'"
	sed -i s/\-\ cron".*/${CRON}"/ ${GITHUB_ACTION}
}

function main() {
	RESULTS_FILE="$(mktemp)"
	# account_env
	local CLIENT_LIST=$(get_client_info)
	echo -e "测试令牌"
	echo -e "${CLIENT_LIST}"
	if [[ -z ${CLIENT_LIST} ]]; then
		echo "API账号未设置, 结束任务"
		exit 0
	fi
	echo -e "${CLIENT_LIST}" | while read ACCOUNT && [[ -n "${ACCOUNT}" ]]
	do
		local START_TIME=$(date +%s)

		local API_LIST=$(get_api_random)
		local CLIENT_NAME=$(echo -e "${ACCOUNT}" | awk '{print $1}')
		local CLIENT_ID=$(echo -e "${ACCOUNT}" | awk '{print $2}')
		local CLIENT_SECRET=$(echo -e "${ACCOUNT}" | awk '{print $3}')
		local REFESH_TOKEN=$(echo -e "${ACCOUNT}" | awk '{print $4}')

		echo -e "CLIENT_ID ${CLIENT_ID} ----开始调用----"
		echo -e "======================================================================="
		api_call_batch "${API_LIST}" "${CLIENT_NAME}" "${CLIENT_ID}" \
			"${CLIENT_SECRET}" "${REFESH_TOKEN}"
		local API_COUNT=$(echo -e "${API_LIST}" | sort | uniq | wc -l)
		local COUNT=$(echo -e "${API_LIST}" | wc -l)

		local RESULTS=$(cat ${RESULTS_FILE})
		local SUCCESS_COUNT=$(echo -e "${RESULTS}" | grep 'API调用成功' | wc -l)
		local FAILED_COUNT=$(echo -e "${RESULTS}" | grep 'API调用失败' | wc -l)

		rm -f ${RESULTS_FILE}

		local STOP_TIME=$(date +%s)
		local DURATION=$(($[STOP_TIME] - $[START_TIME]))

		echo -e "CLIENT_ID ${CLIENT_ID} 本轮调用API:${API_COUNT}个, 耗时${DURATION}秒 \
	(合计调用:${COUNT}个次; 成功:${SUCCESS_COUNT}次; 失败:${FAILED_COUNT}次)\\n"
	done

	local UPCOMMING_SCHEDULED=$(($(date +%s) + ($RANDOM % 3600 + 600)))
	local H=$[$(date -d @$[UPCOMMING_SCHEDULED] +%k)]
	local M=$[$(date -d @$[UPCOMMING_SCHEDULED] +%M)]
	update_cron $H $M

	echo -e "\\n下一轮调用时间 $(date -d @$[UPCOMMING_SCHEDULED]) 已计划"
}

# account_env
# get_client_info
main
