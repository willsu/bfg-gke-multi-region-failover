{
  "displayName": "GKE Control Plane ${TPL_CLUSTER_NAME} Unreachable",
  "enabled": true,
  "combiner": "OR",
  "notificationChannels": [
    "${TPL_NOTIFICATION_CHANNEL}"
  ],
  "severity": "CRITICAL",
  "conditions": [
    {
      "displayName": "GKE metric stream has stopped (PromQL)",
      "conditionPrometheusQueryLanguage": {
        "query": "(count(rate(apiserver_request_total{cluster=\"${TPL_CLUSTER_NAME}\"}[1m])) or vector(0)) < 1",
        "duration": "0s",
        "evaluationInterval": "30s",
        "alertRule": "GKEClusterUnreachable"
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "86400s",
    "notificationPrompts": [
      "OPENED",
    ]
  }
}
