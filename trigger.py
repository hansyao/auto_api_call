# -*- coding: utf-8 -*-
import hashlib
import hmac
import json
import sys
import os
import time
import requests
from datetime import datetime

secret_id=os.getenv('SECRET_ID')
secret_key=os.getenv('SECRET_KEY')

service = "scf"
host = "scf.tencentcloudapi.com"
endpoint = "https://" + host
region = "ap-shanghai"
action = sys.argv[1]
version = "2018-04-16"
algorithm = "TC3-HMAC-SHA256"
timestamp = int(time.time())
date = datetime.utcfromtimestamp(timestamp).strftime("%Y-%m-%d")
params = {"FunctionName": os.getenv('SCF_FUNCTIONNAME'),
          'TriggerName': sys.argv[2],
          'Type': 'timer',
          'TriggerDesc': sys.argv[3]
          }

# ************* 步骤 1：拼接规范请求串 *************
http_request_method = "POST"
canonical_uri = "/"
canonical_querystring = ""
ct = "application/json"
payload = json.dumps(params)
canonical_headers = "content-type:%s\nhost:%s\n" % (ct, host)
signed_headers = "content-type;host"
hashed_request_payload = hashlib.sha256(payload.encode("utf-8")).hexdigest()
canonical_request = (http_request_method + "\n" +
                     canonical_uri + "\n" +
                     canonical_querystring + "\n" +
                     canonical_headers + "\n" +
                     signed_headers + "\n" +
                     hashed_request_payload)

# ************* 步骤 2：拼接待签名字符串 *************
credential_scope = date + "/" + service + "/" + "tc3_request"
hashed_canonical_request = hashlib.sha256(
    canonical_request.encode("utf-8")).hexdigest()
string_to_sign = (algorithm + "\n" +
                  str(timestamp) + "\n" +
                  credential_scope + "\n" +
                  hashed_canonical_request)

# ************* 步骤 3：计算签名 *************
# 计算签名摘要函数
def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


secret_date = sign(("TC3" + secret_key).encode("utf-8"), date)
secret_service = sign(secret_date, service)
secret_signing = sign(secret_service, "tc3_request")
signature = hmac.new(secret_signing, string_to_sign.encode(
    "utf-8"), hashlib.sha256).hexdigest()
# print(signature)

# ************* 步骤 4：拼接 Authorization *************
authorization = (algorithm + " " +
                 "Credential=" + secret_id + "/" + credential_scope + ", " +
                 "SignedHeaders=" + signed_headers + ", " +
                 "Signature=" + signature)

header = {
    'Authorization': authorization,
    'Content-Type': 'application/json',
    'Host': host,
    'X-TC-Action': action,
    'X-TC-Timestamp': str(timestamp),
    'X-TC-Version': version,
    'X-TC-Region': region,
    'X-TC-Language': 'zh-CN'
}

r = requests.post(endpoint, headers=header, data=payload)
print(r.text)
