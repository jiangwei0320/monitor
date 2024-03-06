问题：我们无法修改原生的operator部署的prometheus 的secret（prometheus.yaml.gz），也就是页面中的 **configration** 配置

参考连接：https://yunlzheng.gitbook.io/prometheus-book/part-iii-prometheus-shi-zhan/operator/use-custom-configuration-in-operator

1、解决方法：

（1）重新建一个crd实例，下述创建的crd，会自动重新创建一个prometheus实例，同时也会自动创建该实例对应的几个volumes: 对应的secret。这些secret可以更改

```
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: consul-service-discovery
  namespace: monitor
spec:
  serviceAccountName: prometheus-operator-prometheus
  resources:
    requests:
      memory: 400Mi
```

（2）剩下的svc+配置 根据实际需求 自己写就可以了