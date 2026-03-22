
     =============================
       주말 리눅스(26.02.28) 과정
     =============================

=============================
        LINUX Lv1. OT
=============================

1. 비번 암호
* PC 아이디/암호: soldesk/soldesklove
* WIFI 비번: SecurityHacker/soldesk1.

2. 카카오 그룹(오픈 채팅방): 
* 검색: "리눅스 lv1 / 0228"
* 비번: sd506
* URL: https://open.kakao.com/o/gqWCnnii
* 가입하시면 글 한번 올려 주세요.

3. 강사 정보
* 강 사    : 백 승 찬
* 연락처   : 010-8815-6754     => 조퇴, 지각, 결석
* 이메일   : jang4sc@hanmail.net

    현) 솔데스크 전임강사
    현) 레드햇 공인강사, 시험감독관
    현) ITBANK 평생교육원 관리교수

4. 수업 폴더
    윈도우 탐색기(<WIN + e>)
    C:\리눅스주말(26.02.28)
        +-- 수업관련자료/*    => <WIN + E> => \\172.16.6.249 (soldesk/soldesklove)
            +-- 리눅스 기초
            +-- 리눅스 서버
            +-- 리눅스 네트워크
        +-- VM
            +-- main
            +-- server1
            +-- server2
        +-- Tools
        +-- 기타

    [참고] VMware Workstation pro 17.x | 25H2
    - 목적: OS Virtualization S/W
    - 예: Oracle VirtualBox, VMware Workstation

    [참고] LinuxCD - CentOS Stream 9
    * RHEL
        - CentOS-Stream-9-latest-x86_64-dvd1_2025_0412.iso
        => everything

5. 로컬 사용자를 위한 공유 디렉토리
    * 윈도우 탐색기(<WIN + e>)
    * \\172.16.6.249
        ID/PASS: soldesk/soldesklove, linux0804/soldesklove

6. 출석체크
    * 입실: 09:30 ~ 09:40(비콘 체크)
    * 퇴실: 18:30 ~ (비콘 체크)
    * 지각, 조퇴

7. 점심시간
    * 13:20 ~ 14:30

8. 강의 동영상 링크
   - https://drive.google.com/drive/folders/1luCBITRrmO2aVruU_M4K-tuyeu6ti8As?usp=drive_link


RedHat

* RedHat 6/7/8/9 -> RHEL 2/3/4/5/6/7/8/9/10
    |                       |
    V                       V
    fedora               CentOS


=============================
           선수 지식
=============================

1. 패키지 설치/삭제

 yum install -y gnome-tweaks
 yum remove -y gnome-tweaks
 yum list 'gnome-*'


2. 서비스 기동/종료

 systemctl enable --now firewalld
 systemctl disable --now firewalld


3. GUI -> TUI

 systemctl set-default multi-user.target
 systemctl isolate multi-user.target


4. 제어 문자
<CTL + C>, <CTR + D>


5. OS 셧다운/재부팅

■ 운영체제 전원 끄기(Power OFF)
 poweroff 
 init 0          /* 0: Runlevel 0 = Power Off */
 shutdown -h now    /* -h: halt */

■ 운영체제 재부팅(Reboot)
 reboot 
 init 6          /* 6: Runlevel 6 = reboot */
 shutdown -r now    /* -r: reboot */


=============================
제04장 암호변경 & 시스템 기본 정보 확인
=============================

1. 매뉴얼과 암호변경
    man CMD
         CMD --help 
         man CMD
        
         man ls
         man -k calendar
         man -f passwd
         man -s 5 passwd
    
    passwd CMD
         passwd fedora
        

2. 시스템 기본 정보 확인
    uname CMD
         uname -a
         cat /etc/centos-release
        
        [참고] docs.redhat.com
        https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/
    
    date CMD
         date 08301300
         date +%m%d
        
        [실무예] NTP 서버에 시간 동기화
         vi /etc/chrony.conf
        server 0.kr.pool.ntp.org iburst
         systemctl restart chronyd
         timedatectl
    
    cal CMD

=============================
제05장. 디렉토리/파일/기타 관리
=============================

    관리(administration)?
    
     man hier
     ls /

1. 디렉토리 관리
    1) 디렉토리 이동
        pwd CMD
        
            [실무예] PS1 변수(~/.bashrc)
             export PS1='[\u@\h \w]\$ '
             export PS1='\[\e[31;1m\][\u@\h\[\e[33;1m\] \w]\$ \[\e[m\]'
        
        cd CMD
            경로(PATH)
            * 상대경로:  cd dir1
            * 절대경로:  cd /dir1
    
            [실무예] 홈디렉토리로 이동
             cd
             cd ~
             cd /root
             cd $HOME
            
            [실무예] 사용자의 홈디렉토리로 이동
             cd ~fedora
            
            [실무예] 이전 디렉토리로 이동
             cd -
    
            [실무예] 옆에 디렉토리로 이동
             cd ../dir2
    
    
    2) 디렉토리 관리
        ls CMD
             ls -l
             ls -ld
            OPTIONS: -l, -d, -R, -F, -i, -h
        
            [실무예] alias ls(~/.bashrc)
             alias ls='ls --color=auto -h -F'
            
            [실무예] 가장 많이 사용되는 형식
             ls -altr
             ls -altr /LogDir
        
        mkdir CMD
             mkdir -p dir1/dir2
        
        rmdir CMD
             rm -rf dir1


2. 파일 관리
    touch CMD
         touch -t 08301300 file1
    
    cp CMD
         cp file1 file2
         cp file1 dir1
         cp -r dir1 dir2
        OPTIONS: -r, -i, -f
        
        [실무예] 설정 파일 복사(백업)
         cp -p httpd.conf httpd.conf.OLD
        
        [실무예] 소스 디렉토리 복사(백업)
         cp -a /was /was.OLD
        
        [실무예] 로그 파일 비우기
         > file.log
    
    mv CMD
         mv file1 file2
         mv file1 dir1
         mv dir1 dir2
        OPTIONS: -i, -f
        
        [참고] 와일드 카드 문자
        *  ?  {}  []
    
    rm CMD
         rm -rf dir1
        OPTIONS: -i, -f, -r
        
        [참고] rm CMD로 지운 파일 되살리기
        * extundelete CMD
        * xfs_undelete CMD
        * testdisk

3. 파일 내용 확인
    cat CMD
         cat -n file1
         cat file1 file2 > file3
    
    more CMD
         CMD | more
         cat /etc/services | more
         ps -ef | more
         netstat -antup | more
         systemctl list-unit-files
        
        [참고] cat vs more
    
    head CMD
        
        [실무예] alias pps
         alias pps='ps -ef | head -1; ps -ef | grep $1'
         pps rsyslogd
    
    tail CMD
         tail -f /var/log/messages
        
        [실무예] tail -f 
         tail -f /var/log/messages
         tail -f /var/log/messages /var/log/secure
         tail -f /var/log/messages | egrep -i 'warn|error|fail|crit|alert|emerg'


4. 기타 관리 명령

    wc CMD
    
        [실무예] 데이터 수집
         cat /etc/passwd | wc -l
         rpm -qa | wc -l
         ps -ef | wc -l
         ps -ef | grep httpd | wc -l
         df -h / | tail -1 | awk '{print $5}'
         cat /var/log/messages | grep -i 'Started Telnet Server' | grep 'Mar  7' | wc -l
    
    su CMD
         su - fedora
         su fedora
    sudo CMD
         sudo CMD
         sudo -i
         sudo -l
         sudo -l -U fedora
        
        [참고] su CMD vs sudo CMD
        
    *id CMD
    *groups CMD
    
    *last CMD
    *lastb CMD
    *lastlog CMD
    
    who CMD
    w CMD
         w -i user01
        
        [실무예] 모니터링 구문
         while true
        do
            CMD
            sleep 2
        done
    watch CMD
         watch 'CMD; CMD'
    
    *exit CMD
    
=============================
제06장. 파일 종류
=============================

파일의 종류
* 일반 파일
* 디렉토리 파일
* 링크 파일
    - 하드 링크 파일  ( ln file1 file2)
    - 심볼릭 링크 파일( ln -s file1 file2)
* 장치 파일


=============================
제07장. 파일 속성 관리
=============================

1. 소유자/그룹 변경
    chown CMD
         chown -R fedora:fedora dir1
    
    chgrp CMD

2. 퍼미션 변경
    chmod CMD
        퍼미션 변경 방법
        * 심볼릭 모드( chmod u+x file1)
        * 옥탈 모드  ( chmod 755 file1)
        
        파일&디렉토리 퍼미션의미
        * file(r/w/x)
        * directory(r(ls -l)/w(생성&삭제)/x(cd))
        
        umask CMD - 002|022|027|077
        * (관리자) /etc/bashrc, /etc/login.defs
        * (사용자) ~/.bashrc

=============================
제08장. VI/VIM 편집기
=============================

1. VI 편집기 실행
     vi file1

2. VI 편집기 기능
    1) 입력 모드
        i, a, o, O
    
    2) 명령 모드
        이동:
        삭제:
        Undo/Redo:
    
    3) 최하위행 모드
        복사&붙이기:
        검색:
        찾아서&바꾸기:
        저장&나가기:

3. VI 편집기 환경파일
    (관리자) /etc/vimrc
    (사용자) ~/.vimrc
    ----------------------
    syntax on
    set ai nu ts=4 sw=4 et
    ----------------------

=============================
제10장 관리자가 알아두면 유용한 명령
=============================

1. 파일 비교
    cmp/diff CMD

        [실무예] 파일 비교 - 현재 설정 파일과 백업 파일 비교
         diff httpd.conf httpd.conf.OLD
        
        [실무예] 디렉토리 비교 - 디렉토리 마이그레이션 이후 확인
         diff -r /was1 /was2

2. 파일 내용 정렬
    sort CMD
         CMD | sort -k 3
         CMD | sort -k 3 -r
        
        [실무예] 용량 점검
        * df CMD + du CMD + find CMD + lsof CMD
        
         df -hT
         du -sh /var
         cd /var ; du -sh * | sort -hr | more

3. 파일 종류 확인
    file CMD

=============================
제11장 파일 검색 및 고급 명령
=============================

1. 파일 내용 검색
    grep CMD
         grep OPTIONS PATTERN file1
        * OPTIONS: -l, -n, -r, -v, -i, -w, -A 
        * PATTERN: *  .  ^root  root$  [abc]
    
        [참고] CMD | grep root 
         cat /etc/passwd | grep root 
         rpm -qa | grep httpd 
         ps -ef | grep rsyslogd 
         netstat -antup | grep :22 
         systemctl list-unit-files | grep ssh 
        
        [참고] 정규표현식(Regular Expression)
        
        [참고] egrep/fgrep CMD
        * egrep == grep -E
        * fgrep == grep -F
        
        [실무예] chklog/chklog.sh
         alias chklog='cat $1 | egrep -i "warn|error|fail|crit|alert|emerg"'
         chklog /var/log/messages

2. 파일 찾기
    find CMD
         find /
         find / -name file1 -type f
         find / -user fedora -group fedora
         find / -mtime -7|7|+7
         find / -size -300M|300M|+300M
         find / -perm -755|755
         find / -name file1 -type f -exec CMD {} \;
        
        [실무예] 오래된 로그 파일 지우기
        * find CMD + crontab CMD
         find /LogDir -name "*.log" -type f -mtime +30 -exec rm -f {} \;

        [실무예] 갑자기 파일 시스템이 풀(full) 난 경우
        * df CMD + du CMD + find CMD + lsof CMD
         df -hT
         du -sh /var 
         cd /var ; du -sh * | sort -hr | more
         find /var -type f -mtime -2 -size +1G
        [참고] lsof /var/log/db/db.log


3. 고급 명령
    *sed CMD
    *awk CMD

=============================
제12장 압축과 아카이빙
=============================

1. 압축
    gzip/gunzip CMD
         gzip file1
         gunzip -c file1.gz
         gunzip file1.gz
    
    bzip2/bunzip2 CMD
         bzip2 file1
         bunzip2 -c file1.bz2
         bunzip2 file1.bz2
    
    xz/unxz CMD
         xz file1
         unxz -c file1.xz
         unxz file1.xz

2. 아카이빙
    tar CMD
         tar cvf file.tar file1 file2
         tar tvf file.tar
         tar xvf file.tar
    
    *cpio CMD


3. 압축 + 아카이빙
    tar CMD
         tar cvzf file.tar.gz file1 file2
         tar tvzf file.tar.gz
         tar xvzf file.tar.gz

         tar cvjf file.tar.bz2 file1 file2
         tar tvjf file.tar.bz2
         tar xvjf file.tar.bz2

         tar cvJf file.tar.xz file1 file2
         tar tvJf file.tar.xz
         tar xvJf file.tar.xz
    
    jar CMD
         jar cvf file.jar file1 file2
         jar tvf file.jar
         jar xvf file.jar
    
    zip/unzip CMD
         zip -r file.zip file1 file2
         unzip -l file.zip
         unzip file.zip

=============================
제13장 배시쉘의 특성
=============================

배시쉘 특성 - 명령어 해석기(Command Interpreter)
● 리다이렉션(Redirection): <, >, 2>
● 파이프(Pipe): |
● 쉘 기능(Shell Function): 
● 변수(Variable): PATH, PS1
● 메타캐릭터(Metacharacter): ''  ""  ``  ;
● 히스토리(History):
● 엘리어스(Alias):
● 환경파일(Environment Files): /etc/profile, ~/.bash_profile, ~/.bashrc


1) 리다이렉션(Redirection): <, >, 2>

    fd
    --------------------
    0   stdin
    1   stdout
    2   stderr
    --------------------
    
    (ㄱ) 입력 리다이렉션: <, 0< 
         wc -c < /etc/passwd
    (ㄴ) 출력 리다이렉션: >, >>, 
    (ㄷ) 에러 리다이렉션
    
    [실무예] 결과 메일 보내기
     mailx -s "[  OK  ] server1" admin@example.com < report.txt
    
    [실무예] 스크립트 로그 파일 생성 시
     ./script.sh > script.log 2>&1
    
    [실무예] 출력 내용이 많은 명령의 내용 분석을 위한 로그 파일 생성
     ./configure --prefix=/usr/local/apache2 > apache.log 2>&1
    
    [실무예] 일반 사용자가 에러메시지 출력이 많은 명령어 수행시 에러 메세지 출력 삭제하기
    $ find / -name file1 -type f 2>/dev/null

2) 파이프(Pipe): |
     CMD | more
     CMD | grep root
     CMD | CMD | ...
    
    [실무예] CMD | tee file.log
    1) 모니터링 구문에서 "CMD | tee -a file" 형식
         while true
        do
            CMD | tee -a file.log
            sleep 2
        done
    2) 여러 터미널의 출력 내용 공유하기
         script -a /dev/null | tee /dev/pts/1 | tee /dev/pts/2
    3) 일반 사용자가 sudo 명령어 수행 시 리다이렉션
        $ echo WEB | sudo tee /var/www/html/index.html
    
3) 쉘 기능(Shell Function): 

    [참고] <TAB>, <TAB><TAB>, ↑↓→←

4) 변수(Variable): PATH, PS1
    변수의 종류
    * 지역변수
    * 환경변수
    * 특수변수
    
    변수 선언 방법
    (선언)  export VAR=5
    (확인)  echo $VAR
    (해제)  unset VAR

    쉘 환경변수
    ● PS1 변수(export PS1='[\u@\h \w]\$ ')(~/.bashrc)
    ● PS2 변수
    ● PATH 변수(export PATH=$PATH:/root/bin)(~/.bashrc)
    ● HISTTIMEFORMAT 변수
    ● HOME 변수
    ● PWD 변수
    ● LOGNAME 변수
    ● USER 변수
    ● UID 변수
    ● TERM 변수
    ● LANG 변수
    ● SHELL 변수    

5) 메타캐릭터(Metacharacter): ''  ""  ``  \ ;

6) 히스토리(History):

    관련 변수
    * HISTSIZE
    * HISTFILE
    * HISTFILESIZE
    
    [참고] ble.sh
    * bash => autosuggestion

7) 엘리어스(Alias):
     alias cp='cp -i'
     alias
     unalias cp

8) 환경파일(Environment Files): /etc/profile, ~/.bash_profile, ~/.bashrc
    /etc/profile
        /etc/profile.d/{*.sh,sh.local}
        /etc/bashrc
    
    $HOME/.bash_profile
        ~/.bashrc
            /etc/bashrc
    
    $HOME/.bashrc
        /etc/bashrc
            /etc/profile.d/*.sh

=============================
제14장 프로세스 관리
=============================

1. 프로세스 정보
    * PID, PPID
    * /proc/PID/*

2. 프로세스 관리
    프로세스 실행
        fg)  CMD
        bg)  CMD &
        
        [참고] 백그라운드로 실행하는 경우
    
    프로세스 확인
         ps -ef | grep crond
         ps aux | grep crond
    
    프로세스 종료
         kill -9|-15 PID PID

3. 프로세스 모니터링
    top CMD
         top
        * 정열: cPu, Mem
        * 출력 내용 분석 <--- 
기타 모니터링 도구(epel-release 필요)
    * htop       : CPU/MEM
    * iotop      : DISK
    * iftop/bmon : NET
    * atop       : CPU/MEM/DISK/NET + Data Gathering
    * btop       : CPU/MEM/DISK/NET

=============================
제15장 원격접속과 파일전송
=============================

1. 원격 접속
    ssh CMD
         ssh 192.168.10.10
         ssh 192.168.10.10 'CMD'
        
        [실무예] 공개키 인증 방식
         ssh-keygen
         ssh-copy-id fedora@192.168.10.10

2. 파일 전송
    scp CMD
         scp file1 server2:/tmp
         scp server2:/tmp/file1 /test
         scp -r dir1 server2:/tmp
         scp main:/test/file1 server2:/test

=============================
제16장 디스크 관리 - 장치 인식
=============================

  ls /
    -> /dev/*
     man 7 hier
    
1. 선수지식
    디스크의 종류: 
        * HDD(Hard Disk Drive)
            - IDE(SATA)
            - SCSI(SAS))
        * SSD(Solide State Disk)
            - SSD
            - NVMe

    디스크 종류와 이름체계
    ■ IDE           (예: /dev/hd)      - /dev/hda, /dev/hdb, /dev/hdc, /dev/hdd
    ■ SCSI/SATA/SAS (예: /dev/sd)      - /dev/sda, /dev/sdb, /dev/sdc, ....
    ■ NVMe          (예: /dev/nvme0n1) - /dev/nvme0n1, /dev/nvme0n2, /dev/nvme0n3, ...
       /dev/nvme0n1, /dev/nvme0n2, /dev/nvme0n3, ....
        * nvme0: 장치 이름(예: /dev/nvme0) => NVMe 컨트롤러(controller) 번호
        * nY: 네임스페이스 이름(예: n1)    => 컨트롤러가 노출한 namespace(논리디바이스) 번호
        * pZ: 파티션 이름(예: p1)          => namespace(또는 블록 디바이스)상의 파티션 번호
    ■ virtio-blk 반가상화 스토리지(VM)  - /dev/vda, /dev/vdb, /dev/vdc, ...
    ■ virtio-scsi 반가상화 스토리지(VM) - /dev/sda, /dev/sdb, /dev/sdc, ...
    ■ SD/MMC/eMMC 스토리지(SD 카드)     - /dev/mmcblk0, /dev/mmcblk1, ....

2. 장치 인식 작업
     poweroff
    디스크 장착
    Power ON
    
     lsblk 

=============================
제17장 디스크 관리 - 파티션 작업
=============================

1. 선수지식

파티션 종류와 이름체계
* BIOS F/W -> MBR Partition Type
      Primary partition(1-4)
      Extended partition
      - Logical partition(5-15)   
 
* UEFI F/W -> GPT Partition Type
      Partition(1-128)

2. 파티션 작업
파티션 설정 툴 종류
    * fdisk CMD
         fdisk /dev/sdb
         fdisk -l /dev/sdb
    * gdisk CMD
         gdisk /dev/sdb
         gdisk -l /dev/sdb
    * parted CMD
        ?

=============================
제18장 디스크 관리 - 파일시스템 작업
=============================

1. 선수지식
    파일 시스템? 파일을 저장하고 관리하는 구조체계
    파일 시스템 종류
        * ext4 : 기능
        * xfs  : 성능(r/w)

2. 파일시스템 작업
    mkfs CMD
         mkfs.ext4 /dev/sdb1
         mkfs.xfs /dev/sdb1
        
         lsblk --fs

=============================
제19장 디스크 관리 - 마운트 작업
=============================

1. 마운트 확인
     df -hT
     mount

2. 마운트 관련 파일
    /etc/fstab
    /etc/mtab

3. 마운트 관련 명령
    mount CMD
         mount -t ext4 -o defaults /dev/sdb1 /oracle
        -t ext4: ext4, xfs
        -o defaults: rw, suid, dev, exec, auto, nouser, async
            => ro,remount
    umount CMD
         umount /testmount
         umount /dev/sdb1
        
        [실무예] target is busy
         fuser -cu /home
         fuser -ck /home
         umount /home
    mount -a CMD (/etc/fstab)
    umount -a CMD(/etc/mtab)

=============================   
제20장 파일시스템 점검 작업
=============================

파일 시스템 점검(umount 작업 후 fsck)
* (ext4) fsck /dev/sdb1
* (xfs ) xfs_repair /dev/sdb1

    [실무예] fsck -y
     fsck -y /dev/sdb1 2>&1 | tee fsck.log

=============================
제21장 파일시스템 용량 모니터링 작업
=============================

df CMD + du CMD + find CMD + lsof CMD
     df -hT
     du -sh /var
     cd /var ; du -sh * | sort -nr | more
     find /var -type f -size +1G
     lsof /var/log/messages

    [참고] 모니터링 툴 => 웹콘솔
     systemctl enable --now cockpit.socket
     firefox https://192.168.10.20:9090 &

=============================
제22장 LVM 관리
=============================

1. PV 관리
     pvcreate /dev/sdc1
     pvremove /dev/sdc1
    
     pvs
     pvdisplay /dev/sdc1

2. VG 관리
     vgcreate vg1 /dev/sdc1
     vgremove vg1
    
     vgs
     vgdiplay vg1
    
     vgextend vg1 /dev/sdd1
     vgreduce vg1 /dev/sdd1
    
     vgrename vg1 vg2

3. LV 관리

4. FS 관리

5. Mount 관리


=============================
제23장 네트워크 관리
=============================

=============================
제24장 SELinux 관리
=============================

=============================
제25장 방화벽 관리
=============================


