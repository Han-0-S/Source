# AD 시간 동기화 설정 + 부팅 시 자동 점검 (Ubuntu 20.04 / 22.04)

AD 도메인에 가입된 Ubuntu VM이 **도메인 컨트롤러(DC)와의 시간차 때문에 로그인에 실패하는 문제**를 막기 위한 설정 모음입니다.
`systemd-timesyncd`용과 `chrony`용 설정을 모두 제공하며, 부팅 시 DC와의 시간차를 점검하고 필요하면 보정하는 systemd 서비스가 포함되어 있습니다.

## 구성

```
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

## 빠른 시작

시간 서비스는 **둘 중 하나만** 사용합니다.

```bash
tar xzf ad-time-sync.tar.gz && cd ad-time-sync

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

설치가 끝나면 점검을 한 번 실행하고 결과를 보여 줍니다. 기존 설정 파일은 `.bak.<시각>` 으로 백업됩니다.

## 동작 방식

```
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

### 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 정상 (허용 범위 이내) |
| 1 | 시간차 초과, 보정 실패 |
| 2 | DC 시간 조회 불가 (네트워크/DNS/방화벽) 또는 DC 목록 없음 |

## 확인 방법

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

## 설정 항목 (`/etc/default/ad-time-check`)

| 변수 | 기본값 | 설명 |
|---|---|---|
| `DC_LIST` | 설치 시 지정 | 점검 대상 DC. 비우면 realm 도메인명을 DNS로 조회해 자동 탐색 |
| `MAX_OFFSET` | 60 | 허용 시간차(초). Kerberos 한계(300초)보다 여유 있게 |
| `WAIT_TIMEOUT` | 45 | 부팅 시 NTP 동기화 대기 최대 시간(초) |
| `RETRIES` / `RETRY_INTERVAL` | 3 / 10 | 재시도 횟수 / 간격(초) |
| `RESTART_SSSD_ON_FIX` | yes | 보정 후 SSSD 캐시 정리·재시작 |

부팅 지연이 걱정되면 `WAIT_TIMEOUT`, `RETRIES`를 줄이세요. 최악의 경우 서비스는 `TimeoutStartSec=180` 에서 중단됩니다.

## 엔진별 참고

| 항목 | systemd-timesyncd | chrony |
|---|---|---|
| 설정 위치 | `/etc/systemd/timesyncd.conf.d/10-ad-time.conf` | `/etc/chrony/chrony.conf` (전체 교체, 백업 생성) |
| 큰 오차 보정 | 오차가 약 0.4초를 넘으면 step 으로 보정 | `makestep` 으로 즉시 보정 |
| 보정 방법(스크립트) | `systemctl restart systemd-timesyncd` | `chronyc makestep` |
| 장점 | 기본 설치, 가벼움 | 상태 확인·진단 도구 풍부, VM 스냅샷 복원에 유리 |
| 20.04 / 22.04 | 모두 drop-in 지원 | 20.04는 chrony 3.5, 22.04는 4.x (설정 호환) |

- chrony 설정은 Ubuntu 22.04 기본 파일에 있는 `sourcedir /run/chrony-dhcp`(DHCP로 받은 NTP 서버)를 포함하지 않습니다. DHCP 제공 NTP를 함께 쓰려면 해당 줄을 추가하세요.
- timesyncd의 `FallbackNTP`는 `NTP=`가 비어 있을 때만 쓰이므로 이 구성에서는 의미가 없어 넣지 않았습니다.

## 같이 확인할 것

- **DC 쪽**: DC(특히 PDC Emulator)에서 Windows Time 서비스(w32time)가 NTP 서버로 동작해야 하며 UDP 123이 열려 있어야 합니다.
- **하이퍼바이저 시간 동기화**: VMware Tools 시간 동기화나 Hyper-V Time Synchronization 서비스가 게스트 NTP와 겹치면 시간이 흔들립니다. 하나만 사용하세요.
- **방화벽**: DC 조회에 UDP/TCP 389, 시간 동기화에 UDP 123이 필요합니다.
- **NTP 소스 불일치**: 외부 NTP에 동기화된 VM이라도 DC가 다른 시간원을 쓰면 서로 어긋날 수 있습니다. 이 설정은 VM의 NTP 소스를 DC로 맞추는 것이 목적입니다.

## 제거

```bash
sudo ./uninstall.sh
```
서비스·타이머·점검 스크립트와 timesyncd drop-in 을 제거합니다. `/etc/default/ad-time-check` 와 chrony 백업(`/etc/chrony/chrony.conf.bak.*`)은 남겨 두므로 필요 시 직접 복원하세요.
