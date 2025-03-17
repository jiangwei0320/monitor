https://github.com/robusta-dev/krr?tab=readme-ov-file#slack-notification

1、下载到本地

```shell
git clone https://github.com/robusta-dev/krr.git
```

2、安装python库

```shell
pip install -r requirements.txt
```

3、运行krr命令，查询指定的ns空间pod详情，如果不指定就是所有pod

```shell
python krr.py simple --namespace=kube-system --prometheus-url=https://www.bitahub.com/prometheus
```

4、查询其他集群，这里默认拿了当前集群的 /root.kube/config文件，如果其他集群，更换config文件，可以指定 --kubeconfig 指定你想要扫描得集群

```shell
 python krr.py simple --help
```

