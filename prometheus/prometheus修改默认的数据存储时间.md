operator部署的prometheus，默认配置都通过prometheuses.monitoring.coreos.com  该crd修改

kubectl get prometheuses.monitoring.coreos.com -n monitoring k8s

```
spec:
  retention: 180d
# 修改后不需要重启，即可生效
```




