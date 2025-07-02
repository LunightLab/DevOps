#!/bin/bash
# InfluxDB + Telegraf 자동 설정 스크립트

echo "🔧 InfluxDB + Telegraf 설정 시작..."

# 1. InfluxDB 설치
echo "📦 InfluxDB 설치 중..."
brew install influxdb
brew services start influxdb

sleep 10

# 2. 데이터베이스 및 사용자 생성
echo "👤 InfluxDB 사용자 및 데이터베이스 생성..."
influx -execute "CREATE USER admin WITH PASSWORD 'admin123' WITH ALL PRIVILEGES"
influx -execute "CREATE DATABASE telegraf"
influx -execute "CREATE USER grafana WITH PASSWORD 'grafana123'"
influx -execute "GRANT ALL ON telegraf TO grafana"

# 3. Telegraf 설치
echo "📊 Telegraf 설치 중..."
brew install telegraf

# 4. Telegraf 설정 파일 생성
echo "⚙️ Telegraf 설정 생성..."
cat > /opt/homebrew/etc/telegraf.conf << 'EOF'
[global_tags]
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false

[[outputs.influxdb]]
  urls = ["http://localhost:8086"]
  database = "telegraf"
  username = "grafana"
  password = "grafana123"

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.mem]]

[[inputs.net]]

[[inputs.system]]

[[inputs.processes]]

[[inputs.swap]]
EOF

# 5. Telegraf 시작
echo "🚀 Telegraf 시작..."
brew services start telegraf

sleep 15

# 6. 확인
echo "✅ 설정 확인 중..."
echo "InfluxDB 상태: $(brew services list | grep influxdb | awk '{print $2}')"
echo "Telegraf 상태: $(brew services list | grep telegraf | awk '{print $2}')"

# 7. 데이터 확인
echo "📊 데이터 수집 확인..."
influx -username grafana -password grafana123 -database telegraf -execute "SHOW MEASUREMENTS"

echo ""
echo "✅ InfluxDB + Telegraf 설정 완료!"
echo ""
echo "📋 Grafana 데이터소스 설정:"
echo "  URL: http://localhost:8086"
echo "  Database: telegraf"
echo "  User: grafana"
echo "  Password: grafana123"
echo ""
echo "🎯 이제 Dashboard 12918을 Import 하세요!"