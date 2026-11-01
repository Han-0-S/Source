# Ubuntu 20.04 / 22.04 VM의 AD 시간 동기화 점검 및 자동화 가이드

AD(Active Directory)에 Domain Join 된 Ubuntu VM에서 **DC(도메인 컨트롤러)와의 시간차 때문에 로그인이 실패할 때**, 동기화가 완료되었는지 확인하는 방법과 이를 설정·자동 점검하는 방법을 정리한 문서입니다.

**목차**

1. 핵심 개념
2. VM의 NTP 동기화 완료 여부 확인
3. AD DC와의 실제 시간차 측정
4. 시간차 때문에 로그인이 실패했는지 로그로 판별
5. 간단한 점검 스크립트 (오프셋 초과 시 경고)
6. 시간차가 확인됐을 때의 조치
7. 자주 놓치는 원인
8. 자동화 패키지: 설정 파일 + 부팅 시 자동 점검 서비스
9. 전체 코드
10. 제거

## 1. 핵심 개념

`timedatectl`의 `System clock synchronized: yes`는 **"어떤 NTP 서버와든 동기화됐다"**는 뜻일 뿐, **AD DC와의 시간차를 보장하지 않습니다.** Kerberos는 기본적으로 DC와 5분(300초) 이상 차이 나면 인증을 거부합니다. 따라서 확인은 두 단계로 합니다.

- **1단계**: VM이 NTP 동기화를 마쳤는지 확인 (timesyncd / chrony)
- **2단계**: AD DC와의 실제 시간차를 직접 측정 (허용 기준: 보통 1~2초 이내가 안전, 300초 초과 시 로그인 실패)

## 2. VM의 NTP 동기화 완료 여부 확인

```bash
timedatectl
```

`System clock synchronized: yes`, `NTP service: active`이면 동기화가 된 상태입니다.

### systemd-timesyncd (Ubuntu 20.04/22.04 기본값)

```bash
timedatectl timesync-status     # Server, Offset, Delay, Packet count 확인
journalctl -u systemd-timesyncd --no-pager | tail
```

`Packet count`가 0이면 아직 서버와 한 번도 통신하지 못한 상태입니다.

### chrony

```bash
chronyc tracking          # System time(오프셋), Leap status: Normal 인지 확인
chronyc sources -v        # 앞에 ^* 가 붙은 서버가 현재 선택된 동기화 대상
chronyc waitsync 30 0.1   # 오프셋 0.1초 이내가 될 때까지 최대 30회 대기, 성공 시 종료코드 0
```

## 3. AD DC와의 실제 시간차 측정

DC를 NTP 소스로 쓰지 않거나 소스가 불확실하다면 DC와 직접 비교하는 것이 가장 확실합니다.

```bash
# (1) Samba 도구: "Server time offset" 값이 초 단위 차이
net ads info -S dc01.corp.example.com

# (2) DC의 rootDSE currentTime 조회 (익명 조회, ldap-utils 필요)
ldapsearch -x -H ldap://dc01.corp.example.com -s base -b "" currentTime
date -u +%Y%m%d%H%M%S.0Z       # VM 시간과 비교

# (3) NTP 질의만 해보기 (ntpdate 패키지 필요)
ntpdate -q dc01.corp.example.com
```

절대값이 300초(5분)를 넘으면 로그인이 실패합니다. Windows 쪽에서는 아래처럼 확인할 수 있습니다.

```text
w32tm /stripchart /computer:<Ubuntu-IP> /samples:3 /dataonly
```

## 4. 시간차 때문에 로그인이 실패했는지 로그로 판별

```bash
sudo grep -i "skew" /var/log/sssd/*.log
sudo journalctl -u sssd --no-pager | grep -i -E "skew|krb5"
kinit user@CORP.EXAMPLE.COM      # "Clock skew too great" 가 나오면 시간차 문제
```

`/var/log/sssd/krb5_child.log`에 `KRB5KRB_AP_ERR_SKEW`가 보이면 확정입니다. 로그가 부족하면 `sssd.conf`의 `[domain/...]`에 `debug_level = 6`을 넣고 sssd를 재시작하세요.

## 5. 간단한 점검 스크립트 (오프셋 초과 시 경고)

```bash
#!/usr/bin/env bash
DC=dc01.corp.example.com
LIMIT=120   # 허용 오프셋(초)

off=$(net ads info -S "$DC" 2>/dev/null | awk -F': *' '/Server time offset/ {print $2}')
[[ -z $off ]] && { echo "DC 조회 실패 (네트워크/DNS 확인)"; exit 2; }
off=${off#-}   # 절대값
if (( off > LIMIT )); then echo "경고: DC와 시간차 ${off}초"; exit 1
else echo "정상: DC와 시간차 ${off}초"; fi
```

부팅 직후 동기화가 끝난 뒤에 SSSD/로그인을 진행시키고 싶다면 아래 루프를 서비스 시작 전 단계에 넣을 수 있습니다. (아래 8장의 자동화 패키지가 이를 서비스로 구현한 것입니다.)

```bash
until [[ $(timedatectl show -p NTPSynchronized --value) == yes ]]; do sleep 2; done
```

## 6. 시간차가 확인됐을 때의 조치

```bash
# timesyncd 사용 시: /etc/systemd/timesyncd.conf 의 [Time] 에 NTP=dc01.corp.example.com 지정 후
sudo systemctl restart systemd-timesyncd

# chrony 사용 시: 즉시 강제 보정
sudo chronyc makestep

# 보정 후 Kerberos/SSSD 캐시 정리
kdestroy; sudo sss_cache -E; sudo systemctl restart sssd
```

## 7. 자주 놓치는 원인

- **하이퍼바이저 시간 동기화와 충돌**: VMware Tools의 시간 동기화나 Hyper-V Time Synchronization 서비스가 게스트 NTP와 겹치면 시간이 흔들립니다. 둘 중 하나만 사용하세요.
- **스냅샷 복원, 일시 중지 후 재개**: 이때 시계가 크게 틀어질 수 있습니다. `systemd-timesyncd`는 큰 오차를 천천히 보정하는 데 한계가 있으므로, AD 환경에서는 `chrony`와 `makestep` 설정이 더 안정적입니다.
- **타임존 오류**: 비교는 UTC 기준이라 타임존 자체는 상관없습니다. 다만 타임존이 틀린 채로 시각을 수동으로 맞추면 시간 단위로 어긋납니다. `timedatectl`로 타임존과 UTC 시각을 함께 확인하세요.
- **NTP 소스가 DC와 다름**: 외부 NTP(`ntp.ubuntu.com` 등)와 DC 시간이 서로 다르면 VM은 "동기화됨"으로 나와도 DC와는 틀릴 수 있습니다. 가능하면 NTP 소스를 DC(PDC Emulator)로 맞추세요.

## 8. 자동화 패키지: 설정 파일 + 부팅 시 자동 점검 서비스

timesyncd용과 chrony용 설정, 그리고 부팅 시 DC와의 시간차를 점검하고 필요하면 보정하는 systemd 서비스를 묶은 패키지(`ad-time-sync`)입니다. 시간 서비스는 **둘 중 하나만** 사용합니다.

### 8.1 구성

```text
ad-time-sync/
├── install.sh                      설치 스크립트
├── uninstall.sh                    제거 스크립트
└── files/
    ├── ad-time-check               점검/보정 스크립트  → /usr/local/sbin/ad-time-check
    ├── ad-time-check.default       점검 설정           → /etc/default/ad-time-check
    ├── ad-time-check.service       부팅 시 점검 유닛   → /etc/systemd/system/
    ├── ad-time-check.timer         15분 주기 재점검    → /etc/systemd/system/
    ├── timesyncd-10-ad-time.conf   timesyncd 설정      → /etc/systemd/timesyncd.conf.d/10-ad-time.conf
    └── chrony.conf                 chrony 설정         → /etc/chrony/chrony.conf
```

### 8.2 설치

```bash
# A) chrony 사용 (권장: step 보정, 상태 확인 도구가 풍부)
sudo ./install.sh --engine chrony --install-deps \
     --dc "dc01.corp.example.com dc02.corp.example.com"

# B) systemd-timesyncd 사용 (Ubuntu 기본, 별도 패키지 불필요)
sudo ./install.sh --engine timesyncd --install-deps \
     --dc "dc01.corp.example.com dc02.corp.example.com"
```

| 옵션 | 설명 |
|---|---|
| `--engine chrony\|timesyncd\|auto` | 사용할 시간 서비스. `auto`는 chrony가 설치되어 있으면 chrony |
| `--dc "<DC1> [DC2 ...]"` | 동기화·점검 대상 DC (필수). PDC Emulator를 첫 번째로 권장 |
| `--fallback <서버>` | chrony에만 적용되는 보조 NTP 서버 |
| `--max-offset <초>` | 허용 시간차 (기본 60초) |
| `--install-deps` | `ldap-utils`(DC 시간 조회용)와 chrony 선택 시 `chrony` 설치 |

설치가 끝나면 점검을 한 번 실행하고 결과를 보여 줍니다. 기존 설정 파일은 `.bak.<시각>`으로 백업됩니다.

### 8.3 부팅 시 동작 순서

```text
부팅
 └─ network-online.target
     └─ chrony / systemd-timesyncd 시작
         └─ ad-time-check.service        ← sssd / winbind / smbd 보다 먼저 실행
              1) NTP 동기화 완료까지 대기 (기본 최대 45초)
              2) DC 와의 시간차 측정
              3) 허용치 초과 시 보정(chrony: makestep / timesyncd: 재시작) 후 재측정 (최대 3회)
              4) 보정이 있었다면 sss_cache -E + sssd 재시작
         └─ sssd 시작
부팅 10분 후부터 15분마다 ad-time-check.timer 가 같은 점검을 반복
```

- 점검이 실패해도 sssd 등은 **그대로 시작**됩니다(순서만 보장). 실패는 `systemctl --failed`와 로그로 확인합니다.
- DC와의 시간차는 `net ads info -S`(Samba) → `ldapsearch currentTime`(ldap-utils) → `ntpdate -q` 순서로 가능한 방법을 자동 선택합니다.

### 8.4 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 정상 (허용 범위 이내) |
| 1 | 시간차 초과, 보정 실패 |
| 2 | DC 시간 조회 불가 (네트워크/DNS/방화벽) 또는 DC 목록 없음 |

### 8.5 설정 항목 (`/etc/default/ad-time-check`)

| 변수 | 기본값 | 설명 |
|---|---|---|
| `DC_LIST` | 설치 시 지정 | 점검 대상 DC. 비우면 realm 도메인명을 DNS로 조회해 자동 탐색 |
| `MAX_OFFSET` | 60 | 허용 시간차(초). Kerberos 한계(300초)보다 여유 있게 |
| `WAIT_TIMEOUT` | 45 | 부팅 시 NTP 동기화 대기 최대 시간(초) |
| `RETRIES` / `RETRY_INTERVAL` | 3 / 10 | 재시도 횟수 / 간격(초) |
| `RESTART_SSSD_ON_FIX` | yes | 보정 후 SSSD 캐시 정리·재시작 |

부팅 지연이 걱정되면 `WAIT_TIMEOUT`, `RETRIES`를 줄이세요. 최악의 경우 서비스는 `TimeoutStartSec=180`에서 중단됩니다.

### 8.6 확인 방법

```bash
# 점검 결과
sudo ad-time-check --check-only        # 보정 없이 점검만
ad-time-check --status                 # 마지막 결과 (/run/ad-time-check.status)
journalctl -u ad-time-check -b --no-pager
systemctl list-timers ad-time-check.timer

# 시간 서비스 상태
timedatectl                            # System clock synchronized: yes
timedatectl timesync-status            # (timesyncd) Server, Offset, Packet count
chronyc tracking                       # (chrony) System time, Leap status: Normal
chronyc sources -v                     # (chrony) ^* 가 선택된 소스
```

### 8.7 엔진별 비교

| 항목 | systemd-timesyncd | chrony |
|---|---|---|
| 설정 위치 | `/etc/systemd/timesyncd.conf.d/10-ad-time.conf` | `/etc/chrony/chrony.conf` (전체 교체, 백업 생성) |
| 큰 오차 보정 | 오차가 약 0.4초를 넘으면 step으로 보정 | `makestep`으로 즉시 보정 |
| 보정 방법(스크립트) | `systemctl restart systemd-timesyncd` | `chronyc makestep` |
| 장점 | 기본 설치, 가벼움 | 상태 확인·진단 도구 풍부, VM 스냅샷 복원에 유리 |
| 20.04 / 22.04 | 모두 drop-in 지원 | 20.04는 chrony 3.5, 22.04는 4.x (설정 호환) |

- chrony 설정은 Ubuntu 22.04 기본 파일에 있는 `sourcedir /run/chrony-dhcp`(DHCP로 받은 NTP 서버)를 포함하지 않습니다. DHCP 제공 NTP를 함께 쓰려면 해당 줄을 추가하세요.
- timesyncd의 `FallbackNTP`는 `NTP=`가 비어 있을 때만 쓰이므로 이 구성에서는 의미가 없어 넣지 않았습니다.

### 8.8 함께 확인할 것

- **DC 쪽**: DC(특히 PDC Emulator)에서 Windows Time 서비스(w32time)가 NTP 서버로 동작해야 하며 UDP 123이 열려 있어야 합니다.
- **하이퍼바이저 시간 동기화**: VMware Tools / Hyper-V 시간 동기화가 게스트 NTP와 겹치지 않게 하나만 사용하세요.
- **방화벽**: DC 조회에 UDP/TCP 389, 시간 동기화에 UDP 123이 필요합니다.
- **테스트 범위**: 점검 스크립트의 판정 로직은 가짜 `net` 명령으로 확인했고, 설치 스크립트와 systemd 유닛은 문법만 검사했습니다. 운영 VM에 적용하기 전에 테스트 VM에서 먼저 실행해 보세요.

## 9. 전체 코드

### 9.1 files/ad-time-check (점검/보정 스크립트)

```bash
#!/usr/bin/env bash
#
# ad-time-check
# AD 도메인 컨트롤러(DC)와의 시간차를 점검하고, Kerberos 허용 오차를 넘으면 보정합니다.
#
# 사용법:
#   ad-time-check               점검 + (필요 시) 보정
#   ad-time-check --check-only  점검만 (보정/sssd 재시작 안 함)
#   ad-time-check --status      마지막 점검 결과 보기
#
# 종료 코드: 0=정상, 1=시간차 초과(보정 실패), 2=DC 조회 불가, 64=사용법 오류
# 설정 파일: /etc/default/ad-time-check

set -u
export LC_ALL=C

CONF=/etc/default/ad-time-check
# shellcheck disable=SC1090
[[ -r $CONF ]] && . "$CONF"

DC_LIST=${DC_LIST:-}
MAX_OFFSET=${MAX_OFFSET:-60}
WAIT_TIMEOUT=${WAIT_TIMEOUT:-45}
RETRIES=${RETRIES:-3}
RETRY_INTERVAL=${RETRY_INTERVAL:-10}
RESTART_SSSD_ON_FIX=${RESTART_SSSD_ON_FIX:-yes}
STATUS_FILE=${STATUS_FILE:-/run/ad-time-check.status}
CHECK_ONLY=0
M_OFFSET=""; M_DC=""; M_METHOD=""; SYNCED=no

have() { command -v "$1" >/dev/null 2>&1; }
log()  { printf '[ad-time-check] %s\n' "$*"; }
usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

case "${1:-}" in
  --status)     cat "$STATUS_FILE" 2>/dev/null || echo "상태 파일 없음: $STATUS_FILE"; exit 0 ;;
  --check-only) CHECK_ONLY=1 ;;
  -h|--help)    usage; exit 0 ;;
  "")           ;;
  *)            usage; exit 64 ;;
esac

# ---------- 시간 동기화 서비스 판별 / 동기화 대기 ----------
detect_engine() {
  if   systemctl is-active --quiet chrony 2>/dev/null || systemctl is-active --quiet chronyd 2>/dev/null; then echo chrony
  elif systemctl is-active --quiet systemd-timesyncd 2>/dev/null; then echo timesyncd
  else echo none; fi
}

ntp_synced() {
  case $ENGINE in
    chrony)    chronyc tracking 2>/dev/null | grep -q '^Leap status *: Normal' ;;
    timesyncd) [[ $(timedatectl show -p NTPSynchronized --value 2>/dev/null) == yes ]] ;;
    *)         return 1 ;;
  esac
}

wait_sync() {
  local elapsed=0
  while (( elapsed < WAIT_TIMEOUT )); do
    ntp_synced && return 0
    sleep 2; elapsed=$(( elapsed + 2 ))
  done
  return 1
}

# ---------- DC 목록 ----------
discover_dcs() {
  if [[ -n $DC_LIST ]]; then echo $DC_LIST; return; fi
  local d=""
  have realm && d=$(realm list 2>/dev/null | awk -F': *' '/^[[:space:]]*domain-name:/ {print $2; exit}')
  [[ -z $d ]] && d=$(hostname -d 2>/dev/null)
  [[ -n $d ]] && getent ahostsv4 "$d" 2>/dev/null | awk '{print $1}' | sort -u | head -3 | tr '\n' ' '
}

# ---------- DC 와의 시간차 측정 (값 = DC시간 - 로컬시간, 초) ----------
now() { date +%s.%N; }

offset_netads() {
  have net || return 1
  local o
  o=$(timeout 15 net ads info -S "$1" 2>/dev/null | awk -F': *' '/Server time offset/ {print $2; exit}')
  [[ $o =~ ^-?[0-9]+$ ]] && echo "$o"
}

offset_ldap() {
  have ldapsearch || return 1
  local ct t1 t2 e
  t1=$(now)
  ct=$(timeout 15 ldapsearch -x -LLL -H "ldap://$1" -s base -b "" currentTime 2>/dev/null | awk '/^currentTime:/ {print $2; exit}')
  t2=$(now)
  [[ $ct =~ ^[0-9]{14}\.0Z$ ]] || return 1
  e=$(date -u -d "${ct:0:4}-${ct:4:2}-${ct:6:2} ${ct:8:2}:${ct:10:2}:${ct:12:2}" +%s) || return 1
  awk -v e="$e" -v a="$t1" -v b="$t2" 'BEGIN{printf "%.3f", e-(a+b)/2}'
}

offset_ntpdate() {
  have ntpdate || return 1
  local o
  o=$(timeout 20 ntpdate -q "$1" 2>/dev/null | awk '{for(i=1;i<NF;i++) if($i=="offset") {v=$(i+1); gsub(/,/,"",v)}} END{print v}')
  [[ $o =~ ^[-+]?[0-9.]+$ ]] && echo "$o"
}

measure() {
  local dc fn o
  for dc in $DCS; do
    for fn in offset_netads offset_ldap offset_ntpdate; do
      if o=$($fn "$dc") && [[ -n $o ]]; then
        M_OFFSET=$o; M_DC=$dc; M_METHOD=${fn#offset_}
        return 0
      fi
    done
  done
  return 1
}

exceeds() { awk -v o="$1" -v m="$MAX_OFFSET" 'BEGIN{ if (o<0) o=-o; exit !(o>m) }'; }

# ---------- 보정 ----------
fix_clock() {
  case $ENGINE in
    chrony)    log "chronyc makestep 실행 (즉시 시간 보정)"
               chronyc makestep >/dev/null 2>&1 || { log "makestep 실패"; return 1; } ;;
    timesyncd) log "systemd-timesyncd 재시작 (즉시 재동기화)"
               systemctl restart systemd-timesyncd || return 1 ;;
    *)         log "실행 중인 시간 동기화 서비스(chrony/timesyncd)가 없습니다"; return 1 ;;
  esac
}

write_status() {
  {
    echo "time=$(date -Is)"
    echo "engine=$ENGINE"
    echo "ntp_synced=$SYNCED"
    echo "dc=$M_DC"
    echo "method=$M_METHOD"
    echo "offset_sec=$M_OFFSET"
    echo "max_offset_sec=$MAX_OFFSET"
    echo "result=$1"
  } > "$STATUS_FILE" 2>/dev/null
}

# ---------- 메인 ----------
ENGINE=$(detect_engine)
DCS=$(discover_dcs)
log "시간 서비스: $ENGINE / 대상 DC: ${DCS:-(없음)}"

if wait_sync; then SYNCED=yes; log "NTP 동기화 완료"
else log "경고: ${WAIT_TIMEOUT}초 안에 NTP 동기화가 완료되지 않았습니다"; fi

if [[ -z ${DCS// /} ]]; then
  log "DC 목록을 알 수 없습니다 (/etc/default/ad-time-check 의 DC_LIST 설정 필요)"
  write_status no-dc; exit 2
fi

fixed=0; result=unreachable
for (( try=1; try<=RETRIES; try++ )); do
  if measure; then
    if exceeds "$M_OFFSET"; then
      result=skew
      log "시간차 ${M_OFFSET}초 > 허용 ${MAX_OFFSET}초 [$M_DC via $M_METHOD] (시도 $try/$RETRIES)"
      (( CHECK_ONLY )) && break
      fix_clock && fixed=1
      sleep "$RETRY_INTERVAL"
      wait_sync && SYNCED=yes
    else
      result=ok
      log "정상: DC($M_DC)와 시간차 ${M_OFFSET}초 (허용 ${MAX_OFFSET}초, $M_METHOD)"
      break
    fi
  else
    result=unreachable
    log "DC 시간 조회 실패 (시도 $try/$RETRIES) - 네트워크/DNS/방화벽(UDP 389, TCP 389) 확인"
    (( CHECK_ONLY )) && break
    sleep "$RETRY_INTERVAL"
  fi
done

write_status "$result"

case $result in
  ok)
    if (( fixed )) && [[ $RESTART_SSSD_ON_FIX == yes ]] && (( ! CHECK_ONLY )); then
      log "시간 보정 후 SSSD 캐시 정리 및 재시작"
      have sss_cache && sss_cache -E >/dev/null 2>&1
      systemctl try-restart sssd 2>/dev/null
    fi
    exit 0 ;;
  skew)
    log "오류: 시간차를 허용 범위로 줄이지 못했습니다. NTP 소스가 DC(PDC Emulator)인지 확인하세요."
    exit 1 ;;
  *)
    exit 2 ;;
esac
```

### 9.2 files/ad-time-check.default (점검 설정)

```bash
# /etc/default/ad-time-check
# ad-time-check 서비스 설정 (쉘 문법)

# 점검 대상 DC (공백 구분). 비워 두면 realm 도메인명을 DNS 로 조회해 자동 탐색합니다.
DC_LIST="@DC_LIST@"

# 허용 시간차(초). Kerberos 기본 한계는 300초이며, 여유를 두고 60초를 권장합니다.
MAX_OFFSET=@MAX_OFFSET@

# 부팅 시 NTP 동기화를 기다리는 최대 시간(초)
WAIT_TIMEOUT=45

# 시간차 초과/DC 조회 실패 시 재시도 횟수와 간격(초)
RETRIES=3
RETRY_INTERVAL=10

# 시간 보정이 일어났을 때 SSSD 캐시 정리 + 재시작 여부 (yes/no)
RESTART_SSSD_ON_FIX=yes
```

### 9.3 files/ad-time-check.service (부팅 시 점검 유닛)

```ini
[Unit]
Description=AD time synchronization check (Kerberos clock skew guard)
Wants=network-online.target
After=network-online.target chrony.service chronyd.service systemd-timesyncd.service
# 인증 계열 서비스가 시작되기 전에 점검을 끝냅니다 (실패해도 이들 서비스는 시작됨)
Before=sssd.service winbind.service smbd.service nmbd.service
ConditionPathExists=/usr/local/sbin/ad-time-check

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ad-time-check
TimeoutStartSec=180

[Install]
WantedBy=multi-user.target
```

### 9.4 files/ad-time-check.timer (주기 재점검)

```ini
[Unit]
Description=Periodic AD time synchronization check

[Timer]
OnBootSec=10min
OnUnitInactiveSec=15min
RandomizedDelaySec=30
AccuracySec=10s

[Install]
WantedBy=timers.target
```

### 9.5 files/timesyncd-10-ad-time.conf (timesyncd 설정)

```ini
# /etc/systemd/timesyncd.conf.d/10-ad-time.conf
# systemd-timesyncd 를 AD 도메인 컨트롤러에 동기화시키는 drop-in 설정
# (Ubuntu 20.04 / 22.04 공통)
[Time]
# 동기화 대상 DC (공백 구분, 가능하면 PDC Emulator 를 첫 번째로)
NTP=@DC_LIST@

# DC 가 외부 시간원과 동기화되지 않은 경우 root distance 가 커질 수 있어 여유를 둠
RootDistanceMaxSec=5

# 폴링 간격: 기본(32~2048초)보다 최대 간격을 줄여 오차가 오래 쌓이지 않게 함
PollIntervalMinSec=32
PollIntervalMaxSec=512

# 서버 접속 실패 시 재시도 간격(초)
ConnectionRetrySec=30
```

### 9.6 files/chrony.conf (chrony 설정)

```text
# /etc/chrony/chrony.conf
# chrony 를 AD 도메인 컨트롤러에 동기화시키는 설정 (Ubuntu 20.04 chrony 3.5 / 22.04 chrony 4.x 공통)

# 동기화 대상 DC (설치 스크립트가 --dc 값으로 채웁니다)
# @SERVERS@

# 시작 직후 처음 3번의 측정에서 오차가 1초를 넘으면 시간을 한 번에 보정(step)
# VM 스냅샷 복원/일시중지가 잦다면 "makestep 1.0 -1" (언제든 step 허용)도 고려
makestep 1.0 3

# Windows DC 는 root delay/dispersion 이 큰 경우가 있어 기본값(3초)보다 완화
maxdistance 16.0

# 커널 RTC 동기화
rtcsync

# 클럭 드리프트 기록
driftfile /var/lib/chrony/chrony.drift

# 로그
logdir /var/log/chrony

# 윤초 처리 (leap second 테이블 사용)
leapsectz right/UTC
```

### 9.7 install.sh (설치)

```bash
#!/usr/bin/env bash
#
# install.sh - AD 시간 동기화 설정 + 부팅 시 자동 점검 서비스 설치
#
# 사용법 (root):
#   sudo ./install.sh --dc "dc01.corp.example.com dc02.corp.example.com" [옵션]
#
# 옵션:
#   --engine chrony|timesyncd|auto   사용할 시간 서비스 (기본 auto: chrony 가 설치되어 있으면 chrony)
#   --dc "<DC1> [DC2 ...]"           동기화/점검 대상 DC (필수, 공백 구분)
#   --fallback <서버>                chrony 에 추가할 보조 NTP 서버 (예: ntp.ubuntu.com)
#   --max-offset <초>                허용 시간차 (기본 60)
#   --install-deps                   필요한 패키지 설치 (chrony 선택 시 chrony, ldap-utils)
#   -h, --help                       도움말

set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
F=$HERE/files

ENGINE=auto; DC_LIST=""; FALLBACK=""; MAX_OFFSET=60; INSTALL_DEPS=0

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case $1 in
    --engine)       ENGINE=${2:?}; shift 2 ;;
    --dc)           DC_LIST=${2:?}; shift 2 ;;
    --fallback)     FALLBACK=${2:?}; shift 2 ;;
    --max-offset)   MAX_OFFSET=${2:?}; shift 2 ;;
    --install-deps) INSTALL_DEPS=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "알 수 없는 옵션: $1"; usage; exit 64 ;;
  esac
done

(( EUID == 0 )) || { echo "root 권한(sudo)으로 실행하세요."; exit 1; }
[[ -n $DC_LIST ]] || { echo "--dc 로 도메인 컨트롤러를 지정하세요."; usage; exit 64; }

if [[ $ENGINE == auto ]]; then
  if command -v chronyd >/dev/null 2>&1; then ENGINE=chrony; else ENGINE=timesyncd; fi
fi
[[ $ENGINE == chrony || $ENGINE == timesyncd ]] || { echo "--engine 은 chrony 또는 timesyncd"; exit 64; }
echo "==> 시간 서비스: $ENGINE / DC: $DC_LIST"

backup() {
  if [[ -e $1 ]]; then cp -a "$1" "$1.bak.$(date +%Y%m%d%H%M%S)"; fi
}

if (( INSTALL_DEPS )); then
  echo "==> 패키지 설치"
  apt-get update -qq
  pkgs="ldap-utils"
  [[ $ENGINE == chrony ]] && pkgs="$pkgs chrony"
  # shellcheck disable=SC2086
  apt-get install -y $pkgs
fi

install_timesyncd() {
  echo "==> systemd-timesyncd drop-in 설정"
  install -d /etc/systemd/timesyncd.conf.d
  backup /etc/systemd/timesyncd.conf.d/10-ad-time.conf
  sed -e "s|@DC_LIST@|$DC_LIST|" "$F/timesyncd-10-ad-time.conf" > /etc/systemd/timesyncd.conf.d/10-ad-time.conf
  systemctl unmask systemd-timesyncd 2>/dev/null || true
  systemctl enable systemd-timesyncd
  timedatectl set-ntp true
  systemctl restart systemd-timesyncd
}

install_chrony() {
  command -v chronyd >/dev/null 2>&1 || { echo "chrony 가 설치되어 있지 않습니다. --install-deps 를 사용하거나 'apt install chrony' 하세요."; exit 1; }
  echo "==> chrony 설정 (/etc/chrony/chrony.conf, 기존 파일은 .bak.<시각> 으로 백업)"
  local tmp; tmp=$(mktemp)
  for dc in $DC_LIST; do echo "server $dc iburst" >> "$tmp"; done
  if [[ -n $FALLBACK ]]; then echo "server $FALLBACK iburst" >> "$tmp"; fi
  install -d /etc/chrony
  backup /etc/chrony/chrony.conf
  sed -e "/@SERVERS@/{r $tmp" -e 'd}' "$F/chrony.conf" > /etc/chrony/chrony.conf
  rm -f "$tmp"
  # chrony 와 timesyncd 는 동시에 쓰지 않음
  systemctl disable --now systemd-timesyncd 2>/dev/null || true
  systemctl enable chrony
  systemctl restart chrony
}

if [[ $ENGINE == chrony ]]; then install_chrony; else install_timesyncd; fi

echo "==> 점검 스크립트 / 서비스 설치"
install -m 0755 "$F/ad-time-check" /usr/local/sbin/ad-time-check
if [[ -e /etc/default/ad-time-check ]]; then
  echo "    /etc/default/ad-time-check 가 이미 있어 유지합니다."
else
  sed -e "s|@DC_LIST@|$DC_LIST|" -e "s|@MAX_OFFSET@|$MAX_OFFSET|" "$F/ad-time-check.default" > /etc/default/ad-time-check
  chmod 0644 /etc/default/ad-time-check
fi
install -m 0644 "$F/ad-time-check.service" /etc/systemd/system/ad-time-check.service
install -m 0644 "$F/ad-time-check.timer"   /etc/systemd/system/ad-time-check.timer
systemctl daemon-reload
systemctl enable ad-time-check.service ad-time-check.timer
systemctl start ad-time-check.timer

echo "==> 지금 한 번 점검 실행"
systemctl start ad-time-check.service || true
echo
/usr/local/sbin/ad-time-check --status || true
echo
echo "완료. 로그 확인: journalctl -u ad-time-check -b --no-pager"
```

### 9.8 uninstall.sh (제거)

```bash
#!/usr/bin/env bash
#
# uninstall.sh - 자동 점검 서비스와 timesyncd drop-in 설정 제거
# (chrony.conf 는 .bak.<시각> 백업이 남아 있으므로 필요하면 수동으로 복원하세요)
set -u
(( EUID == 0 )) || { echo "root 권한(sudo)으로 실행하세요."; exit 1; }

systemctl disable --now ad-time-check.timer ad-time-check.service 2>/dev/null
rm -f /etc/systemd/system/ad-time-check.service /etc/systemd/system/ad-time-check.timer
rm -f /usr/local/sbin/ad-time-check
rm -f /etc/systemd/timesyncd.conf.d/10-ad-time.conf
systemctl daemon-reload
echo "제거 완료. /etc/default/ad-time-check 는 남겨 두었습니다 (필요 없으면 삭제)."
ls /etc/chrony/chrony.conf.bak.* 2>/dev/null && echo "↑ chrony 설정 백업 파일이 있습니다."
systemctl try-restart systemd-timesyncd 2>/dev/null
exit 0
```

## 10. 제거

```bash
sudo ./uninstall.sh
```

서비스·타이머·점검 스크립트와 timesyncd drop-in을 제거합니다. `/etc/default/ad-time-check`와 chrony 백업(`/etc/chrony/chrony.conf.bak.*`)은 남겨 두므로 필요 시 직접 복원하세요.
