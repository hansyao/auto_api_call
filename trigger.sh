#!/bin/bash

ACTION=$1
TRIGGER_NAME=$2
TRIGGER_DESC=$3
REGION='ap-shanghai'
VER='2018-04-16'
ALGORITHM='TC3-HMAC-SHA256'
TYPE="Content-Type:application/json"
HOST='scf.tencentcloudapi.com'
BODY="{\"FunctionName\": \"${SCF_FUNCTIONNAME}\", \
\"TriggerName\": \"${TRIGGER_NAME}\", \
\"Type\": \"timer\", \
\"TriggerDesc\": \"${TRIGGER_DESC}\"}"

SECRETID=${SECRET_ID}
SECRETKEY=${SECRET_KEY}

timestamp() {
	if [ $1 -eq 1 ]; then
		echo -e $(date -u +%s)
	elif [ $1 -eq 2 ]; then
		echo -e $(date -u +%F)
	else
		echo -e $(date -u "+%F %H:%M:%S")
	fi
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

auth_sign() {
	local HMAC256="$(mktemp)"
	local ENTER=$'\n'

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

post_result() {
	curl -s \
    -H "Host: ${HOST}" \
	-H "X-TC-Action: ${ACTION}" \
	-H "X-TC-Timestamp: ${TIME}" \
	-H "X-TC-Version: ${VER}" \
	-H "X-TC-Region: ${REGION}" \
	-H "X-TC-Language: zh-CN" \
	-H "${TYPE}" \
	-H "Authorization: $(auth_sign)" \
	-d "${BODY}" "https://${HOST}/"
}

main() {
	DATE=$(timestamp 2)
	TIME=$(timestamp 1)
	post_result
}

main

