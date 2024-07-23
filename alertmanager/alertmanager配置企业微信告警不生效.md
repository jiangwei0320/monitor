##### alertmanager配置企业微信告警不生效

```
"global":
  "resolve_timeout": "5m"
  "smtp_from": "leinao_monitor@163.com"
  "smtp_smarthost": "smtp.163.com:465"
  "smtp_auth_username": "leinao_monitor@163.com"
  "smtp_auth_password": "PRVVZMHJWMXBYDLE"
  "smtp_require_tls": false
"inhibit_rules":
- "equal":
  - "namespace"
  - "alertname"
  "source_match":
    "severity": "critical"
  "target_match_re":
    "severity": "warning|info"
- "equal":
  - "namespace"
  - "alertname"
  "source_match":
    "severity": "warning"
  "target_match_re":
    "severity": "info"
"receivers":
- "name": "email"
  "email_configs":
  - "to": "devops@leinao.ai"
    "headers":
      "Subject": '{{ if eq .Status "firing" }}【告警】{{ .CommonLabels.alertname }}{{ else }}【告警恢复】{{ .CommonLabels.alertname }}{{ end }}'
    "html": '{{ template "email.default.message" . }}'
    "send_resolved": true
- "name": "wechat"
  "wechat_configs":
  - "to_party": '2'
    "agent_id": '1000007' 
    "api_secret": 'Q4tMnY4M6Tw7VvVkXjeG_NVOSw2wYe1W6n8IdKooKlo' 
    "corp_id": 'ww8c6c642a9aa729db' 
    "send_resolved": true
    "to_party": '2'
	"message": |
	  {{ template "wechat_business.html" . }}
"route":
  "group_by":
  - "namespace"
  "group_interval": "5m"
  "group_wait": "30s"
  "receiver": "email"
  "repeat_interval": "12h"
  "routes":
  - "match":
      "alertname": "wechat"
    "receiver": "wechat"
"templates":
- "/etc/alertmanager/config/*.tmpl"
```

通过检查下述python脚本检测问题所在

```
$ cat wechat.py
#!/usr/bin/env python
#coding=utf_8
#!/root/.virtualenvs/wechat/bin/python
# usage: send message via wechat
import requests, sys, json
import urllib3
urllib3.disable_warnings()
###填写参数###
# Corpid是企业号的标识
Corpid = "ww8c6c642a9aa729db"       ### 修改这里
# Secret是管理组凭证密钥
Secret = "Q4tMnY4M6Tw7VvVkXjeG_NVOSw2wYe1W6n8IdKooKlo"   ### 修改这里
# 应用ID
Agentid = "1000007"   ### 修改这里
# token_config文件放置路径
Token_config = r'/usr/local/test__wechat_config.json'
###下面的代码都不需要动###
def GetTokenFromServer(Corpid, Secret):
    """获取access_token"""
    Url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken"
    Data = {
        "corpid": Corpid,
        "corpsecret": Secret
    }
    r = requests.get(url=Url, params=Data, verify=False)
    print(r.json())
    if r.json()['errcode'] != 0:
        return False
    else:
        Token = r.json()['access_token']
        file = open(Token_config, 'w')
        file.write(r.text)
        file.close()
        return Token
def SendMessage(Partyid, Subject, Content):
    """发送消息"""   
    # 获取token信息
    try:
        file = open(Token_config, 'r')
        Token = json.load(file)['access_token']
        file.close()
    except:
        Token = GetTokenFromServer(Corpid, Secret)

    # 发送消息
#    Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
    Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=ACCESS_TOKEN"
    Data = {
        "toparty": Partyid,
        "msgtype": "text",
        "agentid": Agentid,
        "text": {"content": Subject + '\n' + Content},
        "safe": "0"
    }
    r = requests.post(url=Url, data=json.dumps(Data), verify=False)

    # 如果发送失败，将重试三次
    n = 1
    while r.json()['errcode'] != 0 and n < 4:
        n = n + 1
        Token = GetTokenFromServer(Corpid, Secret)
        if Token:
            Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
            r = requests.post(url=Url, data=json.dumps(Data), verify=False)
            print(r.json())

    return r.json()
if __name__ == '__main__':
    # 部门id
    Partyid = '2'
    # 消息标题
    Subject = '自应用程序代码测试'
    # 消息内容
    Content = 'str(sys.argv[3])'
    Status = SendMessage(Partyid, Subject, Content)
    print(Status)
```

如果centos提示确实requests包，

```
yum install epel-release
yum install python3-pip
pip3 install requests
```

执行脚本

python3 wechat.py

提示:

```
FN-354hJ0Ec2tqf8QAsej9NP0b2XNiecXYMQDOvrCl8CzwgYF8dYpTUiG6BFJVFKDUAru8P4J_wk31D8yfyfTt3ld5gww', 'expires_in': 7200}
/usr/lib/python3.6/site-packages/requests/packages/urllib3/connectionpool.py:1004: InsecureRequestWarning: Unverified HTTPS request is being made. Adding certificate ver
ification is strongly advised. See: https://urllib3.readthedocs.io/en/latest/advanced-usage.html#ssl-warnings
  InsecureRequestWarning,
{'errcode': 60020, 'errmsg': 'not allow to access from your ip, hint: [1721635284214400803011566], from ip: 112.29.111.158, more info at https://open.work.weixin.qq.com/
devtool/query?e=60020'}
{'errcode': 60020, 'errmsg': 'not allow to access from your ip, hint: [1721635284214400803011566], from ip: 112.29.111.158, more info at https://open.work.weixin.qq.com/
devtool/query?e=60020'}
```

原因，没有在企业微信中添加公网ip白名单；

参考：https://blog.csdn.net/qq_29974229/article/details/126737488

如何设置企业微信ip白名单：https://blog.csdn.net/weixin_45385457/article/details/132278442

##### 如何设置企业微信白名单：

参考：https://blog.csdn.net/weixin_45385457/article/details/132278442

下述是脚本：

```
#-*- encoding:utf-8 -*-
from flask import abort, request
from flask import Flask
from xml.dom.minidom import parseString
import _thread
import time
import os
import sys
sys.path.append("weworkapi_python/callback")  # 正确的模块导入路径
from WXBizMsgCrypt3 import WXBizMsgCrypt   # https://github.com/sbzhu/weworkapi_python 项目地址
app = Flask(__name__)

# 对应步骤4中接受消息回调模式中的URL，如域名是'www.example.com' 那么在步骤4中填入的url就为"http://www.example.com/hook_path"
@app.route('/hook_path', methods=['GET','POST'])
def douban():
    if request.method == 'GET':
        echo_str = signature(request, 0)
        return(echo_str)
    elif request.method == 'POST':
        echo_str = signature2(request, 0)
        return(echo_str)

qy_api = [
    WXBizMsgCrypt("sX42pSCNCmPSGnEd", "mONhlhHsd5Eg3SgADjOT12CFpZFLyyJb0XzunPkc6UR", "ww8c6c642a9aa729db"),
] #对应接受消息回调模式中的token，EncodingAESKey 和 企业信息中的企业id   # 只改这里即可

# 开启消息接受模式时验证接口连通性
def signature(request, i):
    msg_signature = request.args.get('msg_signature', '')
    timestamp = request.args.get('timestamp', '')
    nonce = request.args.get('nonce', '')
    echo_str = request.args.get('echostr', '')
    ret,sEchoStr=qy_api[i].VerifyURL(msg_signature, timestamp,nonce,echo_str)
    if (ret != 0):
        print("ERR: VerifyURL ret: " + str(ret))
        return("failed")
    else:
        return(sEchoStr)
# 实际接受消息
def signature2(request, i):
    msg_signature = request.args.get('msg_signature', '')
    timestamp = request.args.get('timestamp', '')
    nonce = request.args.get('nonce', '')
    data = request.data.decode('utf-8')
    ret,sMsg=qy_api[i].DecryptMsg(data,msg_signature, timestamp,nonce)
    if (ret != 0):
        print("ERR: DecryptMsg ret: " + str(ret))
        return("failed")
    else:
        with open ("/var/log/qywx.log", 'a+') as f: # 消息接收日志
            doc = parseString(sMsg)
            collection = doc.documentElement
            name_xml = collection.getElementsByTagName("FromUserName")
            msg_xml = collection.getElementsByTagName("Content")
            type_xml = collection.getElementsByTagName("MsgType")
            pic_xml = collection.getElementsByTagName("PicUrl")
            msg = ""
            name = ""
            msg_type = type_xml[0].childNodes[0].data
            if msg_type == "text": #文本消息
                name = name_xml[0].childNodes[0].data        #发送者id
                msg = msg_xml[0].childNodes[0].data          #发送的消息内容
                f.write(time.strftime('[%Y-%m-%d %H:%M:%S]') + "[ch%d] %s:%s\n" % (i, name, msg))
                _thread.start_new_thread(os.system, ("python3 command.py '%s' '%s' '%d' '%d'" % (name, msg, i, 0), )) #此处将消息进行外部业务处理

            elif msg_type == "image": #图片消息
                name = name_xml[0].childNodes[0].data
                pic_url = pic_xml[0].childNodes[0].data
                f.write(time.strftime('[%Y-%m-%d %H:%M:%S]') + "[ch%d] %s:图片消息\n" % (i, name))
                _thread.start_new_thread(os.system, ("python3 command.py '%s' '%s' '%d' '%d'" % (name, pic_url, i, 1), ))  #此处将消息进行外部业务处理

            f.close()

        return("ok")

if __name__=='__main__':
    app.run("0.0.0.0", 12345)  #本地监听端口,可自定义
    
```

**注只改脚本这里就可以了：**

**qy_api = [**
    **WXBizMsgCrypt("sX42pSCNCmPSGnEd", "mONhlhHsd5Eg3SgADjOT12CFpZFLyyJb0XzunPkc6UR", "ww8c6c642a9aa729db"),**
**] #对应接受消息回调模式中的token，EncodingAESKey 和 企业信息中的企业id   # 只改这里即可**