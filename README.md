🐧 주말 리눅스 과정 (25.12.13) 실습 기록
본 저장소는 솔데스크(Soldesk) 주말 리눅스(CentOS Stream 9) 과정의 강의 정보와 주요 실습 명령어를 정리한 공간입니다.
1. 강의 정보 및 접속 정보
강사: 백승찬 (jang4sc@hanmail.net)
오픈채팅방: 리눅스 lv1 / 0228 (비번: sd506)
강의 영상: Google Drive 링크
실습 환경:
PC ID/PW: soldesk / soldesklove
WIFI PW: SecurityHacker / soldesk1.
OS: CentOS Stream 9 (VMware Workstation 17.x)
2. 필수 선수 지식 (Quick Reference)
패키지 및 서비스 관리
bash
# 패키지 설치/삭제
yum install -y gnome-tweaks
yum remove -y gnome-tweaks

# 서비스 기동/종료
systemctl enable --now firewalld
systemctl disable --now firewalld

# GUI <-> TUI 모드 전환
systemctl set-default multi-user.target  # TUI 모드 설정
systemctl isolate multi-user.target      # 즉시 전환
코드를 사용할 때는 주의가 필요합니다.

시스템 종료 및 재부팅
구분	명령어
Power OFF	poweroff, init 0, shutdown -h now
Reboot	reboot, init 6, shutdown -r now
3. 주요 실습 명령어 요약
제04장. 암호 변경 & 시스템 정보
도움말 확인: man [명령어], [명령어] --help
시스템 정보: uname -a, cat /etc/centos-release
시간 동기화 (NTP):
bash
vi /etc/chrony.conf
# server 0.kr.pool.ntp.org iburst 추가 후
systemctl restart chronyd
timedatectl
코드를 사용할 때는 주의가 필요합니다.

제05장. 디렉토리 및 파일 관리
디렉토리 이동 및 확인
pwd: 현재 경로 확인
cd ~: 홈 디렉토리 이동 / cd -: 이전 디렉토리 이동
ls -altr: 파일 상세 목록을 시간 역순으로 출력
파일/디렉토리 조작
생성: mkdir -p dir1/dir2 (계층 생성), touch file1
복사: cp -p (권한 유지 백업), cp -a (디렉토리 전체 백업)
삭제: rm -rf [경로] (강제 삭제 시 주의)
내용 확인: cat, more, head, tail (로그 확인 시 tail -f 권장)
4. 로컬 공유 디렉토리
경로: \\172.16.6.249
계정: soldesk / soldesklove