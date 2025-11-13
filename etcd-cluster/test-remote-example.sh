#!/bin/bash

# Example: Testing Remote etcd Cluster
# This script demonstrates how to test a remote etcd cluster (e.g., Zeabur deployment)

# ==========================================
# Example 1: Test Zeabur deployment
# ==========================================
echo "Example 1: Testing Zeabur deployment"
echo "-------------------------------------"
echo ""
echo "ETCD_ENDPOINTS=https://etcd1.example.zeabur.app:2379,https://etcd2.example.zeabur.app:2379,https://etcd3.example.zeabur.app:2379 ./test.sh"
echo ""

# ==========================================
# Example 2: Test with authentication
# ==========================================
echo "Example 2: Testing with authentication"
echo "---------------------------------------"
echo ""
echo "ETCD_ENDPOINTS=https://etcd.example.com:2379 \\"
echo "ETCD_USER=root \\"
echo "ETCD_PASSWORD=secretpassword \\"
echo "./test.sh"
echo ""

# ==========================================
# Example 3: Test single endpoint
# ==========================================
echo "Example 3: Testing single endpoint"
echo "-----------------------------------"
echo ""
echo "ETCD_ENDPOINTS=http://192.168.1.100:2379 ./test.sh"
echo ""

# ==========================================
# Example 4: Test local cluster
# ==========================================
echo "Example 4: Testing local Docker Compose cluster"
echo "------------------------------------------------"
echo ""
echo "./test.sh"
echo ""

# ==========================================
# Instructions
# ==========================================
echo "=========================================="
echo "How to use:"
echo "=========================================="
echo ""
echo "1. Replace the endpoints with your actual etcd cluster URLs"
echo "2. If using HTTPS, make sure your certificates are valid"
echo "3. If using authentication, provide ETCD_USER and ETCD_PASSWORD"
echo "4. Run the test script with the environment variables"
echo ""
echo "Note: You must have etcdctl installed on your system for remote testing"
echo "Install etcdctl: brew install etcd (macOS) or apt install etcd-client (Linux)"
echo ""
