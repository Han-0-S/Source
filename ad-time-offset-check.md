# ad-time-offset-check.sh: AD DC 시간차 점검 스크립트

AD 도메인 컨트롤러(DC)와의 시간차(오프셋)를 확인하고, 허용치를 넘으면 경고하는 간단한 점검 스크립트(`ad-time-offset-check.sh`)입니다. 앞서 안내한 "간단한 점검 스크립트(오프셋 초과 시 경고)" 내용을 파일로 만든 것입니다.

**목차**

1. 사용법
2. 동작 방식
3. 종료 코드
4. 출력 예시
5. 활용 예
6. 테스트 범위와 참고
7. 전체 코드

## 1. 사용법

```bash
chmod +x ad-time-offset-check.sh

./ad-time-offset-check.sh                            # 스크립트 안의 기본값 사용
./ad-time-offset-check.sh dc01.corp.example.com      # DC만 지정
./ad-time-offset-check.sh dc01.corp.example.com 60   # DC + 허용 오프셋 60초
```

필요 패키지: `samba-common-bin` (`net` 명령). 설치: `sudo apt install samba-common-bin`

## 2. 동작 방식

- `net ads info -S <DC>` 출력의 `Server time offset` 값을 읽습니다. (VM과 DC의 시간차, 초 단위)
- 음수 오프셋도 처리하도록 절대값으로 바꾼 뒤 허용치(`LIMIT`)와 비교합니다.
- DC 주소와 허용 오프셋은 인자로 줄 수 있고, 생략하면 기본값(`dc01.corp.example.com`, 120초)을 씁니다.
- `net` 명령이 없으면 설치 안내를 출력하고 종료합니다.
- Kerberos 한계는 300초이며, 허용치는 여유를 두고 정하세요. 더 엄격하게 보려면 60초 이하를 권장합니다.

## 3. 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 정상 (허용 범위 이내) |
| 1 | 경고 (시간차가 허용치 초과) |
| 2 | DC 조회 실패 (네트워크/DNS 확인) 또는 `net` 명령 없음 |

종료 코드가 있어서 cron, 모니터링 도구, 다른 스크립트에서 결과를 판별하는 데 쓸 수 있습니다.

## 4. 출력 예시

```text
정상: DC와 시간차 3초
경고: DC와 시간차 400초
DC 조회 실패 (네트워크/DNS 확인)
net 명령이 없습니다. 설치: sudo apt install samba-common-bin
```

## 5. 활용 예

```bash
# cron: 10분마다 점검하고 이상 시 syslog 에 기록
*/10 * * * * /usr/local/bin/ad-time-offset-check.sh dc01.corp.example.com 60 || logger -t ad-time "AD 시간차 이상 (exit=$?)"

# 다른 스크립트에서 사용: 이상이 있으면 sssd 재시작 전에 시간 보정
if ! ./ad-time-offset-check.sh dc01.corp.example.com 60; then
  sudo chronyc makestep   # chrony 사용 시 (timesyncd 는 systemctl restart systemd-timesyncd)
fi
```

## 6. 테스트 범위와 참고

- `net` 명령을 흉내 낸 가짜 명령으로 정상, 초과, 음수 오프셋, 조회 실패, `net` 없음 경우를 확인했습니다. 실제 AD 환경에서는 실행해 보지 못했습니다.
- `net ads info`가 응답하지 않으면 `ldapsearch`(ldap-utils) 또는 `ntpdate -q`로 측정하는 방식으로 바꿀 수 있습니다.
- `net ads info`가 보여 주는 값은 초 단위 정수라서 1초 미만의 정밀한 비교에는 적합하지 않습니다.

## 7. 전체 코드

```bash
#!/usr/bin/env bash
#
# ad-time-offset-check.sh
# AD 도메인 컨트롤러(DC)와의 시간차(오프셋)를 확인하고, 허용치를 넘으면 경고합니다.
#
# 사용법:
#   ./ad-time-offset-check.sh [DC주소] [허용오프셋(초)]
#
# 예:
#   ./ad-time-offset-check.sh                                # 아래 기본값 사용
#   ./ad-time-offset-check.sh dc01.corp.example.com          # DC만 지정
#   ./ad-time-offset-check.sh dc01.corp.example.com 60       # DC + 허용 오프셋 60초
#
# 종료 코드:
#   0 = 정상 (허용 범위 이내)
#   1 = 경고 (시간차가 허용치 초과)
#   2 = DC 조회 실패 (네트워크/DNS 확인)
#
# 필요 패키지: samba-common-bin (net 명령)

DC=${1:-dc01.corp.example.com}   # 점검할 DC
LIMIT=${2:-120}                  # 허용 오프셋(초). Kerberos 한계는 300초

if ! command -v net >/dev/null 2>&1; then
  echo "net 명령이 없습니다. 설치: sudo apt install samba-common-bin"
  exit 2
fi

off=$(net ads info -S "$DC" 2>/dev/null | awk -F': *' '/Server time offset/ {print $2}')
[[ -z $off ]] && { echo "DC 조회 실패 (네트워크/DNS 확인)"; exit 2; }

off=${off#-}   # 절대값

if (( off > LIMIT )); then
  echo "경고: DC와 시간차 ${off}초"
  exit 1
else
  echo "정상: DC와 시간차 ${off}초"
fi
```
