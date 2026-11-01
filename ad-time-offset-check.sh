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
