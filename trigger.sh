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

	paste "${CLIENT_NAME}" "${CLIENT_ID}" "${CLIENT_SECRET}" \
		"${REFESH_TOKEN}" | grep -v '^$'

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
	local HEADER=$1
	local BODY=$2

	local SECRETID=${TC_SECRET_ID}
	local SECRETKEY=${TC_SECRET_KEY}
	local HMAC256="$(mktemp)"
	local ALGORITHM='TC3-HMAC-SHA256'
	local ENTER=$'\n'
	local TIME=$(echo -e "${HEADER}" | grep 'X-TC-Timestamp:' | awk '{print $2}')
	local DATE=$(date -u -d @${TIME} +%F)
	local TYPE=$(echo -e "${HEADER}" | grep 'Content-Type:' | sed s/\ //g)
	local HOST=$(echo -e "${HEADER}" | grep 'Host:' | awk '{print $2}')

	# ***************** 步骤 1：拼接规范请求串 *************
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

	# ***************** 步骤 2：拼接待签名字符串 *************
	local SERVICE=$(echo ${HOST} | cut -d "." -f1)
	local STRINGTOSIGN=$(echo -e "${ALGORITHM}${ENTER}${TIME}${ENTER}${DATE}\
/${SERVICE}/tc3_request${ENTER}${HASHED_REQUEST}")

	# ************* 步骤 3：计算签名 *************
	hmac256_py ${HMAC256}
	local SIGNATURE=$(python ${HMAC256} "${SECRETKEY}" "${SERVICE}" \
		"${DATE}" "${STRINGTOSIGN}")
	rm -f ${HMAC256}
	
	#  ************* 步骤 4：拼接 Authorization *************
	echo -e Authorization: ${ALGORITHM} 'Credential='${SECRETID}/${DATE}/${SERVICE}\
/tc3_request, 'SignedHeaders='${SIGED_HEADERS}, Signature=${SIGNATURE}
}

function header() {
	local HOST=$1
	local VERSION=$2
	local REGION=$3
	local ACTION=$4
	local HEADER=$5
	local TIME=$(timestamp 1)
	
	cat > ${HEADER} <<EOF
Host: ${HOST}
X-TC-Action: ${ACTION}
X-TC-Timestamp: ${TIME}
X-TC-Version: ${VERSION}
X-TC-Region: ${REGION}
X-TC-Language: zh-CN
Content-Type: application/json
EOF

}

function pack_code() {
	local ZIP_FILE=/tmp/$1.zip	
	# 打包代码
	sed -i s/^PLATFORM\=./PLATFORM\=2/g graph_api_app.sh
	zip -r ${ZIP_FILE} ./ -x ".git/*" -x ".github/*" >/dev/null
	echo -e "${ZIP_FILE}"
}

function body() {
	local ACTION=$1
	local FUNC_NAME=$2
	local BODY_JSON=$3

	if [[ ${ACTION} == 'CreateFunction' ]]; then
		# 函数基本配置
		local RUNTIME='CustomRuntime'
		local MEM=64
		local TIMEOUT=60
		# 代码基本配置
		local HANDLER='index.main_handler'
		local CODE='ZipFile'
		# 打包代码
		local ZIP_FILE=$(pack_code ${FUNC_NAME})
		local ZIPFILE_BASE64=$(cat ${ZIP_FILE} | base64 -w 0)
		echo -e "为函数${FUNC_NAME}打包代码为完成"

		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"Runtime\": \"${RUNTIME}\", \
		\"MemorySize\": ${MEM}, \
		\"Handler\": \"${HANDLER}\", \
		\"Timeout\": ${TIMEOUT}, \
		\"Code\": {\"${CODE}\": \"${ZIPFILE_BASE64}\"}, \
		\"Environment\": {\"Variables\": [$(env_var | sed s/.$//g)]}}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'UpdateFunctionCode' ]]; then
		# 代码基本配置
		local HANDLER='index.main_handler'
		local CODE='ZipFile'
		# 打包代码
		local ZIP_FILE=$(pack_code ${FUNC_NAME})
		local ZIPFILE_BASE64=$(cat ${ZIP_FILE} | base64 -w 0)
		echo -e "为函数${FUNC_NAME}打包代码为完成"

		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"Handler\": \"${HANDLER}\", \
		\"Code\": {\"${CODE}\": \""${ZIPFILE_BASE64}"\"}}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'DeleteFunction' || ${ACTION} == 'Invoke' \
		|| ${ACTION} == 'GetFunction' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\"}" \
		>${BODY_JSON}

	elif [[ ${ACTION} == 'UpdateFunctionConfiguration' ]]; then
		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"Environment\": {\"Variables\": [$(env_var | sed s/.$//g)]}}" \
		>${BODY_JSON}

	elif [[ "${ACTION}" == 'CreateTrigger' || "${ACTION}" == 'DeleteTrigger' ]]; then
		local TRIGGER_NAME=$4
		local TRIGGER_DESC=$5

		echo -e "{\"FunctionName\": \"${FUNC_NAME}\", \
		\"TriggerName\": \"${TRIGGER_NAME}\", \
		\"Type\": \"timer\", \
		\"TriggerDesc\": \"${TRIGGER_DESC}\"}" \
		>${BODY_JSON}
	else
		echo "参数错误！"
		echo -e "仅支持: \\n\
		CreateFunction	创建函数\\n\
		UpdateFunctionCode	更新函数代码\\n\
		UpdateFunctionConfiguration	更新函数配置\\n\
		CreateTrigger	创建触发器\\n\
		DeleteTrigger	删除触发器\\n\
		DeleteFunction	删除函数\\n\
		Invoke	运行函数\\n"
	fi
}

function post_result_func() {
	local ACTION=$1
	local BODY_JSON=$2

	# 定义函数
	local HOST='scf.tencentcloudapi.com'
	local VERSION='2018-04-16'
	local REGION='ap-shanghai'

	# 获取BODY内容
	local BODY=$(cat ${BODY_JSON})

	# 定义header
	local HEADER=/tmp/header.txt
	header "${HOST}" "${VERSION}" "${REGION}" "${ACTION}" "${HEADER}"

	# 根据HEADER和BODY签名
	local SIGNATURE=$(auth_sign "$(cat ${HEADER})" "${BODY}")

	# 将签名封装入header
	echo -e "${SIGNATURE}" >> ${HEADER}

	# 生成header数组，兼容老版本curl
	local ARGS[0]='-k'
	local i=1
	while read LINE && [[ -n "${LINE}" ]]
	do
		local ARGS[$[i]]='-H'
		local ARGS[$(($[i] + 1))]="${LINE}"
		i=$(($[i] + 2))
	done <${HEADER}

	# POST
	curl -s -H "${ARGS[@]}" -d @${BODY_JSON} "https://${HOST}/"
}

ACTION=$1
FUNC_NAME=$2
BODY_JSON='/tmp/body.json'
ZIP_FILE=/tmp/"${FUNC_NAME}".zip

if [[ -z "${ACTION}" || -z "${FUNC_NAME}" ]]; then
	echo "缺少函数名或触发方式"
	exit 0
fi

if [[ "${ACTION}" == 'CreateFunction' ]]; then
	# 查询函数是否存在
	body 'GetFunction' "${FUNC_NAME}" "${BODY_JSON}"
	RESPONSE=$(post_result_func GetFunction "${BODY_JSON}")
	# 函数不存在，则创建
	if [[ $(echo -e "${RESPONSE}" | jq -r '.Response.Error') != 'null' ]]; then
		body 'CreateFunction' "${FUNC_NAME}" "${BODY_JSON}"
		post_result_func 'CreateFunction' "${BODY_JSON}"
	# 函数存在，则更新
	else
		echo '更新环境变量'
		body UpdateFunctionConfiguration "${FUNC_NAME}" "${BODY_JSON}"
		post_result_func UpdateFunctionConfiguration "${BODY_JSON}"

		echo -e "\\n更新代码"
		body UpdateFunctionCode "${FUNC_NAME}" "${BODY_JSON}"
		post_result_func UpdateFunctionCode "${BODY_JSON}"
	fi
	echo -e "\\n等待函数发布成功"
	i=0
	while :
	do
		if [[ $[i] -ge 10 ]]; then
			echo -e "函数 ${FUNC_NAME} 发布超时$(($[i] + 1))秒"
			echo -e "结束任务"
			# 清理临时文件
			rm -f  ${ZIP_FILE}
			rm -f ${HEADER}
			rm -f ${BODY_JSON}
			exit 0
		fi
		body 'GetFunction' "${FUNC_NAME}" "${BODY_JSON}"
		RESPONSE=$(post_result_func GetFunction "${BODY_JSON}" \
			| jq -r '.Response.Status')
		if [[ "${RESPONSE}" == 'Active' ]]; then
			echo -e "函数 ${FUNC_NAME} 发布成功"
			break
		fi
		sleep 1
		let i++
	done
	echo '开始测试运行函数'
	body Invoke "${FUNC_NAME}" "${BODY_JSON}"
	post_result_func Invoke "${BODY_JSON}"
	
elif [[ "${ACTION}" == 'CreateTrigger' || "${ACTION}" == 'DeleteTrigger' ]]; then
	TRIGGER_NAME=$3
	TRIGGER_DESC=$4
	body "${ACTION}" "${FUNC_NAME}" "${BODY_JSON}" "${TRIGGER_NAME}" "${TRIGGER_DESC}"
	post_result_func "${ACTION}" "${BODY_JSON}"
else
	# 按照触发条件生成BODY
	body "${ACTION}" "${FUNC_NAME}" "${BODY_JSON}"
	# 签名并执行函数
	post_result_func "${ACTION}" "${BODY_JSON}"
fi

echo -e "\\n清理临时文件"
rm -f ${ZIP_FILE}
rm -f ${HEADER}
rm -f ${BODY_JSON}

exit 0