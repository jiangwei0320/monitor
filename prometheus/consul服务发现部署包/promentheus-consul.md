Consul 是一个多网络工具，提供功能齐全的服务网格解决方案。它解决了在多云和混合云环境中运行微服务和云基础设施的网络和安全挑战。本文档介绍了 Consul 的概念、它解决的问题，并包含使用 Consul 的快速入门教程。

https://yunlzheng.gitbook.io/prometheus-book/part-ii-prometheus-jin-jie/sd/service-discovery-with-consul

1、服务安装

```
helm install consul consul/ -n consul
```

2、注意事项，consul UI容器的端口是**8500**，启动的svc是consul-consul-ui，使用的是80端口，需要修改svc监听的80端口改为8500，nodeport也得是8500，要不然无法访问

3、注册一个服务到consul

```
curl -X PUT -d '{"id": "10.0.102.10","name": "10.0.102.10","address": "10.0.102.10","port": 9110,"tags": ["10.0.102.10"],"meta": {"job": "10.0.102.10","instance": "10.0.102.10"},"checks": [{"http": "http://10.0.102.10:9110/metrics", "interval": "5s"}]}' http://localhost:8500/v1/agent/service/register
```

4、删除一个consul中的node节点

```
curl --request PUT http://10.0.100.203:8500/v1/agent/service/deregister/10.0.102.10
注：10.0.102.10 为上述put传参中唯一的id,建议使用mac地址
```

5、在 prometheus 中配置自动发现consul，在prometheus页面的configration中配置（根据实际部署情况，正常为promethues.yaml文件）

```
- job_name: consul-prometheus
  consul_sd_configs:
  - server: 10.0.100.203:8500
    refresh_interval: 30s
```

