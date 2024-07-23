##### 1、如何让当前得alertmanager接入promeheus的告警

```
# kubectl edit prometheuses.monitoring.coreos.com -n monitoring k8s 
spec:
  additionalScrapeConfigs:
    key: prometheus-additional.yaml
    name: additional-configs
  alerting:
    alertmanagers:
    - apiVersion: v2
      name: alertmanager-main
      namespace: monitoring
      port: web
```

注：这里选择alertmanager对应的namespace，port是容器的port，可以写portname，也可以实际的端口

##### 2、配置alertmanager的配置文件，一般k8s中为secret，alertmanager.yaml

一般secret中可以写如下配置:

```
apiVersion: v1
data:
  alertmanager.yaml: Imdsb2JhbCI6CiAgInJlc29sdmVfdGltZW91dCI6ICI1bSIKICAic210cF9mcm9tIjogImxlaW5hb19tb25pdG9yQDE2My5jb20iCiAgInNtdHBfc21hcnRob3N0IjogInNtdHAuMTYzLmNvbTo0NjUiCiAgInNtdHBfYX=
  template_email.tmpl: e3sgZGVmaW5lICJlbWFpbC5kZWZhdWx0Lm1lc3NhZ2UiIH19Cnt7LSBpZiBndCAobGVuIC5BbGVydHMuRmlyaW5nKSAwIC19fQp7ey0gcmFuZ2UgJGluZGV4LCAkYWxlcnQgOj0gLkFsZXJ0cyAtfX0Ke3stIGlmIGVx=
  template_wechat.tmpl: e3sgZGVmaW5lICJ3ZWNoYXRfYnVzaW5lc3Muc3RhcnQuaHRtbCIgfX0KICB7eyByYW5nZSAkaSwgJGFsZXJ0IDo9IC5BbGVydHMgfX0KPT09PT09PT09PT09U3RhcnQ9PT09PT09PT09PT0KICAgIFvlkYrorabnirbmgIFd77yae3sgLlN0YXR1cyB9fQogICAgW+WRiuitpumhuV06IHt7IGluZGV4ICRhbGVydC5MYWJlbHMgImFsZ=
```

对应解码后，相当于下述配置，alertmanager.yaml

```
"global":
  "resolve_timeout": "5m"
  "smtp_from": "leinao_monitor@163.com"
  "smtp_smarthost": "smtp.163.com:465"
  "smtp_auth_username": "leinao_monitor@163.com"
  "smtp_auth_password": "PRVVZMHJWMXBYDLE"
  "smtp_require_tls": false
"inhibit_rules":
- "equal":
  - "namespace"
  - "alertname"
  "source_match":
    "severity": "critical"
  "target_match_re":
    "severity": "warning|info"
- "equal":
  - "namespace"
  - "alertname"
  "source_match":
    "severity": "warning"
  "target_match_re":
    "severity": "info"
"receivers":
- "name": "email"
  "email_configs":
  - "to": "devops@leinao.ai"
    "headers":
      "Subject": '{{ if eq .Status "firing" }}【告警】{{ .CommonLabels.alertname }}{{ else }}【告警恢复】{{ .CommonLabels.alertname }}{{ end }}'
    "html": '{{ template "email.default.message" . }}'
    "send_resolved": true
- "name": "wechat"
  "wechat_configs":
  - "to_party": '2'
    "agent_id": '1000007' 
    "api_secret": 'Q4tMnY4M6Tw7VvVkXjeG_NVOSw2wYe1W6n8IdKooKlo' 
    "corp_id": 'ww8c6c642a9aa729db' 
    "send_resolved": true
    "message": '{{ template "wechat_business.html" . }}'
"route":
  "group_by":
  - "namespace"
  "group_interval": "5m"
  "group_wait": "30s"
  "receiver": "email"        #默认没有触发下述route的告警规则，都由这条规则接收；
  "repeat_interval": "12h"
  "routes":
  - "receiver": "wechat"     #如果这里不写match，选择具体路由，那么所有的告警都会从这里也发一份
  - "receiver": "email"
"templates":
- "/etc/alertmanager/config/*.tmpl"
```

###### （1）邮件模板（template_email.tmpl: ），这里在上述配置中主要是引用{{ define "email.default.message" }}，这里面定义的模板名称

<br> 主要是用于页面换行，如果显示在一行，使用<br>

```
{{ define "email.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 }}
========= 监控报警 ========= <br>
告警状态：{{ .Status }} <br>
告警级别：{{ .Labels.severity }} <br>
告警类型：{{ $alert.Labels.alertname }} <br>
故障集群：{{ $alert.Labels.origin_prometheus }} <br>
故障主机: {{ $alert.Labels.instance }} <br>
告警主题: {{ $alert.Annotations.summary }} <br>
告警详情: {{ $alert.Annotations.message }}{{ $alert.Annotations.description}} <br>
触发阀值：{{ .Annotations.value }} <br>
故障时间: {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} <br>
========== end ==========
{{- end }}
{{- end }}
{{- end }}
{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 }}
========= 异常恢复 ========= <br>
告警类型：{{ .Labels.alertname }} <br>
告警状态：{{ .Status }} <br>
告警集群：{{ $alert.Labels.origin_prometheus }} <br>
告警主题: {{ $alert.Annotations.summary }} <br>
告警详情: {{ $alert.Annotations.message }}{{ $alert.Annotations.description}}; <br>
故障时间: {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} <br>
恢复时间: {{ ($alert.EndsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} <br>
{{- if gt (len $alert.Labels.instance) 0 }}
实例信息: {{ $alert.Labels.instance }} <br>
{{- end }}
========== end ========== <br>
{{- end }}
{{- end }}
{{- end }}
{{- end }}
```

###### （2）微信模板（ .tmpl: ）

```
{{ define "wechat_business.start.html" }}
  {{ range $i, $alert := .Alerts }}
============Start============ <br>
    [告警状态]：{{ .Status }} <br>
    [告警项]: {{ index $alert.Labels "alert_name" }} <br>
    [集群]：{{ index $alert.Labels "cluster" }} <br>
    [接口]：{{ index $alert.Labels "interface" }} <br>
    [摘要信息]：{{ index $alert.Annotations "value" }} <br>
    [开始时间]：{{ .StartsAt.Format "2006-01-02 15:04:05" }} <br>
============End============= <br>
  {{ end }}
{{ end }}
{{ define "wechat_business.restore.html" }}
  {{ range $i, $alert := .Alerts }}
============Start============ <br>
    [告警状态]：{{ .Status }}
    [告警项]: {{ index $alert.Labels "alert_name" }} <br>
    [集群]：{{ index $alert.Labels "cluster" }} <br>
    [接口]：{{ index $alert.Labels "interface" }} <br>
    [摘要信息]：{{ index $alert.Annotations "value" }} <br>
    [恢复时间]：{{ .EndsAt.Format "2006-01-02 15:04:05" }} <br>
============End============= <br>
  {{ end }}
{{ end }}
{{ define "wechat_business.html" }}
  {{ if eq .Status "firing"}}{{ template "wechat_business.start.html" . }}
  {{ end }}
  {{ if eq .Status "resolved" }}{{ template "wechat_business.restore.html" . }}
  {{ end }}
{{ end }}
```

