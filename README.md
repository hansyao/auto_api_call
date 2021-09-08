下一次运行时间: 09/08/21 21:59:30 (北京 UTC+8）

---

>纯shell写的脚本，自动调用微软graph api，保持Office 365 E5开发活跃，达到免费续期的目的。

>可选择一键部署到Github Actions, 腾讯云函数和VPS。

>可先Fork本项目后，按照以下步骤部署。

---
# 部署说明
## 准备工作
1. **Github**: 

* 申请一个Personal access token，授予repo和workflow权限
![Github Secret ID](https://cdn.jsdelivr.net/gh/hansyao/image-hosting@master/20210606/Screenshot%20from%202021-08-23%2010-06-05.5haf6e1xk4g0.png)

* 在本项目settings->Actions secrets新建New secrets命名为**GH_TOKEN**，将上面申请到的Personal access token粘贴进去。

2. **腾讯云函数**(如需要部署)： 

* 在本项目settings->Actions secrets新建两个New secrets命名为**TC_SECRET_ID**和**TC_SECRET_KEY**, 将相应的腾讯密钥ID和密钥复制过来。

3. **微软**

* 新建Web应用，将重定向地址指向http://localhost:53682/
* 申请证书和密码授予相关API权限
* 将申请到的CLIENT ID和SECRET命名为CLIENT_ID1和CLIENT_SECRET1添加到本项目settings->Actions secrets
* 根据申请到的CLIENT ID和SECRET用[rclone](https://rclone.org/downloads/)得到refresh_token, 命名为REFESH_TOKEN1添加到本项目settings->Actions secrets。(**特别注意：** [rclone](https://rclone.org/downloads/)生成时有两个token - access_token 和 refresh_token， 这里需要取用的是**refresh_token**)
	>如是Linux系统，可运行本项目的小工具[init_token.sh](./init_token.sh)按提示填入**CLIENT_ID**和**CLIENT_SECRET**即可很方便地得到REFRESH_TOKEN。
* 将CLIENT_ID， CLIENT_SECRET， REFESH_TOKEN同时填入[auto_ms_api.yml](../../blob/master/.github/workflows/auto_ms_api.yml#L19-L27)
	>如有多个可按照CLIENT_ID2， CLIENT_SECRET2和REFESH_TOKEN2添加。(保持前缀CLIENT_ID， CLIENT_SECRET， REFESH_TOKEN一致并成对出现即可，本项目会自动抓取所有符合规则的环境变量运行)

最终，我们可以在在本项目settings->Actions secrets中得到如下token。

![](https://cdn.jsdelivr.net/gh/hansyao/image-hosting@master/20210606/Screenshot%20from%202021-08-23%2011-23-02.2gyy9bofyby0.png)


## 运行Actions

转到本项目Actions, 手工运行一次[MS OFFICE 365 E5自动续期](../../actions/workflows/auto_ms_api.yml)， 如果运行成功，下一次运行时间会自动改为随机时间，可按需更改[graph_api_app.sh第5行](../../blob/b1b34738316828b6adcd4d38c7fa5132a297e9d4/graph_api_app.sh#L5)的运行频率（理论上无需进行任何更改）。
```
FREQUENCY=60 	# 频率（单位：分钟）： 取【当前时间+(0~FREQUENCY之间的随机数)+10】确定为下一次运行的时间
```

如需部署到腾讯云函数，可以运行action [部署到腾讯云函数](../../actions/workflows/tencent_cloud.yml), 如果准备工作3中的密钥填得正确的话，本项目会自动部署到你的腾讯云函数账户里并设定为随机触发。

如需部署到VPS: 
1. 在本项目settings->Actions secrets新建追加以下New secrets将VPS的SSH登录信息填入：
```bash
	REMOTE_IP		#目标VPS的IP地址或者指向的域名
	REMOTE_PORT		#ssh端口
	REMOTE_SSH_KEY		#ssh密钥 (密钥与密码二选一即可)
	REMOTE_PASSWORD		#ssh登录密码 (密钥与密码二选一即可)
	REMOTE_USER_NAME	#ssh登录用户名
```
2. 然后运行action [部署到远程服务器](../../actions/workflows/deploy_to_remote.yml), 本项目即可自动部署到你的VPS服务器里并设定为随机触发， 任务触发后最后一次的日志默认保存在服务器路径```$HOME/graph_api/graph_api.log```。

<br>

**备注**：运行Actions后，请检查调用API部分的日志(见如下截屏)，确保API调用成功。
![](https://cdn.jsdelivr.net/gh/hansyao/image-hosting@master/20210606/e5_actions.1cdg7rdlm31c.png)

<br>
至此，全部部署完成。
