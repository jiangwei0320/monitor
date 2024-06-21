##### PS：以下过程需要项目部署完成后执行

##### 1、grafana配置修改，禁止匿名用户登录(ini配置文件 不生效，因为这里配置了环境变量，需要 在 环境变量配置)

```
kubectl set env deployment/monitor-grafana GF_AUTH_ANONYMOUS_ENABLED=false -n monitoring
```

配置文件配置(很多默认配置并未写进ini文件。需要修改默认值，添加进来即可)：

```
[date_formats]
default_timezone = CST
[server]
domain = localhost
root_url = %(protocol)s://%(domain)s:%(http_port)s/grafana
serve_from_sub_path = true
[auth.anonymous]
enabled = true
```



##### 

##### 2、允许页面嵌入

```
[security]
allow_embedding	= true # 默认值是false。不允许页面嵌入
kiosk  # 去除边框
```

##### 3、通过ingress配置prometheus、alertmanager账号密码认证

###### （1）centos 离线yum安装htpasswd，直接使用下述离线包

```
# 离线安装htpasswd、这里提供rpm包（httpd-tools.rpm）
  yun install httpd-tools.rpm
  
# 创建用户密码文件,用户名和文件名按需定义(用户名：root 文件名: auth)，注意这里需要通过命令行输入密码 
  htpasswd -c auth root
  
# 创建secret文件（basic-auth为secret名称）
  kubectl create secret generic basic-auth --from-file=auth  -n  monitoring

```

###### （2）更新 prometheus、alertmanager 的ingress（注意ingress-name是不是更当前集群一致）

```
# 重新apply两个ingress文件即可，验证访问prometheus、alertmanager是否需要输入密码（两个ingress公用上述创建的账号、密码）
# 新增配置如下，文件中加好了，下述仅供参考：
  annotations:
    nginx.ingress.kubernetes.io/auth-secret: basic-auth (上述monitrong空间的secret名称，需对应上)
    nginx.ingress.kubernetes.io/auth-type: basic
```



