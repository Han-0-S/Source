#!/usr/bin/env bash
#
# ipconfig-all.sh
# AD Domain Join 된 Ubuntu 의 네트워크 정보를 Windows "ipconfig /all" 형식으로 출력합니다.
#
# 사용법:
#   ./ipconfig-all.sh            # 전체 어댑터
#   ./ipconfig-all.sh ens160     # 특정 어댑터만
#
# 사용하는 정보원(있는 것만 사용, 없으면 자동 대체):
#   realm / sssd.conf / hostname -d   -> Primary DNS Suffix (AD 도메인)
#   ip, /sys/class/net                -> IP, MAC, 게이트웨이, 링크 상태
#   resolvectl / resolv.conf          -> DNS 서버, 검색 접미사
#   systemd-networkd / NetworkManager / dhclient -> DHCP 서버, 임대 정보

export LC_ALL=C
FILTER="${1:-}"

if [[ "$FILTER" == "-h" || "$FILTER" == "--help" ]]; then
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 출력 포맷터 (Windows 스타일 ". . . :" 정렬) ----------
fmt() {
  local s="$1" val="$2" i=${#1}
  while (( i < 34 )); do
    if (( i % 2 == 0 )); then s+="."; else s+=" "; fi
    ((i++))
  done
  printf "   %s: %s\n" "$s" "$val"
}
cont() { printf "%39s%s\n" "" "$1"; }          # 여러 값일 때 이어지는 줄
fmt_date() { date -d "@$1" +"%A, %B %-d, %Y %-I:%M:%S %p"; }

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
[[ $ip_forward == 1 ]] && ROUTING="Yes" || ROUTING="No"

if systemctl is-active --quiet nmbd 2>/dev/null; then NETBIOS="Enabled"; else NETBIOS="Disabled"; fi

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
echo "Windows IP Configuration"
echo
fmt "Host Name"              "$HOSTNAME_SHORT"
fmt "Primary Dns Suffix "    "$PRIMARY"
fmt "Node Type"              "Hybrid"
fmt "IP Routing Enabled"     "$ROUTING"
fmt "WINS Proxy Enabled"     "No"
first=1
if [[ -n $SEARCH_LIST ]]; then
  while read -r s; do
    if (( first )); then fmt "DNS Suffix Search List" "$s"; first=0; else cont "$s"; fi
  done <<<"$SEARCH_LIST"
else
  fmt "DNS Suffix Search List" ""
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

  if   [[ -d $sysdir/wireless ]]; then kind="Wireless LAN adapter"
  elif [[ $type == 1 ]];          then kind="Ethernet adapter"
  else                                 kind="Tunnel adapter"; fi

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

  # --- 링크 다운 (Media disconnected) ---
  if [[ $oper == down || $oper == lowerlayerdown ]]; then
    fmt "Media State "                    "Media disconnected"
    fmt "Connection-specific DNS Suffix " ""
    fmt "Description"                     "$desc"
    fmt "Physical Address"                "$mac"
    fmt "DHCP Enabled"                    "${dhcp}"
    fmt "Autoconfiguration Enabled"       "Yes"
    continue
  fi

  fmt "Connection-specific DNS Suffix " "$(get_conn_suffix "$ifc")"
  fmt "Description"                     "$desc"
  fmt "Physical Address"                "$mac"
  fmt "DHCP Enabled"                    "$dhcp"
  fmt "Autoconfiguration Enabled"       "Yes"

  # --- IPv6 ---
  while read -r line; do
    [[ -z $line ]] && continue
    addr=$(awk '{print $4}' <<<"$line"); a6=${addr%/*}
    state="Preferred"
    [[ $line == *tentative* ]]  && state="Tentative"
    [[ $line == *deprecated* ]] && state="Deprecated"
    if   [[ $line == *"scope link"* ]]; then fmt "Link-local IPv6 Address" "${a6}%${idx}(${state})"
    elif [[ $line == *temporary* ]];    then fmt "Temporary IPv6 Address" "${a6}(${state})"
    else                                     fmt "IPv6 Address"           "${a6}(${state})"; fi
  done <<<"$v6_lines"

  # --- IPv4 ---
  while read -r line; do
    [[ -z $line ]] && continue
    addr=$(awk '{print $4}' <<<"$line")
    a4=${addr%/*}; plen=${addr#*/}
    state="Preferred"
    [[ $line == *tentative* ]]  && state="Tentative"
    [[ $line == *deprecated* ]] && state="Deprecated"
    fmt "IPv4 Address"  "${a4}(${state})"
    fmt "Subnet Mask"   "$(prefix2mask "$plen")"

    if [[ $line == *dynamic* ]] && [[ $line =~ valid_lft\ ([0-9]+)sec ]]; then
      expires=$(( NOW + BASH_REMATCH[1] ))
      if   [[ -n $lifetime ]];          then obtained=$(( expires - lifetime ))
      elif [[ -n $lease_file_mtime ]];  then obtained=$lease_file_mtime
      else obtained=""; fi
      fmt "Lease Obtained" "${obtained:+$(fmt_date "$obtained")}"
      fmt "Lease Expires"  "$(fmt_date "$expires")"
    fi
  done <<<"$v4_lines"

  # --- Default Gateway (IPv6 먼저, 그 다음 IPv4 : Windows 와 동일) ---
  gws=$( { ip -6 route show default dev "$ifc" 2>/dev/null \
             | awk -v i="$idx" '{for(n=1;n<=NF;n++) if($n=="via") print $(n+1) "%" i}'
           ip -4 route show default dev "$ifc" 2>/dev/null \
             | awk '{for(n=1;n<=NF;n++) if($n=="via") print $(n+1)}'
         } | awk '!s[$0]++' )
  first=1
  if [[ -n $gws ]]; then
    while read -r g; do
      if (( first )); then fmt "Default Gateway" "$g"; first=0; else cont "$g"; fi
    done <<<"$gws"
  else
    fmt "Default Gateway" ""
  fi

  # --- DHCP Server ---
  [[ $dhcp == Yes && -n $server ]] && fmt "DHCP Server" "$server"

  # --- DNS Servers ---
  if [[ -n $v4_lines || -n $v6_lines ]]; then
    dns=$(get_dns "$ifc")
    first=1
    if [[ -n $dns ]]; then
      while read -r d; do
        if (( first )); then fmt "DNS Servers" "$d"; first=0; else cont "$d"; fi
      done <<<"$dns"
    fi
  fi

  fmt "NetBIOS over Tcpip" "$NETBIOS"
done < <(ip -o link show 2>/dev/null | awk -F': ' '{sub(/@.*/,"",$2); print $2}')

echo
