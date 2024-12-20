## Grafana, Prometheous를 이용한 jenkins 시스템 모니터링

### Grafana
- 매트릭 데이터를 시각화하는데 최적화된 대시보드를 제공해주는 **Data Visualization Tool**
- [Grafana](https://grafana.com/products/cloud/?src=ggl-s&mdm=cpc&camp=b-grafana-exac-apac-kr&cnt=155360829050&trm=%EA%B7%B8%EB%9D%BC%ED%8C%8C%EB%82%98&device=c&gad_source=1&gclid=CjwKCAiA34S7BhAtEiwACZzv4cgT2l38YvlXnavbMQi9EnGyXiHwQ-3psPF_G7IhbK2KBzePismmJhoCS4YQAvD_BwE)
- [GrafanaLabs](https://grafana.com/grafana/dashboards/?search=jenkins)

### Prometheous
- 시스템 및 서비스 상태를 모니터링하는 **Monitorring Tool**
- [Prometheus](https://prometheus.io/) 

----------------------------------------------------------

#### 1. Grafana 설치
```
$ brew install grafana
```

#### 2. Grafana 접속
- 초기계정 (admin / admin)

#### 3. jenkins prometheus metrics 플러그인 설치
- 플러그인 검색해서 설치

#### 4. Prometheus 설치
```
$ brew install prometheus
```

#### 5. Prometheus config 설정
- /usr/local/etc/prometheus.yml

- prometheus.yml

    ```yml
    global:
        scrape_interval: 15s
    
    scrape_configs:

        # jenkins 서버의 고유한 이름(Grafana에서 대시보드 설정할 때 메트릭 구분)
        - job_name: 'jenkins-175'
        # Jenkins Prometheus 플러그인의 메트릭 경로
        metrics_path: '/prometheus'
        # 첫 번째 Jenkins 서버
        static_configs:
        - targets: ['10.88.20.175:8080']

        - job_name: 'jenkins-174'
        # 동일한 메트릭 경로
        metrics_path: '/prometheus'
        static_configs:
        # 두 번째 Jenkins 서버
        - targets: ['10.88.20.174:8081']  

    ```