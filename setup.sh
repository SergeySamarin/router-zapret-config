#!/bin/sh
# router-zapret-config: idempotent setup/reapply script

ZDIR=/tmp/zapret-v72.13
REPO_RAW=https://raw.githubusercontent.com/SergeySamarin/router-zapret-config/main
BIN=$ZDIR/binaries/linux-mipsel/nfqws

# --- wait for network, a few tries ---
i=0
while [ $i -lt 10 ]; do
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && break
    sleep 2
    i=$((i+1))
done

# --- download zapret binaries if not present ---
if [ ! -x "$BIN" ]; then
    wget -q https://github.com/bol-van/zapret/releases/download/v72.13/zapret-v72.13-openwrt-embedded.tar.gz -O /tmp/zapret.tar.gz
    tar -zxf /tmp/zapret.tar.gz -C /tmp
    rm -f /tmp/zapret.tar.gz
fi

# --- always refresh domain lists from your repo ---
wget -q "$REPO_RAW/lists/list-general.txt" -O /tmp/list-general.txt
wget -q "$REPO_RAW/lists/list-google.txt" -O /tmp/list-google.txt

# --- ensure iptables rules present (idempotent) ---
iptables -C FORWARD -p tcp --dport 443 -j NFQUEUE --queue-num 200 --queue-bypass 2>/dev/null || \
iptables -I FORWARD -p tcp --dport 443 -j NFQUEUE --queue-num 200 --queue-bypass

iptables -C FORWARD -p udp --dport 443 -j NFQUEUE --queue-num 200 --queue-bypass 2>/dev/null || \
iptables -I FORWARD -p udp --dport 443 -j NFQUEUE --queue-num 200 --queue-bypass

# --- start nfqws only if not already running ---
if [ -f /tmp/nfqws.pid ] && kill -0 "$(cat /tmp/nfqws.pid)" 2>/dev/null; then
    exit 0
fi

"$BIN" --qnum=200 --daemon --pidfile=/tmp/nfqws.pid \
    --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld \
    --dpi-desync-fooling=badseq,md5sig \
    --dpi-desync-fake-tls=$ZDIR/files/fake/tls_clienthello_www_google_com.bin \
    --hostlist=/tmp/list-general.txt --hostlist=/tmp/list-google.txt \
    --new --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6 \
    --dpi-desync-fake-quic=$ZDIR/files/fake/quic_initial_rr1---sn-xguxaxjvh-n8me_googlevideo_com_kyber_1.bin \
    --hostlist=/tmp/list-general.txt --hostlist=/tmp/list-google.txt
