https://blog.csdn.net/sinat_32582203/article/details/128727107

了解了上述一些技术背景后，现在我们来回溯本次故障发生的过程。

Prometheus A网络恢复后，开始重传中断期间发送失败的数据，且由于数据量较大，Prometheus自动增大了远程写的并发数；

由于数据too old，Thanos拒绝了这些数据，并返回4XX报错；

Prometheus A接收到4XX报错，认为发送失败但远端并无问题，所以再次重传；

上述过程反复重复，造成Thanos distributor及receive大量报错并发生拥塞，liveness健康检查失败，并造成pod反复重启；

由于Thanos distributor及receive的反复崩溃重启，造成中心的Thanos系统无法正常接收各个区域Prometheus的远程写，因为所有区域的Prometheus均进行了重写，Thanos端压力进一步增加，引起雪崩；

Prometheus端的反复重写造成的系统网络流量、内存、CPU负载的急剧升高，引发的OOM问题，也是本次故障的重要表征：

原文链接：https://blog.csdn.net/sinat_32582203/article/details/128727107