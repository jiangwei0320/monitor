

其实Operator作为控制器，会去创建Prometheus、ServiceMonitor、AlertManager以及PrometheusRule4个CRD资源对象，然后会一直监控并维持这4个资源对象的状态。

- *Prometheus*：管理集群中的 Prometheus StatefulSet 实例；
- *ServiceMonitor*：而ServiceMonitor就是exporter的各种抽象，exporter是用来提供专门提供metrics数据接口的工具，Prometheus就是通过ServiceMonitor提供的metrics数据接口去 pull 数据，通过 Label Selector 选取需要监控的 Endpoint 对象；
- *Alertmanager*：管理集群中的 Alertmanager StatefulSet 实例；
- *PrometheusRule*：将告警规则配置动态加载到 Prometheus 实例中。



场景：我们需要将prometheus-operator的数据持久化

#### 1、查看Prometheus的statfulset，容器volumemounts字段，找到容器数据挂载点；

#### 2、因为直接修改statefulset是不生效的，通过修改crd资源 更改容器配置，添加storage字段 ；

```
# kubectl get prometheuses.monitoring.coreos.com -n monitoring 
# kubectl edit prometheuses.monitoring.coreos.com -n monitoring k8s
spec:
  ....
  retention: 15d   #这个配置是修改默认prometheus保留的数据24h时间，在这里设置15天，pv里面的数据，默认超过15天的会自动被清理 
  storage:
    volumeClaimTemplate:
      spec:
        resources:
          requests:
            storage: 20Gi
        storageClassName: prometheusd
        
# 可以在http://IP/prometheus/status中查看保留时间是否生效
```

#### 3、定义了 一个storageClass

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: prometheusdb
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

#### 4、创建pv、pvc

```
提前创建好pv对应的hostpath路径，并赋予目录，子目录所有执行权限
```



```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prom-local-pv-0
  labels:
    app: prometheus
  namespace: monitoring
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: prometheusdb
  local:
    path: /gdata/prometheus_db
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - yigou-dev-102-46  #这里 需要对应集群具体的 node
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/managed-by: prometheus-operator
    app.kubernetes.io/name: prometheus
    operator.prometheus.io/name: k8s
    operator.prometheus.io/shard: "0"
    prometheus: k8s
  name: prometheus-k8s-db-prometheus-k8s-0
  namespace: monitoring
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  selector:
    matchLabels:
      app: prometheus
  storageClassName: prometheusdb
  volumeMode: Filesystem
  volumeName: prom-local-pv-0
```

#### 