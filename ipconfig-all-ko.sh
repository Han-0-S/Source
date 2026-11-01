#!/usr/bin/env bash
#
# ipconfig-all-ko.sh
# AD Domain Join 된 Ubuntu 의 네트워크 정보를
# "한국어 Windows 의 ipconfig /all" 형식으로 출력합니다.
#
# 사용법:
#   ./ipconfig-all-ko.sh            # 전체 어댑터
#   ./ipconfig-all-ko.sh ens160     # 특정 어댑터만
#
# 사용하는 정보원(있는 것만 사용, 없으면 자동 대체):
#   realm / sssd.conf / hostname -d   -> 주 DNS 접미사 (AD 도메인)
#   ip, /sys/class/net                -> IP, MAC, 게이트웨이, 링크 상태
#   resolvectl / resolv.conf          -> DNS 서버, 검색 접미사
#   systemd-networkd / NetworkManager / dhclient -> DHCP 서버, 임대 정보

export LC_ALL=C.UTF-8
FILTER="${1:-}"

if [[ "$FILTER" == "-h" || "$FILTER" == "--help" ]]; then
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 출력 포맷터 ----------
# 한글은 터미널에서 2칸을 차지하므로 "표시 폭" 기준으로 ". . ." 정렬
dwidth() {
  local s=$1 c=${#1} b
  b=$(LC_ALL=C; echo ${#s})
  echo $(( c + (b - c) / 2 ))
}
fmt() {
  local s="$1" val="$2" i
  i=$(dwidth "$s")
  while (( i < 34 )); do
    if (( i % 2 == 0 )); then s+="."; else s+=" "; fi
    ((i++))
  done
  printf "   %s: %s\n" "$s" "$val"
}
cont() { printf "%39s%s\n" "" "$1"; }          # 여러 값일 때 이어지는 줄

# 예: 2026년 11월 1일 일요일 오전 9:00:00
fmt_date() {
  local e=$1 w h ap h12
  local days=(일요일 월요일 화요일 수요일 목요일 금요일 토요일)
  w=$(date -d "@$e" +%w)
  h=$(date -d "@$e" +%-H)
  if (( h < 12 )); then ap="오전"; else ap="오후"; fi
  h12=$(( h % 12 )); (( h12 == 0 )) && h12=12
  date -d "@$e" +"%Y년 %-m월 %-d일 ${days[w]} ${ap} ${h12}:%M:%S"
}

yn() { [[ $1 == Yes ]] && echo "예" || echo "아니요"; }

prefix2mask() {
  local p=$1 m="" i
  for i in 0 1 2 3; do
    if   (( p >= 8 )); then m+="255"; p=$((p-8))
    elif (( p >  0 )); then m+=$((256 - (1 << (8-p)))); p=0
    else m+="0"; fi
    (( i < 3 )) && m+="."
  done
  echo "$m"
}

# ---------- 호스트 단위 정보 ----------
get_primary_suffix() {
  local d=""
  if have realm; then
    d=$(realm list 2>/dev/null | awk -F': *' '/^[[:space:]]*domain-name:/ {print $2; exit}')
  fi
  if [[ -z $d && -r /etc/sssd/sssd.conf ]]; then
    d=$(awk -F= '/^[[:space:]]*domains[[:space:]]*=/ {gsub(/[ \t]/,"",$2); split($2,a,","); print a[1]; exit}' /etc/sssd/sssd.conf 2>/dev/null)
  fi
  [[ -z $d ]] && d=$(hostname -d 2>/dev/null)
  echo "${d,,}"
}

HOSTNAME_SHORT=$(hostname -s 2>/dev/null || hostname)
PRIMARY=$(get_primary_suffix)

# resolv.conf (systemd-resolved stub 이면 실제 upstream 파일 사용)
RESOLV=/etc/resolv.conf
if grep -q '^nameserver 127\.0\.0\.53' /etc/resolv.conf 2>/dev/null \
   && [[ -r /run/systemd/resolve/resolv.conf ]]; then
  RESOLV=/run/systemd/resolve/resolv.conf
fi

ip_forward=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
[[ $ip_forward == 1 ]] && ROUTING="예" || ROUTING="아니요"

if systemctl is-active --quiet nmbd 2>/dev/null; then NETBIOS="사용"; else NETBIOS="사용 안 함"; fi

SEARCH_LIST=$( { [[ -n $PRIMARY ]] && echo "$PRIMARY"
                 awk '/^(search|domain)/ {for(i=2;i<=NF;i++) print $i}' "$RESOLV" 2>/dev/null
               } | awk 'NF && !seen[$0]++' )

# ---------- 어댑터 단위 헬퍼 ----------
get_dns() {
  local ifc=$1 out=""
  if have resolvectl; then
    out=$(resolvectl dns "$ifc" 2>/dev/null | sed 's/^[^:]*: *//' | tr ' ' '\n' | sed 's/[#%].*//' | sed '/^$/d')
  fi
  [[ -z $out ]] && out=$(awk '/^nameserver/ {print $2}' "$RESOLV" 2>/dev/null | grep -v '^127\.')
  echo "$out"
}

get_conn_suffix() {
  have resolvectl || return
  resolvectl domain "$1" 2>/dev/null | sed 's/^[^:]*: *//' | tr ' ' '\n' | grep -v '^~' | sed '/^$/d' | head -1
}

nm_opt() {   # nm_opt <ifc> <dhcp option name>
  have nmcli || return
  nmcli -f DHCP4 dev show "$1" 2>/dev/null | awk -v k="$2" '$0 ~ k" = " {print $NF; exit}'
}

get_description() {
  local ifc=$1 vendor model drv
  if have udevadm; then
    vendor=$(udevadm info -q property -p "/sys/class/net/$ifc" 2>/dev/null | sed -n 's/^ID_VENDOR_FROM_DATABASE=//p')
    model=$(udevadm info  -q property -p "/sys/class/net/$ifc" 2>/dev/null | sed -n 's/^ID_MODEL_FROM_DATABASE=//p')
  fi
  if [[ -n $model ]]; then echo "${vendor:+$vendor }$model"; return; fi
  if [[ -L /sys/class/net/$ifc/device/driver ]]; then
    drv=$(basename "$(readlink -f "/sys/class/net/$ifc/device/driver")")
    echo "Ethernet Adapter ($drv)"; return
  fi
  echo "Virtual Ethernet Adapter ($ifc)"
}

# ---------- 헤더 ----------
echo
echo "Windows IP 구성"
echo
fmt "호스트 이름"             "$HOSTNAME_SHORT"
fmt "주 DNS 접미사"           "$PRIMARY"
fmt "노드 유형"               "혼성"
fmt "IP 라우팅 사용"          "$ROUTING"
fmt "WINS 프록시 사용"        "아니요"
first=1
if [[ -n $SEARCH_LIST ]]; then
  while read -r s; do
    if (( first )); then fmt "DNS 접미사 검색 목록" "$s"; first=0; else cont "$s"; fi
  done <<<"$SEARCH_LIST"
else
  fmt "DNS 접미사 검색 목록" ""
fi

# ---------- 어댑터 ----------
NOW=$(date +%s)

while read -r ifc; do
  [[ -z $ifc || $ifc == lo || $ifc == veth* ]] && continue
  [[ -n $FILTER && ${ifc,,} != "${FILTER,,}" ]] && continue

  sysdir=/sys/class/net/$ifc
  idx=$(cat "$sysdir/ifindex" 2>/dev/null)
  mac=$(cat "$sysdir/address" 2>/dev/null | tr 'a-f:' 'A-F-')
  oper=$(cat "$sysdir/operstate" 2>/dev/null)
  type=$(cat "$sysdir/type" 2>/dev/null)

  if   [[ -d $sysdir/wireless ]]; then kind="무선 LAN 어댑터"
  elif [[ $type == 1 ]];          then kind="이더넷 어댑터"
  else                                 kind="터널 어댑터"; fi

  echo
  echo "$kind $ifc:"
  echo

  v4_lines=$(ip -4 -o addr show dev "$ifc" 2>/dev/null)
  v6_lines=$(ip -6 -o addr show dev "$ifc" 2>/dev/null)
  desc=$(get_description "$ifc")

  # DHCP 여부 / 서버 / 임대시간
  dhcp="No"; server=""; lifetime=""; lease_file_mtime=""
  lf=/run/systemd/netif/leases/$idx
  if [[ -r $lf ]]; then
    dhcp="Yes"
    server=$(sed -n 's/^SERVER_ADDRESS=//p' "$lf")
    lifetime=$(sed -n 's/^LIFETIME=//p' "$lf")
    lease_file_mtime=$(stat -c %Y "$lf" 2>/dev/null)
  fi
  if [[ -z $server ]]; then
    server=$(nm_opt "$ifc" dhcp_server_identifier)
    lifetime=${lifetime:-$(nm_opt "$ifc" dhcp_lease_time)}
  fi
  if [[ -z $server ]]; then
    for f in /var/lib/dhcp/dhclient*.leases /var/lib/dhclient/*.leases; do
      [[ -r $f ]] || continue
      server=$(awk -v i="$ifc" '
        /^lease/ {s=""; ok=0}
        /interface/ {t=$0; gsub(/[";]/,"",t); split(t,a," "); if (a[2]==i) ok=1}
        /dhcp-server-identifier/ {t=$3; gsub(/;/,"",t); s=t}
        /^}/ {if (ok) last=s}
        END {print last}' "$f")
      [[ -n $server ]] && break
    done
  fi
  [[ -n $server ]] && dhcp="Yes"
  grep -q dynamic <<<"$v4_lines" && dhcp="Yes"
  pgrep -af "dhclient.* $ifc" >/dev/null 2>&1 && dhcp="Yes"

  # --- 링크 다운 (미디어 연결 끊김) ---
  if [[ $oper == down || $oper == lowerlayerdown ]]; then
    fmt "미디어 상태"         "미디어 연결 끊김"
    fmt "연결별 DNS 접미사"   ""
    fmt "설명"                "$desc"
    fmt "물리적 주소"         "$mac"
    fmt "DHCP 사용"           "$(yn "$dhcp")"
    fmt "자동 구성 사용"      "예"
    continue
  fi

  fmt "연결별 DNS 접미사"   "$(get_conn_suffix "$ifc")"
  fmt "설명"                "$desc"
  fmt "물리적 주소"         "$mac"
  fmt "DHCP 사용"           "$(yn "$dhcp")"
  fmt "자동 구성 사용"      "예"

  # --- IPv6 ---
  while read -r line; do
    [[ -z $line ]] && continue
    addr=$(awk '{print $4}' <<<"$line"); a6=${addr%/*}
    state="기본 설정"
    [[ $line == *tentative* ]]  && state="시험적"
    [[ $line == *deprecated* ]] && state="사용되지 않음"
    if   [[ $line == *"scope link"* ]]; then fmt "링크-로컬 IPv6 주소" "${a6}%${idx}(${state})"
    elif [[ $line == *temporary* ]];    then fmt "임시 IPv6 주소"     "${a6}(${state})"
    else                                     fmt "IPv6 주소"          "${a6}(${state})"; fi
  done <<<"$v6_lines"

  # --- IPv4 ---
  while read -r line; do
    [[ -z $line ]] && continue
    addr=$(awk '{print $4}' <<<"$line")
    a4=${addr%/*}; plen=${addr#*/}
    state="기본 설정"
    [[ $line == *tentative* ]]  && state="시험적"
    [[ $line == *deprecated* ]] && state="사용되지 않음"
    fmt "IPv4 주소"     "${a4}(${state})"
    fmt "서브넷 마스크" "$(prefix2mask "$plen")"

    if [[ $line == *dynamic* ]] && [[ $line =~ valid_lft\ ([0-9]+)sec ]]; then
      expires=$(( NOW + BASH_REMATCH[1] ))
      if   [[ -n $lifetime ]];          then obtained=$(( expires - lifetime ))
      elif [[ -n $lease_file_mtime ]];  then obtained=$lease_file_mtime
      else obtained=""; fi
      fmt "임대 시작 시간" "${obtained:+$(fmt_date "$obtained")}"
      fmt "임대 만료 시간" "$(fmt_date "$expires")"
    fi
  done <<<"$v4_lines"

  # --- 기본 게이트웨이 (IPv6 먼저, 그 다음 IPv4 : Windows 와 동일) ---
  gws=$( { ip -6 route show default dev "$ifc" 2>/dev/null \
             | awk -v i="$idx" '{for(n=1;n<=NF;n++) if($n=="via") print $(n+1) "%" i}'
           ip -4 route show default dev "$ifc" 2>/dev/null \
             | awk '{for(n=1;n<=NF;n++) if($n=="via") print $(n+1)}'
         } | awk '!s[$0]++' )
  first=1
  if [[ -n $gws ]]; then
    while read -r g; do
      if (( first )); then fmt "기본 게이트웨이" "$g"; first=0; else cont "$g"; fi
    done <<<"$gws"
  else
    fmt "기본 게이트웨이" ""
  fi

  # --- DHCP 서버 ---
  [[ $dhcp == Yes && -n $server ]] && fmt "DHCP 서버" "$server"

  # --- DNS 서버 ---
  if [[ -n $v4_lines || -n $v6_lines ]]; then
    dns=$(get_dns "$ifc")
    first=1
    if [[ -n $dns ]]; then
      while read -r d; do
        if (( first )); then fmt "DNS 서버" "$d"; first=0; else cont "$d"; fi
      done <<<"$dns"
    fi
  fi

  fmt "Tcpip를 통한 NetBIOS" "$NETBIOS"
done < <(ip -o link show 2>/dev/null | awk -F': ' '{sub(/@.*/,"",$2); print $2}')

echo
