#!/bin/sh
kill $(cat /tmp/nfqws.pid) 2>/dev/null
sleep 1
ZDIR=/tmp/zapret-v72.13
/tmp/zapret-v72.13/binaries/linux-mipsel/nfqws \
    --qnum=200 --daemon --pidfile=/tmp/nfqws.pid \
    --filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld \
    --dpi-desync-repeats=8 --dpi-desync-fooling=md5sig,badseq \
    --dpi-desync-fake-tls=$ZDIR/files/fake/tls_clienthello_www_google_com.bin \
    --hostlist=/tmp/list-general.txt --hostlist=/tmp/list-google.txt \
    --new --filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6 \
    --dpi-desync-fake-quic=$ZDIR/files/fake/quic_initial_rr1---sn-xguxaxjvh-n8me_googlevideo_com_kyber_1.bin \
    --hostlist=/tmp/list-general.txt --hostlist=/tmp/list-google.txt
