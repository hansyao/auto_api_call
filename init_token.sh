#/bin/bash

CLIENT_ID='xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx'
CLIENT_SECRET='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
TOKEN="$(mktemp)"
rclone authorize "onedrive" "${CLIENT_ID}" "${CLIENT_SECRET}" \
	| sed -n '/{/,/}/p' | sed '$d' | jq -r \
	> "${TOKEN}"

cat "${TOKEN}" | jq -r '.refresh_token'