# 공통 베이스 이미지
FROM debian:trixie-slim

# 필요한 패키지 설치 (iptables, tcpdump 추가)
RUN apt-get update && apt-get install -y \
    iperf3 \
    mtr-tiny \
    wireguard-tools \
    iproute2 \
    iptables \
    tcpdump \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# VPN 설정 파일들이 들어갈 디렉토리 준비
WORKDIR /etc/vpn-test

# 실행 시 특정 포트 노출 (iperf3: 5201, Wireguard: 51820)
EXPOSE 5201 51820/udp

# 실행 시 wg0.config를 명시적으로 로드하고 MTU를 조정하며 상태를 출력함
CMD sh -c "\
    wg-quick up ./wg0.conf && \
    echo '[WireGuard] Interface wg0 is UP with MTU 1420' && \
    wg show && \
    tail -f /dev/null"