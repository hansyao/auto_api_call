#!/bin/bash

API_LIST_FILE='api_list.conf'
REDIRECT_URI='http://localhost:53682/'
THREADNUMBER=10

function account_env() {
	export CLIENT_ID1='c4a6ecb7-caa0-4bf1-aef3-43f599714f19'
	export CLIENT_SECRET1='egG__p87.AI_Ca42ElbPRqjH9BQtoY44Wz'
	export REFESH_TOKEN1='0.AXAAtbAvAbwPekW-76k9q4JoYLfspsSgyvFLrvND9ZlxTxlwAEo.AgABAAAAAAD--DLA3VO7QrddgJg7WevrAgDs_wQA9P_TUHOAQbOIYba-J7mLLfiYcrDAa2-RZbqB1cjGnd-biQum09jPFdfJkBQtCoK9snqI0R5mBarLCHCneRPy6gFuSx39tJNzfnXE8VngVofTXY39HTLiOsMBO3NSuZdM-kBJE6PbBij9JoQhFqzTUqWU0dZsN4_9_LFGiuyscg4M9hAsSBHvyoz_4YpKNi2MNwgk7T3G1arlovZe65i_wCG4JKGJ4-kXR5iQRydh7V1aImU_WswcKzLJnyxG_MyybwH3WiLmRyabJN-_4Z8AZFXW987pRW7iLtG5F7PjVqy6vugFCZp-YKp-NfGNPuLLeIYM4DBKbYkULdVu1Pq2Gq7GwKPLAswUJs15VHQP5hYilxr9hZANjH73oD4FRCIeWqlmnheOWBC2vlXOiZJ_ipcsR4kzlfU6V8CBPi-jFgR5sXFw9683lGeHrRGWj68773UlvdTpBMdsWsV-syyNi-nwGMMVb0WZYRnmgC51q_K5FT0dehvJxinNBf0-iqasq4iXDn1oJUKCjO7YfQEoFKO6tt5FEP5FQlS0Fqsm3m8m1HKj1HMho9MVL7c3E1jgGfEE6x7h6z0eW5CK3jCs6dgLeAkqhayVBkIiBY1C-JLDCXS1k7ABWSRtx6g7JqvOlPlmca5hiBDqLd0nTX6zBmhR-lLCfY8J-OrvTEBFLiDOHkHqeqbqaoZWNQuw2MZ4MPFbNT7rXnXup-TS2Fay6wdO4BTZ1JMq7wnh7ExAmGeWkY6Jq34EMWGrRz_f9jW8jMVBAR61_EYNL5xDxZ-q7rtXWPOvvgQU9Uy3pcKasrhrUqyh1lYUgvBFSSYxbsH-seh5eCV2hWTDztNDNIaB2EOJEAIpkEsq7jA_2qi9idxchfYieTT8I0LFwPgcyHByoZxo5Xpn_rfkgAlcWFkPuZWuoQ5VHeYZ8loeKav47KOivlAqfOt5dLx6VXkSdLfrAI78_zLHBUAa-tgHzm9hRMnuvgKFr7fizFqNSmNn1XzU2Y-f6Fb81jqxyqXUDdzxjHs5bekeLYkbEUOaIxHHMPflLLreN7KfPmkPAw2uuaP42nlvvilKh82_2tVMxCi2DHDZM3yHGg'

	export CLIENT_ID2='c4a6ecb7-caa0-4bf1-aef3-43f599714f19'
	export CLIENT_SECRET2='egG__p87.AI_Ca42ElbPRqjH9BQtoY44Wz'
	export REFESH_TOKEN2='0.AXAAtbAvAbwPekW-76k9q4JoYLfspsSgyvFLrvND9ZlxTxlwAEo.AgABAAAAAAD--DLA3VO7QrddgJg7WevrAgDs_wQA9P_TUHOAQbOIYba-J7mLLfiYcrDAa2-RZbqB1cjGnd-biQum09jPFdfJkBQtCoK9snqI0R5mBarLCHCneRPy6gFuSx39tJNzfnXE8VngVofTXY39HTLiOsMBO3NSuZdM-kBJE6PbBij9JoQhFqzTUqWU0dZsN4_9_LFGiuyscg4M9hAsSBHvyoz_4YpKNi2MNwgk7T3G1arlovZe65i_wCG4JKGJ4-kXR5iQRydh7V1aImU_WswcKzLJnyxG_MyybwH3WiLmRyabJN-_4Z8AZFXW987pRW7iLtG5F7PjVqy6vugFCZp-YKp-NfGNPuLLeIYM4DBKbYkULdVu1Pq2Gq7GwKPLAswUJs15VHQP5hYilxr9hZANjH73oD4FRCIeWqlmnheOWBC2vlXOiZJ_ipcsR4kzlfU6V8CBPi-jFgR5sXFw9683lGeHrRGWj68773UlvdTpBMdsWsV-syyNi-nwGMMVb0WZYRnmgC51q_K5FT0dehvJxinNBf0-iqasq4iXDn1oJUKCjO7YfQEoFKO6tt5FEP5FQlS0Fqsm3m8m1HKj1HMho9MVL7c3E1jgGfEE6x7h6z0eW5CK3jCs6dgLeAkqhayVBkIiBY1C-JLDCXS1k7ABWSRtx6g7JqvOlPlmca5hiBDqLd0nTX6zBmhR-lLCfY8J-OrvTEBFLiDOHkHqeqbqaoZWNQuw2MZ4MPFbNT7rXnXup-TS2Fay6wdO4BTZ1JMq7wnh7ExAmGeWkY6Jq34EMWGrRz_f9jW8jMVBAR61_EYNL5xDxZ-q7rtXWPOvvgQU9Uy3pcKasrhrUqyh1lYUgvBFSSYxbsH-seh5eCV2hWTDztNDNIaB2EOJEAIpkEsq7jA_2qi9idxchfYieTT8I0LFwPgcyHByoZxo5Xpn_rfkgAlcWFkPuZWuoQ5VHeYZ8loeKav47KOivlAqfOt5dLx6VXkSdLfrAI78_zLHBUAa-tgHzm9hRMnuvgKFr7fizFqNSmNn1XzU2Y-f6Fb81jqxyqXUDdzxjHs5bekeLYkbEUOaIxHHMPflLLreN7KfPmkPAw2uuaP42nlvvilKh82_2tVMxCi2DHDZM3yHGg'

	export CLIENT_ID3='c4a6ecb7-caa0-4bf1-aef3-43f599714f19'
	export CLIENT_SECRET3='egG__p87.AI_Ca42ElbPRqjH9BQtoY44Wz'
	export REFESH_TOKEN3='0.AXAAtbAvAbwPekW-76k9q4JoYLfspsSgyvFLrvND9ZlxTxlwAEo.AgABAAAAAAD--DLA3VO7QrddgJg7WevrAgDs_wQA9P_TUHOAQbOIYba-J7mLLfiYcrDAa2-RZbqB1cjGnd-biQum09jPFdfJkBQtCoK9snqI0R5mBarLCHCneRPy6gFuSx39tJNzfnXE8VngVofTXY39HTLiOsMBO3NSuZdM-kBJE6PbBij9JoQhFqzTUqWU0dZsN4_9_LFGiuyscg4M9hAsSBHvyoz_4YpKNi2MNwgk7T3G1arlovZe65i_wCG4JKGJ4-kXR5iQRydh7V1aImU_WswcKzLJnyxG_MyybwH3WiLmRyabJN-_4Z8AZFXW987pRW7iLtG5F7PjVqy6vugFCZp-YKp-NfGNPuLLeIYM4DBKbYkULdVu1Pq2Gq7GwKPLAswUJs15VHQP5hYilxr9hZANjH73oD4FRCIeWqlmnheOWBC2vlXOiZJ_ipcsR4kzlfU6V8CBPi-jFgR5sXFw9683lGeHrRGWj68773UlvdTpBMdsWsV-syyNi-nwGMMVb0WZYRnmgC51q_K5FT0dehvJxinNBf0-iqasq4iXDn1oJUKCjO7YfQEoFKO6tt5FEP5FQlS0Fqsm3m8m1HKj1HMho9MVL7c3E1jgGfEE6x7h6z0eW5CK3jCs6dgLeAkqhayVBkIiBY1C-JLDCXS1k7ABWSRtx6g7JqvOlPlmca5hiBDqLd0nTX6zBmhR-lLCfY8J-OrvTEBFLiDOHkHqeqbqaoZWNQuw2MZ4MPFbNT7rXnXup-TS2Fay6wdO4BTZ1JMq7wnh7ExAmGeWkY6Jq34EMWGrRz_f9jW8jMVBAR61_EYNL5xDxZ-q7rtXWPOvvgQU9Uy3pcKasrhrUqyh1lYUgvBFSSYxbsH-seh5eCV2hWTDztNDNIaB2EOJEAIpkEsq7jA_2qi9idxchfYieTT8I0LFwPgcyHByoZxo5Xpn_rfkgAlcWFkPuZWuoQ5VHeYZ8loeKav47KOivlAqfOt5dLx6VXkSdLfrAI78_zLHBUAa-tgHzm9hRMnuvgKFr7fizFqNSmNn1XzU2Y-f6Fb81jqxyqXUDdzxjHs5bekeLYkbEUOaIxHHMPflLLreN7KfPmkPAw2uuaP42nlvvilKh82_2tVMxCi2DHDZM3yHGg'
}

function get_client_info() {

	local CLIENT_ID="$(mktemp)"
	local CLIENT_SECRET="$(mktemp)"
	local REFESH_TOKEN="$(mktemp)"

	env | grep 'CLIENT_ID' | cut -d "=" -f2 >${CLIENT_ID}
	env | grep 'CLIENT_SECRET' | cut -d "=" -f2 >${CLIENT_SECRET}
	env | grep 'REFESH_TOKEN' | cut -d "=" -f2 >${REFESH_TOKEN}

	paste "${CLIENT_ID}"  "${CLIENT_SECRET}" "${REFESH_TOKEN}" | grep -v '^$'

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
	local CLIENT_ID=$2
	local CLIENT_SECRET=$3
	local REFESH_TOKEN=$4

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

	echo -e "\\nCLIENT_ID ${CLIENT_ID} 本轮API调用完成"

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
	account_env
	local CLIENT_LIST=$(get_client_info)
	if [[ -z ${CLIENT_LIST} ]]; then
		echo "API账号未设置, 结束任务"
		exit 0
	fi
	echo -e "${CLIENT_LIST}" | while read ACCOUNT && [[ -n "${ACCOUNT}" ]]
	do
		local START_TIME=$(date +%s)

		local API_LIST=$(get_api_random)
		local CLIENT_ID=$(echo -e "${ACCOUNT}" | awk '{print $1}')
		local CLIENT_SECRET=$(echo -e "${ACCOUNT}" | awk '{print $2}')
		local REFESH_TOKEN=$(echo -e "${ACCOUNT}" | awk '{print $3}')

		echo -e "CLIENT_ID ${CLIENT_ID} ----开始调用----"
		echo -e "======================================================================="
		api_call_batch "${API_LIST}" "${CLIENT_ID}" \
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
