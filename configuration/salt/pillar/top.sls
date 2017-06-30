base:
  '*':
    - saltmine
    - collectd
    - postgres
    - rabbitmq
    - influxdb 
    - dnsmasq
  'G@roles:worker':
    - test-data
    - run-tracking-db
    - airflow
  'G@roles:tracker':
    - run-tracking-db
    - airflow
  'G@roles:monitoring-server':
    - grafana
  'G@roles:db-server':
    - grafana
    - run-tracking-db
