##### 1、在K8S部署的grafana，开启SMTP邮件发送功能

```
# 配置grafana对应deployment，配置grafana这个容器，增加以下环境变量
- name: GF_AUTH_PROXY_ENABLED
  value: "true"
- name: GF_SMTP_ENABLED
  value: "true"
- name: GF_SMTP_HOST
  value: "smtp.qq.com:465"
- name: GF_SMTP_PASSWORD
  value: "xthfumeyzxfwjbaf"   #邮件服务器授权码。qq邮箱设置中找
- name: GF_SMTP_USER
  value: "1580067112@qq.com"
- name: GF_SMTP_FROM_ADDRESS
  value: "1580067112@qq.com"
- name: GF_SMTP_FROM_NAME
  value: "grafana"
```

