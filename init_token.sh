#/bin/bash

CLIENT_ID='c4a6ecb7-caa0-4bf1-aef3-43f599714f19'
CLIENT_SECRET='egG__p87.AI_Ca42ElbPRqjH9BQtoY44Wz'
TOKEN="$(mktemp)"
rclone authorize "onedrive" "${CLIENT_ID}" "${CLIENT_SECRET}" \
	| sed -n '/{/,/}/p' | sed '$d' | jq -r \
	> "${TOKEN}"

cat "${TOKEN}" | jq -r '.refresh_token'