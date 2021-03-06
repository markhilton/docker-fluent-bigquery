# Docker Fluentd for Google BigQuery
This container exposes default Fluentd forwarding port 24224 for log ingestion, to parse Nginx & PHP logs into Google BigQuery tables.

BigQuery can be set as datafeed for Google Data Studio to create Business Intelligence Logs Dashboard.

## How to deploy
1. Build Fluentd container
2. Deploy container on VM authorized to stream to Google BigQuery
3. Set up Nginx, PHP containers to forward logs to Fluentd

docker-compose.yml example
```
    logging:
      driver: "fluentd"
      options:
        fluentd-address: ip_address_of_fluentd:24224
        tag: your_tag_name
```

## Features
Parsed Nginx access logs to support:
- GeoIP map rendering
- User Browser Agent parsing

## Nginx required log format
In order to properly parse Nginx access logs the log_format needs to be set up to following json output.

```
log_format json '{ '
    '"time": "$time_local", '
    '"remote_addr": "$remote_addr", '
    '"remote_user": "$remote_user", '
    '"request_url": "$request", '
    '"request_time": "$request_time", '
    '"response_status": "$status", '
    '"response_size": "$body_bytes_sent", '
    '"referrer": "$http_referer", '
    '"agent": "$http_user_agent", '
    '"forwarded_for": "$http_x_forwarded_for", '
    '"host": "$host" '
'}';
```
