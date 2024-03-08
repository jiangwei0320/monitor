## Prometheus 高可用解决方案thanos、cortex

http://www.endwei.com/post/thanos+more+prometheus.html

https://yuerblog.cc/2021/03/01/%E5%9F%BA%E4%BA%8Ethanos%E6%90%AD%E5%BB%BA%E5%88%86%E5%B8%83%E5%BC%8Fprometheus/#google_vignette

前言：

thanos query ：查询模块

thanos sidecar ：读取prometheus采集指标数据并存储到[对象存储](https://so.csdn.net/so/search?q=对象存储&spm=1001.2101.3001.7020)的模块

thanos receive ：接收prometheus数据并存储到对象存储的模块

thanos store ：连接对象存储并提供查询的模块

#### thanos两种部署方式

#### 1.Sidecar 方式部署:

```
# 需要将thanos和promethes部署在一个服务器上，或者是可以共享prometheus的数据目录（可通过nfs共享）
```



#### 2.Receiver 方式部署：

```
# 使用remote write会增加prometheus的内存占用，大多数情况内存使用量会增加约25%。也取决于指标数据的类型和大小。
# 对于WAL中的每个时许，远程写入大妈缓存序列ID到标签值得映射，大量序列将显著增加内存使用量；
https://prometheus.io/docs/practices/remote_write/
```

```

```



