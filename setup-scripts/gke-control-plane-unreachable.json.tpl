{
  "displayName": "GKE Control Plane Unreachable",
  "enabled": true,
  "combiner": "OR",
  "notificationChannels": [
    "${TPL_NOTIFICATION_CHANNEL}"
  ],
  "conditions": [
    {
      "displayName": "API Server Unreachable",
      "conditionAbsent": {
        "duration": "120s",
        "filter": "metric.type=\"prometheus.googleapis.com/apiserver_request_total/counter\" AND resource.type=\"prometheus_target\" AND resource.labels.cluster=\"${TPL_CLUSTER_NAME}\"",
        "trigger": {
          "count": 1
        },
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ]
      }
    }
  ]
}
