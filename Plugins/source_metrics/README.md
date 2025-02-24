# Source Metrics

Monitors server performance and sends the data to [Prometheus Aggregation Gateway](https://github.com/zapier/prom-aggregation-gateway).

As of v0.9.0, Prometheus Aggregation Gateway will always add up input metrics (even gauges), so all types are labeled as counters.
