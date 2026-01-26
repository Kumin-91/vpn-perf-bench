#!/bin/bash

# [1. 환경 설정 및 변수]
# ---------------------------------------------------------
SSH_KEY_PATH="PATH_TO_PEM_FILE"
EC2_USER="ec2-user"
EC2_IP="xxx.xxx.xxx.xxx"

# VPN 경로 (EC2 기준)
OVPN_CONF="/home/ec2-user/openvpn/client.ovpn"
WG_CONF="/home/ec2-user/wireguard/client.conf"

# VPN 내부 IP (서버 주소)
OVPN_SERVER_IP="10.8.0.1"
WG_SERVER_IP="10.0.0.1"

# 실험 옵션
TEST_DURATION=60
STABILIZE_TIME=20
# ---------------------------------------------------------

echo "### [1/5] 홈서버 인프라 가동 (Docker Compose) ###"
docker-compose up -d 
echo ">> 인프라 안정화 대기 ($STABILIZE_TIME초)..."
sleep $STABILIZE_TIME

# ---------------------------------------------------------
echo "### [2/5] OpenVPN 실험 (Start -> Test -> Stop) ###"

# 1. EC2에서 OpenVPN 기동
echo ">> [Remote] OpenVPN 터널 생성 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "sudo openvpn --config $OVPN_CONF --daemon"
sleep 10 # 터널 형성 대기

# 2. iperf3 측정 (Hub 서버 실행 -> EC2 부하 생성)
docker exec -d openvpn-node iperf3 -s
echo ">> [Remote] OpenVPN Throughput 측정 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "iperf3 -c $OVPN_SERVER_IP -t $TEST_DURATION -i 1 --forceflush"

# 3. MTR 측정 (EC2 -> Hub 경로 분석)
echo ">> [Remote] OpenVPN MTR 경로 분석 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "mtr --report --report-cycles 10 $OVPN_SERVER_IP"

# 4. 정리 (EC2 VPN 종료 및 Hub iperf3 종료)
echo ">> [Remote] OpenVPN 터널 해제 및 정리..."
ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "sudo pkill openvpn"
docker exec openvpn-node pkill iperf3
sleep $STABILIZE_TIME

# ---------------------------------------------------------
echo "### [3/5] Wireguard 실험 (Start -> Test -> Stop) ###"

# 1. EC2에서 Wireguard 기동
echo ">> [Remote] Wireguard 터널 생성 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "sudo wg-quick up $WG_CONF"
sleep 5

# 2. iperf3 측정 (Hub 서버 실행 -> EC2 부하 생성)
docker exec -d wireguard-node iperf3 -s
echo ">> [Remote] Wireguard Throughput 측정 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "iperf3 -c $WG_SERVER_IP -t $TEST_DURATION -i 1 --forceflush"

# 3. MTR 측정 (EC2 -> Hub 경로 분석)
echo ">> [Remote] Wireguard MTR 경로 분석 중..."
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" \
    "mtr --report --report-cycles 10 $WG_SERVER_IP" 

# 4. 정리 (EC2 VPN 종료 및 Hub iperf3 종료)
echo ">> [Remote] Wireguard 터널 해제 및 정리..."
ssh -i "$SSH_KEY_PATH" "$EC2_USER@$EC2_IP" "sudo wg-quick down $WG_CONF"
docker exec wireguard-node pkill iperf3
sleep $STABILIZE_TIME

# ---------------------------------------------------------
echo "### [4/5] 환경 정리 및 데이터 마감 ###"
echo ">> 지표 전송 대기 후 Docker 종료..."
sleep 20
docker-compose down 

echo "### [5/5] 모든 실험 완료! 결과를 확인하세요. ###"