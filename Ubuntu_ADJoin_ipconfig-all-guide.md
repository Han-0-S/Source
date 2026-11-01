# AD Domain Join Ubuntu: ipconfig /all 스타일 출력 스크립트

AD(Active Directory)에 Domain Join 된 Ubuntu VM의 네트워크 정보를 Windows의 `ipconfig /all` 실행 결과와 같은 형식으로 출력하는 Bash 스크립트 모음입니다. 영문판(`ipconfig-all.sh`)과 한국어 Windows 형식(`ipconfig-all-ko.sh`)을 제공합니다.

## 1. 사용법

```bash
chmod +x ipconfig-all.sh ipconfig-all-ko.sh

./ipconfig-all.sh            # 영문판 - 전체 어댑터
./ipconfig-all.sh ens160     # 영문판 - 특정 어댑터만
./ipconfig-all-ko.sh         # 한국어판 - 전체 어댑터
./ipconfig-all-ko.sh ens160  # 한국어판 - 특정 어댑터만
```

`realm`이나 `sssd.conf` 조회에 권한이 필요하면 `sudo`로 실행하세요.

## 2. 정보 출처

| 항목 | 정보 출처 |
|---|---|
| 주 DNS 접미사 (AD 도메인) | `realm list` → `sssd.conf` → `hostname -d` 순으로 조회 |
| IP, 서브넷 마스크, MAC, 게이트웨이 | `ip` 명령, `/sys/class/net` (IPv6 링크로컬/임시 주소 포함) |
| DNS 서버, 검색 접미사 | `resolvectl` 우선, 없으면 `resolv.conf` |
| DHCP 서버, 임대 시작/만료 | systemd-networkd, NetworkManager, dhclient 중 사용 중인 것 |
| 링크 다운 어댑터 | Windows처럼 `Media disconnected` / `미디어 연결 끊김` 표시 |

## 3. 출력 예시 (영문판)

```text
Windows IP Configuration

   Host Name . . . . . . . . . . . . : ubuntu01
   Primary Dns Suffix  . . . . . . . : corp.example.com
   Node Type . . . . . . . . . . . . : Hybrid
   IP Routing Enabled. . . . . . . . : No
   WINS Proxy Enabled. . . . . . . . : No
   DNS Suffix Search List. . . . . . : corp.example.com

Ethernet adapter ens160:

   Connection-specific DNS Suffix  . : corp.example.com
   Description . . . . . . . . . . . : VMware VMXNET3 Ethernet Controller
   Physical Address. . . . . . . . . : 00-0C-29-AA-BB-CC
   DHCP Enabled. . . . . . . . . . . : Yes
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::20c:29ff:feaa:bbcc%2(Preferred)
   IPv4 Address. . . . . . . . . . . : 192.168.10.25(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Lease Obtained. . . . . . . . . . : Sunday, November 1, 2026 9:00:00 AM
   Lease Expires . . . . . . . . . . : Monday, November 2, 2026 9:00:00 AM
   Default Gateway . . . . . . . . . : 192.168.10.1
   DHCP Server . . . . . . . . . . . : 192.168.10.1
   DNS Servers . . . . . . . . . . . : 192.168.10.2
                                       192.168.10.3
   NetBIOS over Tcpip. . . . . . . . : Disabled
```

## 4. 출력 예시 (한국어판)

```text
Windows IP 구성

   호스트 이름 . . . . . . . . . . . : ubuntu01
   주 DNS 접미사 . . . . . . . . . . : corp.example.com
   노드 유형 . . . . . . . . . . . . : 혼성
   IP 라우팅 사용. . . . . . . . . . : 아니요
   WINS 프록시 사용. . . . . . . . . : 아니요
   DNS 접미사 검색 목록. . . . . . . : corp.example.com

이더넷 어댑터 ens160:

   연결별 DNS 접미사 . . . . . . . . : corp.example.com
   설명. . . . . . . . . . . . . . . : VMware VMXNET3 Ethernet Controller
   물리적 주소 . . . . . . . . . . . : 00-0C-29-AA-BB-CC
   DHCP 사용 . . . . . . . . . . . . : 예
   자동 구성 사용. . . . . . . . . . : 예
   링크-로컬 IPv6 주소 . . . . . . . : fe80::20c:29ff:feaa:bbcc%2(기본 설정)
   IPv4 주소 . . . . . . . . . . . . : 192.168.10.25(기본 설정)
   서브넷 마스크 . . . . . . . . . . : 255.255.255.0
   임대 시작 시간. . . . . . . . . . : 2026년 11월 1일 일요일 오전 9:00:00
   임대 만료 시간. . . . . . . . . . : 2026년 11월 2일 월요일 오전 9:00:00
   기본 게이트웨이 . . . . . . . . . : 192.168.10.1
   DHCP 서버 . . . . . . . . . . . . : 192.168.10.1
   DNS 서버. . . . . . . . . . . . . : 192.168.10.2
                                       192.168.10.3
   Tcpip를 통한 NetBIOS. . . . . . . : 사용 안 함
```

## 5. 영문판과 한국어판의 차이

- **라벨과 값**: 한국어 Windows 용어를 사용합니다. 예: `예/아니요`, `혼성`, `(기본 설정)`, `미디어 연결 끊김`, `이더넷 어댑터`, `무선 LAN 어댑터`.
- **날짜 형식**: `2026년 11월 1일 일요일 오전 9:00:00` 형식으로 출력합니다.
- **점선 정렬**: 한글은 터미널에서 2칸을 차지하므로 글자 수가 아니라 표시 폭 기준으로 `. . .`을 맞춥니다.
- **로케일**: 한국어판은 `C.UTF-8`을 사용하며 Ubuntu 기본 설치에 포함되어 있습니다.

## 6. 참고 사항

- `lo`와 `veth*` 인터페이스는 표시하지 않습니다.
- `Node Type`은 Windows 기본값인 `Hybrid`(혼성)로 고정했습니다.
- `NetBIOS over Tcpip`은 `nmbd` 서비스가 실행 중이면 `Enabled`(사용), 아니면 `Disabled`(사용 안 함)입니다.
- 일부 라벨의 점 개수나 표기는 실제 한국어 Windows와 한두 칸 다를 수 있습니다. 스크립트의 `fmt "…"` 부분에서 바로 수정할 수 있습니다.
- 스크립트는 네트워크 인터페이스가 없는 환경에서 호스트 정보 부분까지만 테스트했습니다. 어댑터 부분은 실제 VM에서 한 번 실행해 확인하세요.

## 7. 전체 코드: ipconfig-all.sh (영문판)

```bash
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
```

## 8. 전체 코드: ipconfig-all-ko.sh (한국어판)

```bash
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
```
