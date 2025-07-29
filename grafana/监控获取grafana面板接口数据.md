直接页面将post请求参数薅过来

```shell
 curl -X POST http://10.0.100.202:33000/api/ds/query   -u admin:admin   -H "Content-Type: application/json"   -d '{
	"queries": [{
		"datasource": {
			"uid": "P1809F7CD0C75ACF3",
			"type": "prometheus"
		},
		"exemplar": true,
		"expr": "(probe_success == 0 and probe_http_status_code >= 400) or probe_http_status_code",
		"interval": "",
		"legendFormat": "",
		"refId": "A",
		"queryType": "timeSeriesQuery",
		"requestId": "2A",
		"utcOffsetSec": 28800,
		"datasourceId": 1,
		"intervalMs": 15000,
		"maxDataPoints": 1360
	}],
	"range": {
		"from": "2025-06-04T09:35:58.161Z",
		"to": "2025-06-04T09:50:58.161Z",
		"raw": {
			"from": "now-15m",
			"to": "now"
		}
	},
	"from": "1749029758161",
	"to": "1749030658161"
}'
```

