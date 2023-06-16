##### 一、在grafana模板中，设置一个变量，如果想只输出某个函数的key对应的value，可以参考：

1、当前函数名为job_gpu_util，它的输出结果如下：

```
job_gpu_util{card_type="DCU", container="prometheus-pushgateway", endpoint="prometheus-pushgateway", exported_job="sugon-metrics", instance="10.244.118.50:9091", job="prometheus-pushgateway", job_name="jupyter-16555", job_type="jupyter", namespace="monitoring", pod="prometheus-pushgateway-7b5f7bb557-wnk7m", service="prometheus-pushgateway", subcenter_name="sugon", task="jupyter-16555_0"}
0
job_gpu_util{card_type="DCU", container="prometheus-pushgateway", endpoint="prometheus-pushgateway", exported_job="sugon-metrics", instance="10.244.118.50:9091", job="prometheus-pushgateway", job_name="jupyter-16556", job_type="jupyter", namespace="monitoring", pod="prometheus-pushgateway-7b5f7bb557-wnk7m", service="prometheus-pushgateway", subcenter_name="sugon", task="jupyter-16556_0"}
0
job_gpu_util{card_type="GCU", container="prometheus-pushgateway", endpoint="prometheus-pushgateway", exported_job="suiyuan-metrics", instance="10.244.118.50:9091", job="prometheus-pushgateway", job_name="sheng2023061211t5707969110", job_type="training", namespace="monitoring", pod="prometheus-pushgateway-7b5f7bb557-wnk7m", service="prometheus-pushgateway", subcenter_name="suiyuan", task="sheng2023061211t5707969110-task1-0", user_id="c1a35ae42c044fd6b2a2be3b7a534094"}
0
```

![image-20230616155238456](./image-20230616155238456.png)

2、现在我只想要输出key= ”card_type“ 所有的value值

```
# 我想要的结果，类似下述这种
DCU
DCU
GCU
```

3、使用 label_values(job_gpu_util, card_type)  

![1686901927892](./1686901927892.png)