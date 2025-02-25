#### 1、允许远程写入当前prometheus

在prometheus-operator部署的环境中,修改crd -prometheuses.monitoring.coreos.com ，添加下述配置

```
spec:
  enableFeatures:
  - remote-write-receiver
```

