#### prometheus 常用函数相关

##### 1、rate()函数：取一段时间增量的平均每秒数量，采集很细致的情况下使用

rate( "counter类型数据" ) 函数、是专门搭配counter类型数据使用的函数

它的功能是按照设置一个时间段，取counter在这个时间段中的平均**每秒**的增量

```
# 这个例子使用的node_network_receive_bytes_total 本身是一个counter类型，字面意思也很好理解，网络接受字节数
rate(node_network_receive_bytes_total[1m]) #取的是1分钟内的增量/60秒，每秒增量
# 一般rate()函数使用场景例如cpu、内存、硬盘、IO网络流量
```

**注：只要操作的数据是counter类型数据，永远记住，别的先不做，先给他加上一个rate() 或者increase()函数**

##### 2、increase() 函数：取一段时间增量的总量

```
increase(node_network_receive_bytes_total[1m])  # 1分钟内的增量总量，同一时间，用这个值除以60，会发现等于rate获取的值；
```

##### 3、sum()函数 ：输出的结果集取合，一般于 by() 结合使用

##### 4、topk()函数：获取结果集前几位最高的值

```
# gauge类型、counter类型数据都可以使用
# topk(3,rate(node_network_receive_bytes_total[1m]))  取出1分钟内每秒流量增量的前三个最高值
# topk(3,node_cpu_seconds_total) 取出当前结果前三个最高值
```

注：实际使用topk() 通常是进行瞬时报警

##### 5、count() 函数：找出数值符合条件的，输出数目进行加合

```
# 找出当前（或者历史）当TCP大于 200机器数量
  count(count_netstat_wait_connections> 200)
```

注： 一般通过 count() 函数进行模糊判断。

比如企业中有100台服务器，当有10台服务器CPU高于80%时候，不需要报警，但是当有30台超过80%的时候，这个时候需要触发告警

##### 6、`avg` 函数会计算这段时间内所有数据点的平均值，并返回一个单值时间序列。

```
avg(http_requests_total{job="example"})
这将返回 job 标签为 "example" 的所有 http_requests_total 时间序列数据在查询的时间范围内的平均值。
```



#### 示例：如何计算单位时间内cpu的负载

##### 1、获取当前集群cpu负载详细信息

```
node_cpu_seconds_total  # 获取当前监控平台所有服务器，服务器每个cpu的负载情况
```

##### 2、获取当前集群cpu空闲时间

```
node_cpu_seconds_total{mode="idle"}         # mode="idle"是cpu空闲时间
node_cpu_seconds_total{mode="idle"}[1m]     # 集群1分钟cpu空闲时间
```

##### 3、increase函数，获取单位时间内cpu的增量

```
increase(node_cpu_seconds_total{mode="idle"}[1m])   #单个cpu在1分钟时间内的增量
```

##### 4、sum函数求和，上述统计的都是服务器每个cpu的负载，我们将每台服务器的cpu负载求和，这样就可以获取这台服务器的cpu负载信息

```
sum(increase(node_cpu_seconds_total{mode="idle"}[1m]))   # 这里可以看到并不是我们想要的结果，所有服务器的cpu时间都累加了
sum(increase(node_cpu_seconds_total{mode="idle"}[1m])) by(instance)  # 使用by(instance)区分不同主机，注意这里的instance是cpu负载中包含的，类似于”mode=idle“，也可使用 by(node)等，根据实际情况
```

##### 5、计算当前集群一段时间内cpu负载（减去空闲时间，获得cpu使用时间）

```
(1-((sum(increase(node_cpu_seconds_total{mode="idle"}[1m])) by (instance))  /
(sum(increase(node_cpu_seconds_total[1m])) by (instance)))) * 100
```

##### 6、使用 “>” , "<" 等符号，可以过滤查询结果

```
sum(increase(node_cpu_seconds_total{mode="idle"}[1m])) < 1000
sum(increase(node_cpu_seconds_total{mode="idle"}[1m])) > 1000
```

