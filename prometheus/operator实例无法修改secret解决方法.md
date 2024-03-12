

方法一：

1.修改promethes-operator部署得环境prometheus的configration

**下述方法 仅支持configration.scrape_configs: 的更改，也就是追加不同的 job-name**

（1）新建一个prometheus-additional.yaml文件，文件内容如下，填写你本次要**附加**得一些配置，原configration中存在的，这里不需要加了

```
- job_name: kubernetes-pods
  honor_labels: true
  ....
```

（2）promethes-operator所在得namespace空间下新建一个secret 

```
$ kubectl create secret generic additional-config --from-file=prometheus-additional.yaml -n monitoring
注：<additional-config>为secretname 自定义
```

（3）修改 prometheuses.monitoring.coreos.com crd配置

```
# 查看当前集群上述crd资源的name
kubectl get prometheuses.monitoring.coreos.com -n monitoring
```

```
# 编辑该crd资源。加上如下配置
$ kubectl edit prometheuses.monitoring.coreos.com -n monitoring  k8s
spec:
  additionalScrapeConfigs:
    key: prometheus-additional.yaml
    name: additional-configs
注：<key>为上述执行 yaml文件名
   <value>为上述生成的secretname
```



在 operator中可以，如果修改prometheus 的secret（prometheus.yaml.gz），也就是页面中的 **configration** 配置，需要在operator部署**yaml所在目录下**，按照 “**Prometheus Operator 高级配置.pdf**”文档步骤一步一步配置

还可以参考：https://developer.aliyun.com/article/1118992



方法二：（通过新建promtheus实例，并不是直接 修改configration，而是新建一个promethues）

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