#!/bin/bash

function timestamp() {
	if [ $1 -eq 1 ]; then
		echo -e $(date -u +%s)
	elif [ $1 -eq 2 ]; then
		echo -e $(date -u +%F)
	else
		echo -e $(date -u "+%F %H:%M:%S")
	fi
}

function get_client_info() {

	local CLIENT_NAME="$(mktemp)"
	local CLIENT_ID="$(mktemp)"
	local CLIENT_SECRET="$(mktemp)"
	local REFESH_TOKEN="$(mktemp)"

	env | grep 'CLIENT_ID' | sort | uniq | cut -d "=" -f1 >${CLIENT_NAME}
	env | grep 'CLIENT_ID' | sort | uniq | cut -d "=" -f2 >${CLIENT_ID}
	env | grep 'CLIENT_SECRET' | sort | uniq | cut -d "=" -f2 >${CLIENT_SECRET}
	env | grep 'REFESH_TOKEN' |sort | uniq | cut -d "=" -f2 >${REFESH_TOKEN}

	paste "${CLIENT_NAME}" "${CLIENT_ID}"  "${CLIENT_SECRET}" "${REFESH_TOKEN}" | grep -v '^$'

	rm -f ${CLIENT_NAME}
	rm -f ${CLIENT_ID}
	rm -f ${CLIENT_SECRET}
	rm -f ${REFESH_TOKEN}
}

function env_var() {
	local CLIENT_LIST=$(get_client_info)
	if [[ -z ${CLIENT_LIST} ]]; then
		echo "API账号未设置, 结束任务"
		exit 0
	fi
	echo -e "${CLIENT_LIST}" | while read ACCOUNT && [[ -n "${ACCOUNT}" ]]
	do
		# 微软环境变量
		local NAME=$(echo -e "${ACCOUNT}" | awk '{print $1}' | sed s/"CLIENT_ID"//g)
		local CLIENT_ID=$(echo -e "${ACCOUNT}" | awk '{print $2}')
		local CLIENT_SECRET=$(echo -e "${ACCOUNT}" | awk '{print $3}')
		local REFESH_TOKEN=$(echo -e "${ACCOUNT}" | awk '{print $4}')
		

		
		echo -n "{\"Key\":\"CLIENT_ID${NAME}\", \"Value\":\"${CLIENT_ID}\"},"
		echo -n "{\"Key\":\"CLIENT_SECRET${NAME}\", \"Value\":\"${CLIENT_SECRET}\"},"
		echo -n "{\"Key\":\"REFESH_TOKEN${NAME}\", \"Value\":\"${REFESH_TOKEN}\"},"

	done
	# 腾讯环境变量
	TC_SECRET_ID=$(env | grep TC_SECRET_ID | cut -d "=" -f2)
	TC_SECRET_KEY=$(env | grep TC_SECRET_KEY | cut -d "=" -f2)
	echo -n "{\"Key\":\"TC_SECRET_ID\", \"Value\":\"${TC_SECRET_ID}\"},"
	echo -n "{\"Key\":\"TC_SECRET_KEY\", \"Value\":\"${TC_SECRET_KEY}\"},"
}

function hmac256_py() {

	cat >> $1 <<EOF
# -*- coding: utf-8 -*-
import sys
import hashlib
import hmac

secret_key = sys.argv[1]
service = sys.argv[2]
date = sys.argv[3]
string_to_sign = sys.argv[4]

def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()

secret_date = sign(("TC3" + secret_key).encode("utf-8"), date)
secret_service = sign(secret_date, service)
secret_signing = sign(secret_service, "tc3_request")
signature = hmac.new(secret_signing, string_to_sign.encode(
    "utf-8"), hashlib.sha256).hexdigest()

print(signature)

EOF

}

function auth_sign() {
	local SECRETID=${TC_SECRET_ID}
	local SECRETKEY=${TC_SECRET_KEY}
	local HMAC256="$(mktemp)"
	local ENTER=$'\n'
	local TIME=$1
	local DATE=$(date -d @${TIME} +%F)

	# ************* 步骤 1：拼接规范请求串 *************

	local HTTP_REQUEST='POST'
	local URI='/'
	local QUERY=""
	local HEADERS="${TYPE}${ENTER}host:${HOST}\\n"
	local HEADERS=$(echo -n "${HEADERS}" | sed 's/\(.*\)/\L\1/')
	local SIGED_HEADERS='content-type;host'
	local HASED_REQUEST_PLAYLOAD=$(echo -n "${BODY}" | sha256sum | awk '{print $1}')
	local REQUEST="${HTTP_REQUEST}${ENTER}${URI}${ENTER}${QUERY}\
${ENTER}${HEADERS}${ENTER}${SIGED_HEADERS}${ENTER}${HASED_REQUEST_PLAYLOAD}"
	local HASHED_REQUEST=$(echo -e -n "${REQUEST}" | sha256sum | awk '{print $1}')

	# ************* 步骤 2：拼接待签名字符串 *************
	local SERVICE=$(echo ${HOST} | cut -d "." -f1)
	local STRINGTOSIGN="${ALGORITHM}${ENTER}${TIME}${ENTER}${DATE}/${SERVICE}/tc3_request\
${ENTER}${HASHED_REQUEST}"

	# ************* 步骤 3：计算签名 *************
	hmac256_py ${HMAC256}
	local SIGNATURE=$(python ${HMAC256} "${SECRETKEY}" "${SERVICE}" \
		"${DATE}" "${STRINGTOSIGN}")
	rm -f ${HMAC256}

	#  ************* 步骤 4：拼接 Authorization *************
	echo -e ${ALGORITHM} 'Credential='${SECRETID}/${DATE}/${SERVICE}/tc3_request,\
	 'SignedHeaders='${SIGED_HEADERS}, Signature=${SIGNATURE}
}

function post_result_func_trigger() {
	ACTION=$1
	TRIGGER_NAME=$2
	TRIGGER_DESC=$3
	TIME=$(timestamp 1)
	REGION=${TENCENTCLOUD_REGION}
	VER='2018-04-16'
	ALGORITHM='TC3-HMAC-SHA256'
	TYPE="Content-Type:application/json"
	HOST='scf.tencentcloudapi.com'
	BODY="{\"FunctionName\": \"${SCF_FUNCTIONNAME}\", \
	\"TriggerName\": \"${TRIGGER_NAME}\", \
	\"Type\": \"timer\", \
	\"TriggerDesc\": \"${TRIGGER_DESC}\"}"

	curl -s \
	-H "Host: ${HOST}" \
	-H "X-TC-Action: ${ACTION}" \
	-H "X-TC-Timestamp: ${TIME}" \
	-H "X-TC-Version: ${VER}" \
	-H "X-TC-Region: ${REGION}" \
	-H "X-TC-Language: zh-CN" \
	-H "${TYPE}" \
	-H "Authorization: $(auth_sign ${TIME})" \
	-d "${BODY}" "https://${HOST}/"
}


function post_result_func() {
	ACTION=$1
	FUNC_NAME=$2
	ZIPFILE=$3
	HANDLER='index.main_handler'
	REGION='ap-shanghai'
	RUNTIME='CustomRuntime'
	CODE='ZipFile'
	MEM=64
	TIMEOUT=60

	TIME=$(timestamp 1)
	VER='2018-04-16'
	ALGORITHM='TC3-HMAC-SHA256'
	TYPE='Content-Type:application/json'
	HOST='scf.tencentcloudapi.com'

	BODY_JSON=/tmp/body.json

	if [[ ${ACTION} == 'CreateFunction' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"Runtime\": \"${RUNTIME}\", \
		\"MemorySize\": ${MEM}, \
		\"Handler\": \"${HANDLER}\", \
		\"Timeout\": ${TIMEOUT}, \
		\"Code\": {\"${CODE}\": \"${ZIPFILE}\"}, \
		\"Environment\": {\"Variables\": [$(env_var | sed s/.$//g)]}}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'UpdateFunctionCode' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"Handler\": \"${HANDLER}\", \
		\"Code\": {\"${CODE}\": \"${ZIPFILE}\"}}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'DeleteFunction' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\"}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'Invoke' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\"}" \
		>${BODY_JSON}
	else
		echo "参数错误！"
		echo -e "此脚本仅支持: \\n\
		CreateFunction	创建函数\\n\
		UpdateFunctionCode	更新函数代码\\n\
		DeleteFunction	删除函数\\n\
		Invoke	运行函数\\n"
	fi

	BODY=$(cat ${BODY_JSON})

	curl -s \
	-H "Host: ${HOST}" \
	-H "X-TC-Action: ${ACTION}" \
	-H "X-TC-Timestamp: ${TIME}" \
	-H "X-TC-Version: ${VER}" \
	-H "X-TC-Region: ${REGION}" \
	-H "X-TC-Language: zh-CN" \
	-H "${TYPE}" \
	-H "Authorization: $(auth_sign ${TIME})" \
	-d @${BODY_JSON} \
	"https://${HOST}/"

	rm -f ${BODY_JSON}
}

FUNC_TRIGGER=$1
FUNC_NAME=$2
ZIP_FILE=/tmp/${FUNC_NAME}.zip

if [[ -z ${FUNC_TRIGGER} || -z ${FUNC_NAME} ]]; then
	echo "缺少函数名或触发方式"
	exit 0
fi
if [[ ${FUNC_TRIGGER} == 'CreateFunction' ]]; then
	post_result_func DeleteFunction "${FUNC_NAME}"
	zip -r ${ZIP_FILE} ./ -x ".git/*" -x ".github/*"
	post_result_func "${FUNC_TRIGGER}" "${FUNC_NAME}" $(cat  ${ZIP_FILE} | base64 -w 0) 
	rm -rf  ${ZIP_FILE}
else
	post_result_func "${FUNC_TRIGGER}" "${FUNC_NAME}"
fi
