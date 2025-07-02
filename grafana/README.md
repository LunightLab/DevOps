
## 환경
- 목표: Telegraf + InfluxDB v2 + Grafana로 시스템 모니터링
- 참고 블로그: https://blog.devgenius.io/monitor-temperatures-with-telegraf-on-macos-4a0eae03549d
- 대시보드 템플릿: https://grafana.com/grafana/dashboards/12918-macos-host/


## install 
```sh
# install
brew install telegraf influxdb grafana

# version
influx version
Influx CLI 2.7.5 (git: a79a2a1b82) build_date: 2024-04-16T14:32:10Z
```

## Telegraf config
```sh
vi /opt/homebrew/etc/telegraf/telegraf.conf
```

## 주요 설정
- InfluxDB v2 출력 설정
- 기본 시스템 메트릭 (CPU, Memory, Disk, Network, Docker)
- macOS 전용 메트릭 (온도, 배터리) - 문제로 인해 비활성화


## influxDB DB 설정

- 계정, 조직정보, bucket 설정, Token 설정

    http:// localhost:8086

## Grafana 설정

## 데이터소스 추가

Type: InfluxDB
URL: http://localhost:8086
Query Language: Flux (중요!)
Organization: XX
Token: InfluxDB에서 생성한 토큰
Default Bucket: telegraf

## 대시보드 Import

Dashboard ID: 12918 (macOS Host)
Data Source: 방금 생성한 InfluxDB 선택

## 🐛 host 수정
Variables 설정 문제

원인: 대시보드의 host 변수가 InfluxQL 쿼리 사용  
해결: Variables → host 변수 수정  
```
from(bucket: "telegraf")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> distinct(column: "host")
  |> keep(columns: ["host"])
```

## 🐛 템플릿 수정

### Average load per CPU
- **시스템 부하(load average)** 를 CPU 개수로 나눈 값
- load1 = 1분 평균 부하
- n_cpus = CPU 코어 개수
- 결과 = 각 CPU 코어당 평균 부하
- 0.0 ~ 1.0: 정상 (각 코어가 충분히 여유 있음)
- 1.0 이상: 부하가 높음 (대기 중인 작업들이 있음)
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "system")
  |> filter(fn: (r) => r["_field"] == "load1" or r["_field"] == "n_cpus")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> map(fn: (r) => ({ r with _value: r.load1 / r.n_cpus }))
  |> keep(columns: ["_time", "_value"])
```

### CPU 사용율
```c
from(bucket: "telegraf")
  |> range(start: -5m)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_idle")
  |> filter(fn: (r) => r["host"] == "mobiles-Mac-Studio.local")
  |> aggregateWindow(every: 30s, fn: mean, createEmpty: false)
  |> map(fn: (r) => ({ r with _value: 100.0 - r._value }))
```

### 메모리 사용
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "mem")
  |> filter(fn: (r) => r["_field"] == "used" or r["_field"] == "available" or r["_field"] == "free")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)0
```

### Netcork Connections
- 측정값: netstat (네트워크 통계)
- 필드: tcp_established (확립된 TCP 연결 수)
- 결과: 현재 활성 TCP 연결 개수
- 높은 값: 많은 네트워크 연결 활성화 (웹브라우저, 앱들이 바쁨)
- 낮은 값: 네트워크 활동 적음
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "netstat")
  |> filter(fn: (r) => r["_field"] == "tcp_established")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

### Network
- 측정값: net (네트워크 인터페이스)
- 필드: bytes_recv (받은 바이트)
- 인터페이스 필터: != "lo0" (루프백 제외)
- derivative: 초당 변화율 계산
- nonNegative: 음수 값 제거
- 실시간 다운로드 속도 (bytes/sec)
- KB/s, MB/s 단위로 표시 가능
- 실제 네트워크 활동량 확인
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "net")
  |> filter(fn: (r) => r["_field"] == "bytes_recv")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> filter(fn: (r) => r["interface"] != "lo0")
  |> derivative(unit: 1s, nonNegative: true)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

### Disk
- Disk Writes (쓰기)  
- Disk Reads (읽기)
- 디스크 사용량

```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "diskio")
  |> filter(fn: (r) => r["_field"] == "writes")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> derivative(unit: 1s, nonNegative: true)
  |> aggregateWindow(every: v.windowPeriod, fn: sum, createEmpty: false)

from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "diskio")
  |> filter(fn: (r) => r["_field"] == "reads")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> derivative(unit: 1s, nonNegative: true)
  |> aggregateWindow(every: v.windowPeriod, fn: sum, createEmpty: false)

from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "disk")
  |> filter(fn: (r) => r["_field"] == "used_percent")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> filter(fn: (r) => r["path"] == "/")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)

```

### Disk 사용량
- 측정값: disk (디스크 공간)
- 필드: used_percent (사용률 %)
- 경로: "/" (루트 디렉토리 = 주 디스크)
- 결과: 0-100% 디스크 사용률
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "disk")
  |> filter(fn: (r) => r["_field"] == "used_percent")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> filter(fn: (r) => r["path"] == "/")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

### Process CPU Used Top 10
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "procstat")
  |> filter(fn: (r) => r["_field"] == "cpu_usage")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> group(columns: ["process_name"])
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 10)
```

### Process MEM Used Top 10
```c
from(bucket: "telegraf")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "procstat")
  |> filter(fn: (r) => r["_field"] == "memory_rss")
  |> filter(fn: (r) => r["host"] =~ /^${host}$/)
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> group(columns: ["process_name"])
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 10)
```

### 확인할 명령어
```sh
# 서비스 상태 확인
brew services list | grep -E "(telegraf|influxdb|grafana)"

# 설정 테스트
telegraf --config /opt/homebrew/etc/telegraf/telegraf.conf --test

# 데이터 확인
influx query 'from(bucket:"telegraf") |> range(start: -5m) |> limit(n: 5)'

#cli 생성
influx config create \
  --config-name cli \
  --host-url http://localhost:8086 \
  --org nh \
  --token v7an8jZh0fgo0dSJawlj78FgBq8Gvk1UHLsKoPO2dP1Xg3p69wi8Ed2JImn7K8xXECCjsnTL2ZRkEcFOrozs6Q== \
  --active

# list 확인
influx bucket list
```

### telegraf bucket이 30일간만 데이터를 보관
```c
# 1. Bucket 목록 확인
influx bucket list

# 결과 예시:
# ID                      Name        Retention   Shard group duration    Organization ID
# 0123456789abcdef        telegraf    infinite    168h0m0s                orgid123

# 2. 해당 ID로 업데이트
influx bucket update \
  --id eceb87761880c385 \
  --retention 30d
```
