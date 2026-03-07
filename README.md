🐧    
    ###################################
        주말 리눅스(26.02.28) 과정
    ###################################

###############################
LINUX Lv1. OT
###############################
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


###############################
선수 지식
###############################

1. 패키지 설치/삭제

# yum install -y gnome-tweaks
# yum remove -y gnome-tweaks
# yum list 'gnome-*'


2. 서비스 기동/종료

# systemctl enable --now firewalld
# systemctl disable --now firewalld


3. GUI -> TUI

# systemctl set-default multi-user.target
# systemctl isolate multi-user.target


4. 제어 문자
<CTL + C>, <CTR + D>


5. OS 셧다운/재부팅

■ 운영체제 전원 끄기(Power OFF)
# poweroff 
# init 0          /* 0: Runlevel 0 = Power Off */
# shutdown -h now    /* -h: halt */

■ 운영체제 재부팅(Reboot)
# reboot 
# init 6          /* 6: Runlevel 6 = reboot */
# shutdown -r now    /* -r: reboot */


############################
제04장 암호변경 & 시스템 기본 정보 확인
############################

1. 매뉴얼과 암호변경
    man CMD
        # CMD --help 
        # man CMD
        
        # man ls
        # man -k calendar
        # man -f passwd
        # man -s 5 passwd
    
    passwd CMD
        # passwd fedora
        

2. 시스템 기본 정보 확인
    uname CMD
        # uname -a
        # cat /etc/centos-release
        
        [참고] docs.redhat.com
        https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/
    
    date CMD
        # date 08301300
        # date +%m%d
        
        [실무예] NTP 서버에 시간 동기화
        # vi /etc/chrony.conf
        server 0.kr.pool.ntp.org iburst
        # systemctl restart chronyd
        # timedatectl
    
    cal CMD

###############################
제05장. 디렉토리/파일/기타 관리
###############################

    관리(administration)?
    
    # man hier
    # ls /

1. 디렉토리 관리
    1) 디렉토리 이동
        pwd CMD
        
            [실무예] PS1 변수(~/.bashrc)
            # export PS1='[\u@\h \w]\$ '
            # export PS1='\[\e[31;1m\][\u@\h\[\e[33;1m\] \w]\$ \[\e[m\]'
        
        cd CMD
            경로(PATH)
            * 상대경로: # cd dir1
            * 절대경로: # cd /dir1
    
            [실무예] 홈디렉토리로 이동
            # cd
            # cd ~
            # cd /root
            # cd $HOME
            
            [실무예] 사용자의 홈디렉토리로 이동
            # cd ~fedora
            
            [실무예] 이전 디렉토리로 이동
            # cd -
    
            [실무예] 옆에 디렉토리로 이동
            # cd ../dir2
    
    
    2) 디렉토리 관리
        ls CMD
            # ls -l
            # ls -ld
            OPTIONS: -l, -d, -R, -F, -i, -h
        
            [실무예] alias ls(~/.bashrc)
            # alias ls='ls --color=auto -h -F'
            
            [실무예] 가장 많이 사용되는 형식
            # ls -altr
            # ls -altr /LogDir
        
        mkdir CMD
            # mkdir -p dir1/dir2
        
        rmdir CMD
            # rm -rf dir1


2. 파일 관리
    touch CMD
        # touch -t 08301300 file1
    
    cp CMD
        # cp file1 file2
        # cp file1 dir1
        # cp -r dir1 dir2
        OPTIONS: -r, -i, -f
        
        [실무예] 설정 파일 복사(백업)
        # cp -p httpd.conf httpd.conf.OLD
        
        [실무예] 소스 디렉토리 복사(백업)
        # cp -a /was /was.OLD
        
        [실무예] 로그 파일 비우기
        # > file.log
    
    mv CMD
        # mv file1 file2
        # mv file1 dir1
        # mv dir1 dir2
        OPTIONS: -i, -f
        
        [참고] 와일드 카드 문자
        *  ?  {}  []
    
    rm CMD
        # rm -rf dir1
        OPTIONS: -i, -f, -r
        
        [참고] rm CMD로 지운 파일 되살리기
        * extundelete CMD
        * xfs_undelete CMD
        * testdisk
-------------------------------

3. 파일 내용 확인
    cat CMD
        # cat -n file1
        # cat file1 file2 > file3
    
    more CMD
        # CMD | more
        # cat /etc/services | more
        # ps -ef | more
        # netstat -antup | more
        # systemctl list-unit-files
        
        [참고] cat vs more
    
    head CMD
        
        [실무예] alias pps
        # alias pps='ps -ef | head -1; ps -ef | grep $1'
        # pps rsyslogd
    
    tail CMD
        # tail -f /var/log/messages
        
        [실무예] tail -f 
        # tail -f /var/log/messages
        # tail -f /var/log/messages /var/log/secure
        # tail -f /var/log/messages | egrep -i 'warn|error|fail|crit|alert|emerg'


4. 기타 관리 명령

    wc CMD
    
        [실무예] 데이터 수집
        # cat /etc/passwd | wc -l
        # rpm -qa | wc -l
        # ps -ef | wc -l
        # ps -ef | grep httpd | wc -l
        # df -h / | tail -1 | awk '{print $5}'
        # cat /var/log/messages | grep -i 'Started Telnet Server' | grep 'Mar  7' | wc -l
    
    su CMD
        # su - fedora
        # su fedora
    sudo CMD
        # sudo CMD
        # sudo -i
        # sudo -l
        # sudo -l -U fedora
        
        [참고] su CMD vs sudo CMD
        
    *id CMD
    *groups CMD
    
    *last CMD
    *lastb CMD
    *lastlog CMD
    
    who CMD
    w CMD
        # w -i user01
        
        [실무예] 모니터링 구문
        # while true
        do
            CMD
            sleep 2
        done
    watch CMD
        # watch 'CMD; CMD'
    
    *exit CMD
    
###############################
제06장. 파일 종류
###############################

파일의 종류
* 일반 파일
* 디렉토리 파일
* 링크 파일
    - 하드 링크 파일  (# ln file1 file2)
    - 심볼릭 링크 파일(# ln -s file1 file2)
* 장치 파일


###############################
제06장. 파일 속성 관리
###############################

1. 소유자/그룹 변경
    chown CMD
        # chown -R fedora:fedora dir1
    
    chgrp CMD

2. 퍼미션 변경
    chmod CMD
        퍼미션 변경 방법
        * 심볼릭 모드(# chmod u+x file1)
        * 옥탈 모드  (# chmod 755 file1)
        
        파일&디렉토리 퍼미션의미
        * file(r/w/x)
        * directory(r(ls -l)/w(생성&삭제)/x(cd))
        
        umask CMD - 002|022|027|077
        * (관리자) /etc/bashrc, /etc/login.defs
        * (사용자) ~/.bashrc

###############################
제07장. VI/VIM 편집기
###############################

1. VI 편집기 실행
    # vi file1

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
