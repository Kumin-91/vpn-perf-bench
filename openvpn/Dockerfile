# 공통 베이스 이미지
FROM debian:trixie-slim

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    iperf3 \
    mtr-tiny \
    openvpn \
    iproute2 \
    iptables \
    tcpdump \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# VPN 설정 파일들이 들어갈 디렉토리 준비
WORKDIR /etc/vpn-test

# 실행 시 특정 포트 노출 (iperf3: 5201, OpenVPN: 1194)
EXPOSE 5201 1194/udp

# 실행 시 server.conf를 로드하고 로그를 표준 출력으로 유지
CMD ["openvpn", "--config", "server.conf"]