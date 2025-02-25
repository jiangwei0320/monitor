查询页面http://10.0.101.50/prometheus/targets?search= ，发现node-exporter是https，实际我们用http

如果node-exporter http访问不到， 可以看下部署时候启动命令是不是只监听了127.0.0.1，改为0.0.0.0

修改servicemonitors.monitoring.coreos.com

```shell
kubectl edit servicemonitors.monitoring.coreos.com -n monitoring node-exporter
```

```
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 15s
    port: https
    relabelings:
    - action: replace
      regex: (.*)
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
    scheme: http   # 这里的这个协议就是target里面用的，
```

注：如果这里改不生效，看下prometheus-k8s，这里面prometheus.yaml.gz 可能也会配置node-exporter为https

```
kubectl  get secrets -n monitoring
```

