# Linux Lv1 시스템 관리 기초
## 직무교육 강의자료

- **교육 과정:** Linux Lv1
- **대상 환경:** CentOS Stream 9 / RHEL 계열
- **교육 방식:** 이론 설명 + 가상머신 실습
- **자료 구성:** 교육 목표, 핵심 명령어, 실습, 평가 문제

> 안전 안내: 디스크 파티션·포맷·삭제, 파일시스템 축소, 네트워크 및 방화벽 변경은 데이터 손실이나 접속 중단을 일으킬 수 있습니다. 교육용 가상머신에서 먼저 실습하고, 운영 환경에서는 백업과 승인 절차를 확인하세요.

---

## 1. 교육 목표 및 학습 흐름

교육을 마치면 다음 작업을 수행할 수 있습니다.

- Linux 셸에서 도움말을 찾고 시스템 기본 정보를 확인한다.
- 파일과 디렉터리를 생성·복사·이동·검색하고 내용을 확인한다.
- 소유권과 권한을 이해하고 편집기, 리다이렉션, 파이프를 활용한다.
- 프로세스와 원격 접속을 관리하고 디스크·파일시스템을 점검한다.
- 네트워크, SELinux, firewalld의 기본 상태를 확인한다.

## 2. 실습 환경과 안전 수칙

- 권장 환경: VMware Workstation 또는 Oracle VirtualBox 가상머신
- 배포판 예시: CentOS Stream 9 / RHEL 계열
- 실습 전 가상머신 스냅샷 또는 중요 설정 파일 백업
- 디스크 장치명과 용량, 마운트 상태를 확인한 뒤 스토리지 명령 실행
- 운영 서버에서는 승인 없이 방화벽·네트워크·스토리지 설정을 변경하지 않기
- 계정 비밀번호와 개인 연락처를 문서나 스크립트에 평문으로 남기지 않기

## 3. Linux 관리 작업의 기본 원칙

- 현재 위치와 대상 확인: `pwd`, `ls`, `lsblk`, `df -hT`
- 변경 전 백업: `cp -p 설정파일 설정파일.OLD`
- 명령어의 대상과 옵션을 이해한 뒤 실행
- 관리자 권한은 필요한 순간에만 사용: `sudo`
- 작업 후 상태 명령과 로그를 통해 결과 검증
- `rm -rf`, `mkfs`, `lvreduce` 등 위험 명령은 테스트 환경에서 충분히 확인

## 4. 도움말과 시스템 기본 정보

### 핵심 명령어

| 명령어 | 용도 |
|---|---|
| `man CMD` | 명령어 매뉴얼 |
| `CMD --help` | 주요 옵션 도움말 |
| `man -k calendar` | 키워드로 매뉴얼 검색 |
| `man -f passwd` | 매뉴얼의 간단한 설명 |
| `uname -a` | 커널 및 시스템 정보 |
| `cat /etc/centos-release` | 배포판 정보 확인(시스템에 따라 파일이 다를 수 있음) |
| `date` | 날짜와 시간 확인 |
| `cal` | 달력 출력 |
| `timedatectl` | 시간대와 시간 동기화 상태 확인 |

### 시간 동기화 참고

원본 노트에는 `/etc/chrony.conf`에 NTP 서버를 설정하고 `chronyd`를 재시작하는 예제가 있습니다. 실제 적용 전에는 운영 환경의 시간 동기화 정책과 서버 주소를 확인하세요.

## 5. 사용자 암호와 권한 상승

- `passwd`: 현재 사용자의 암호 변경
- `passwd 사용자명`: 권한이 허용되는 경우 지정 사용자의 암호 변경
- `su - 사용자명`: 대상 사용자의 로그인 환경으로 전환
- `sudo -l`: 현재 사용자가 실행할 수 있는 sudo 명령 확인
- `id`, `groups`: 사용자 ID와 그룹 정보 확인
- `who`, `w`, `last`: 로그인 사용자 및 로그인 기록 확인

보안 원칙: 암호를 문서·스크립트·채팅에 평문으로 저장하지 않습니다.

## 6. 디렉터리 이동과 목록 확인

| 명령어 | 설명 |
|---|---|
| `pwd` | 현재 작업 디렉터리 |
| `cd /경로` | 절대경로로 이동 |
| `cd dir1` | 상대경로로 이동 |
| `cd` 또는 `cd ~` | 홈 디렉터리로 이동 |
| `cd -` | 이전 작업 디렉터리로 이동 |
| `cd ..` | 상위 디렉터리로 이동 |
| `ls -l` | 상세 목록 |
| `ls -al` | 숨김 파일을 포함한 상세 목록 |
| `ls -ld 디렉터리` | 디렉터리 자체의 속성 확인 |
| `mkdir -p dir1/dir2` | 상위 경로를 포함해 디렉터리 생성 |
| `rmdir dir1` | 비어 있는 디렉터리 제거 |
| `rm -r dir1` | 디렉터리와 하위 항목 제거(주의 필요) |

### 경로 예제

```bash
cd /var/log
pwd
ls -al
cd -
```

## 7. 파일 복사·이동·삭제

| 명령어 | 설명 |
|---|---|
| `touch file1` | 파일 생성 또는 수정 시간 갱신 |
| `cp file1 file2` | 파일 복사 |
| `cp -r dir1 dir2` | 디렉터리 복사 |
| `cp -p file1 file1.OLD` | 파일 속성과 시간을 보존하며 백업 복사 |
| `mv file1 file2` | 이름 변경 또는 이동 |
| `rm -i file1` | 삭제 전 확인 |
| `rm -r dir1` | 디렉터리 재귀 삭제 |

와일드카드: `*`는 여러 문자, `?`는 한 문자, `[abc]`는 지정한 문자 중 하나를 나타냅니다.

## 8. 파일 내용 확인과 로그 모니터링

| 명령어 | 설명 |
|---|---|
| `cat -n file1` | 줄 번호와 함께 출력 |
| `more` 또는 `less` | 긴 출력을 페이지 단위로 확인 |
| `head file1` | 파일 앞부분 확인 |
| `tail file1` | 파일 끝부분 확인 |
| `tail -f /var/log/messages` | 로그 변경 사항 실시간 확인 |
| `wc -l file1` | 줄 수 확인 |
| `wc -c file1` | 바이트 수 확인 |

### 실습 1 — 파일 관리 기본기

```bash
mkdir -p ~/linux-practice/logs
cd ~/linux-practice
touch app.log
echo "INFO service started" > app.log
echo "ERROR connection failed" >> app.log
cat -n app.log
grep -in "error" app.log
cp -p app.log app.log.OLD
diff app.log app.log.OLD
```

확인 질문: `>`와 `>>`의 차이는 무엇인가요?

## 9. 파일 종류와 링크

- **일반 파일:** 텍스트, 실행 파일, 데이터 파일 등
- **디렉터리:** 파일과 하위 디렉터리 이름을 관리
- **하드 링크:** 같은 파일 데이터(inode)를 가리키는 다른 이름
- **심볼릭 링크:** 대상 경로를 가리키는 링크
- **장치 파일:** `/dev` 아래에서 장치 인터페이스 제공

```bash
ln file1 file1.hard
ln -s file1 file1.link
ls -li file1*
```

## 10. 소유권과 퍼미션

### 소유권 명령어

- `chown 사용자:그룹 파일`: 소유자와 그룹 변경
- `chgrp 그룹 파일`: 그룹만 변경

### 권한 명령어

- `chmod u+x script.sh`: 소유자에게 실행 권한 추가
- `chmod 755 script.sh`: 소유자 `rwx`, 그룹과 기타 사용자 `r-x`
- `umask`: 새 파일·디렉터리에 적용할 기본 권한에서 제거할 비트 지정

파일 권한 `r/w/x`는 읽기/쓰기/실행을 의미합니다. 디렉터리에서는 `r`은 목록 조회, `w`는 항목 생성·삭제, `x`는 디렉터리 통과 권한과 관련됩니다.

### 실습 2 — 권한 확인

```bash
touch report.txt
ls -l report.txt
chmod 640 report.txt
ls -l report.txt
mkdir private
chmod 700 private
ls -ld private
umask
```

`640`은 소유자 `rw-`, 그룹 `r--`, 기타 사용자 `---`를 뜻합니다.

## 11. vi/vim 편집기 핵심

- 실행: `vi file1`
- 입력 모드: `i`(커서 앞), `a`(커서 뒤), `o`(아래 새 줄), `O`(위 새 줄)
- `Esc`: 명령 모드로 복귀
- 검색: `/문자열`, 다음 결과는 `n`
- 저장: `:w`
- 저장 후 종료: `:wq`
- 저장하지 않고 종료: `:q!`
- 사용자 설정 파일: `~/.vimrc`

## 12. 파일 비교·정렬·형식 확인

- `diff file1 file2`: 텍스트 파일 차이 비교
- `diff -r dir1 dir2`: 디렉터리 트리 비교
- `cmp file1 file2`: 바이트 단위 비교
- `sort`: 줄 정렬
- `sort -k 3`: 세 번째 필드 기준 정렬
- `file filename`: 파일 형식 추정

용량 분석에는 `df`, `du`, `find`, `lsof`를 함께 활용할 수 있습니다.

## 13. 파일 검색: grep과 find

### grep

- `grep -n PATTERN file`: 일치 줄과 줄 번호 출력
- `grep -i`: 대소문자 무시
- `grep -v`: 패턴과 일치하지 않는 줄 출력
- `grep -r`: 하위 경로 검색
- `grep -E`: 확장 정규표현식 사용

### find

- `find /경로 -name '*.log' -type f`: 이름과 유형으로 검색
- `find /경로 -mtime +30`: 30일보다 오래 전에 수정된 파일 검색
- `find /경로 -size +1G -type f`: 1GB 초과 파일 검색

### 실습 3 — 오래된 로그 후보 확인

```bash
# 삭제하지 않고 먼저 대상 목록을 확인
find /LogDir -name "*.log" -type f -mtime +30 -print
```

검색 결과를 검토하고 보관 정책과 백업 상태를 확인하기 전에는 삭제 명령을 실행하지 않습니다.

## 14. 압축과 아카이빙

| 명령어 | 용도 |
|---|---|
| `gzip file1` | gzip 압축 |
| `gunzip file1.gz` | gzip 압축 해제 |
| `bzip2 file1` | bzip2 압축 |
| `xz file1` | xz 압축 |
| `tar cvf archive.tar file1 file2` | 아카이브 생성 |
| `tar tvf archive.tar` | 아카이브 목록 확인 |
| `tar xvf archive.tar` | 아카이브 해제 |
| `tar czf archive.tar.gz dir/` | gzip 압축 아카이브 생성 |
| `zip -r archive.zip dir/` | ZIP 파일 생성 |
| `unzip -l archive.zip` | ZIP 목록 확인 |

압축 해제 전에는 파일 목록과 대상 디렉터리를 확인하세요.

## 15. Bash 셸 — 리다이렉션과 파이프

- 표준 입력(stdin): 파일 디스크립터 `0`
- 표준 출력(stdout): 파일 디스크립터 `1`
- 표준 오류(stderr): 파일 디스크립터 `2`
- `> file`: 출력 덮어쓰기
- `>> file`: 출력 이어쓰기
- `2> error.log`: 오류 출력 저장
- `CMD > output.log 2>&1`: 표준 출력과 오류를 같은 파일로 저장
- `CMD | grep root`: 명령 출력 필터링
- `tee file.log`: 화면 출력과 파일 기록을 함께 수행

예제:

```bash
ls -l > files.txt
find / -name "file1" 2>/dev/null
ps -ef | grep sshd
```

## 16. 셸 변수·별칭·히스토리

- 변수 선언: `export VAR=5`
- 확인: `echo "$VAR"`
- 해제: `unset VAR`
- `PATH`: 실행 파일 검색 경로
- `PS1`: 프롬프트 표시 형식
- 별칭 예: `alias ll='ls -alh'`
- 별칭 제거: `unalias ll`
- 히스토리 변수: `HISTSIZE`, `HISTFILE`, `HISTFILESIZE`
- 주요 환경 파일: `/etc/profile`, `~/.bash_profile`, `~/.bashrc`

## 17. 프로세스 확인과 관리

- `ps -ef`: 프로세스 목록
- `ps aux`: 프로세스 목록(다른 형식)
- `top`: CPU·메모리 사용량을 실시간으로 관찰
- `command &`: 백그라운드 실행
- `kill PID`: 기본 종료 신호(SIGTERM) 전송
- `kill -9 PID`: 강제 종료. 정상 종료가 되지 않을 때 신중하게 사용
- `htop`, `iotop`, `iftop`, `bmon`, `atop`, `btop`: 추가 설치가 필요할 수 있는 모니터링 도구

## 18. 원격 접속과 파일 전송

- `ssh user@host`: 원격 시스템 접속
- `ssh user@host 'command'`: 원격에서 명령 실행
- `ssh-keygen`: 공개키·개인키 생성
- `ssh-copy-id user@host`: 공개키 등록
- `scp file user@host:/tmp/`: 파일 전송
- `scp -r dir user@host:/tmp/`: 디렉터리 전송

원격 서버의 주소와 계정 권한을 확인하고 개인키 파일을 안전하게 보호하세요.

## 19. 디스크 장치와 파티션

### 장치 확인

```bash
lsblk
lsblk --fs
```

대표 장치 이름 예:

- SATA/SCSI: `/dev/sda`, `/dev/sdb`
- NVMe: `/dev/nvme0n1`
- 가상머신의 virtio-blk: `/dev/vda`

### 파티션 도구

- `fdisk`
- `gdisk`
- `parted`

MBR과 GPT는 파티션 구성 방식입니다. 파티션 작업 전 디스크의 모델·용량·마운트 상태와 백업 여부를 확인하세요.

## 20. 파일시스템 생성과 마운트

- 파일시스템 예: ext4, XFS
- `mkfs.ext4 /dev/sdb1`: 지정 파티션에 ext4 생성 — 기존 데이터가 손실될 수 있음
- `mount /dev/sdb1 /mnt/data`: 파일시스템 연결
- `df -hT`, `mount`: 마운트 상태 확인
- `/etc/fstab`: 부팅 시 자동 마운트 설정
- `umount /mnt/data`: 마운트 해제

마운트 해제에 실패하면 사용 중인 프로세스를 확인합니다. 운영 중인 파일시스템을 임의로 강제 해제하지 마세요.

## 21. 파일시스템 점검과 용량 모니터링

- 파일시스템 점검·복구 전 백업과 언마운트 상태를 확인
- ext 계열: `fsck` 사용
- XFS: `xfs_repair` 사용
- `df -hT`: 파일시스템별 사용량
- `du -sh /var`: 디렉터리 전체 용량
- `du -sh * | sort -hr`: 현재 위치의 항목을 용량순으로 정렬
- `find /var -type f -size +1G`: 1GB 초과 파일 검색
- `lsof`: 열린 파일과 이를 사용하는 프로세스 확인

## 22. LVM 개념과 주요 명령

### 주요 개념

- **PV (Physical Volume):** LVM에 편입하는 물리 장치 또는 파티션
- **VG (Volume Group):** PV를 묶은 저장 공간 풀
- **LV (Logical Volume):** VG에서 할당한 논리 볼륨

### 기본 명령 예

```bash
pvcreate /dev/sdc1
pvs

vgcreate vg1 /dev/sdc1
vgs

lvcreate -L 1G -n lv1 vg1
lvs
```

위 예제는 `/dev/sdc1`을 초기화하므로, 실습용으로 준비한 장치인지 반드시 확인해야 합니다.

## 23. LVM 실무 시나리오

- **시나리오 A:** VG에 여유 공간이 있으면 LV와 파일시스템 확장
- **시나리오 B:** 여유 공간이 없으면 새 PV를 VG에 추가한 뒤 LV 확장
- **시나리오 C:** PV 교체 시 `pvmove`로 데이터를 이동한 뒤 기존 PV 제거
- 용량 감소는 파일시스템 유형별 지원 조건을 확인해야 함
- XFS는 일반적으로 축소를 지원하지 않으므로, 단순히 `lvreduce -r`을 실행하지 않기

확장 작업 예시(장치와 볼륨 이름은 실습 환경에 맞게 조정):

```bash
vgextend vg1 /dev/sdf1
lvextend -l +100%FREE -r /dev/vg1/lv1
```

## 24. 네트워크 관리

- NetworkManager: 네트워크 장치와 연결 프로파일 관리
- `ip address`: IP 주소 확인
- `ip route`: 라우팅 테이블 확인
- `cat /etc/resolv.conf`: DNS 설정 확인
- `nmcli`: 명령행 설정 도구
- `nmtui`: 텍스트 UI 설정 도구
- `nm-connection-editor`: 그래픽 설정 도구

IP 변경, NIC 추가, 다중 IP, 호스트명 변경, 본딩 작업은 변경 후 연결 상태를 검증합니다. 원격 접속 중 네트워크를 변경하면 연결이 끊길 수 있으므로 콘솔 접근 방법을 확보하세요.

## 25. SELinux와 firewalld

### SELinux

SELinux는 프로세스가 접근할 수 있는 자원을 보안 정책으로 제한합니다.

- `enforcing`: 정책 적용
- `permissive`: 접근을 차단하지 않고 관련 내용을 기록
- `disabled`: 비활성화
- `sestatus`: 현재 상태 확인
- `setenforce 0`: 실행 중인 시스템을 일시적으로 permissive 모드로 전환

보안 문제를 해결하기 위해 SELinux를 무조건 끄지 말고 로그와 정책을 먼저 확인하세요.

### firewalld

- `firewalld`: 동적으로 방화벽 규칙을 관리
- `zone`: 규칙 영역
- `service`: 포트·프로토콜 묶음
- `port`: 포트/프로토콜
- `firewall-cmd`, `firewall-config`: 규칙 관리 도구

방화벽 변경 전에는 필요한 통신과 허용 범위를 확인하고, 원격 접속이 차단되지 않도록 주의합니다.

## 26. 통합 실습 — 서버 상태 점검

```bash
hostnamectl
uname -a
ip address
ip route
df -hT
free -h
ps -ef | head
systemctl --failed
sestatus
firewall-cmd --state
```

### 실습 과제

1. `/var`의 전체 용량과 하위 디렉터리별 용량을 확인한다.
2. 최근 2일 이내 생성·수정된 대용량 파일을 검색한다.
3. 시스템 로그에서 `warn`, `error`, `fail` 관련 항목을 찾는다.
4. 실패 상태의 systemd 유닛을 확인하고 원인을 추정한다.
5. 실행 명령, 확인 결과, 조치 제안, 위험 요소를 작업 기록으로 남긴다.

### 평가 기준

- 명령 선택: 30%
- 결과 해석: 30%
- 안전 절차: 25%
- 작업 기록: 15%

## 27. 복습 퀴즈

1. 현재 작업 디렉터리를 확인하는 명령은?
2. `>`와 `>>`는 어떻게 다른가?
3. `chmod 640 파일`의 권한을 설명하라.
4. `df`와 `du`의 차이는?
5. PID를 확인하고 프로세스를 정상 종료하려면?
6. PV, VG, LV의 관계를 설명하라.
7. SELinux permissive 모드에서는 무엇이 달라지는가?
8. 디스크 포맷 전에 반드시 확인해야 할 사항은?

## 28. 강사용 정답

1. `pwd`
2. `>`는 덮어쓰기, `>>`는 이어쓰기
3. 소유자 `rw-`, 그룹 `r--`, 기타 사용자 `---`
4. `df`는 파일시스템 사용량, `du`는 파일·디렉터리 사용량
5. `ps` 등으로 PID를 확인한 뒤 `kill PID`로 정상 종료 요청
6. PV를 묶어 VG를 만들고, VG 공간을 LV에 할당
7. 정책 위반을 차단하지 않고 관련 내용을 기록
8. 장치명·용량·파티션·마운트 상태·백업 여부를 재확인

## 29. 참고 자료 및 강의 운영 메모

- 기준 자료: 사용자가 제공한 Linux Lv1 강의 노트
- 배포판 공식 문서: Red Hat Enterprise Linux 문서
- 명령어별 옵션은 `man CMD` 및 `CMD --help`로 확인
- 실습 장치명(`/dev/sdb` 등), IP, 사용자명은 실제 교육 환경에 맞게 변경
- 강의 전 실습 명령을 교육용 가상머신에서 검증하고 스냅샷을 준비
- 원본에 포함된 계정 비밀번호와 개인 연락처는 배포용 자료에서 제외

---

## 강의 진행 권장안

| 단계 | 진행 내용 | 권장 방식 |
|---|---|---|
| 도입 | 교육 목표와 가상머신 확인 | 강사 설명 |
| 기초 | 도움말, 파일·디렉터리, 권한 | 명령어 시연 후 따라 하기 |
| 셸·프로세스 | 파이프, 리다이렉션, 프로세스, SSH | 짧은 실습 반복 |
| 스토리지 | 디스크, 파일시스템, LVM | 스냅샷이 있는 VM에서만 실습 |
| 네트워크·보안 | IP, SELinux, firewalld | 상태 확인 중심 |
| 마무리 | 통합 실습과 퀴즈 | 결과 기록 및 피드백 |
