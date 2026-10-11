# EM4100 RFID 리더 개발 가이드

## Python · RS-232C · CSV · Windows EXE 빌드

이 문서는 Windows 10/11 환경에서 RS-232C 또는 USB-RS232 방식의 RFID
리더로 카드 ID를 수신하고, 화면에 표시한 뒤 CSV 파일에 저장하는 Python
프로그램을 작성하고 실행 파일(`.exe`)로 빌드하는 과정을 설명합니다.

> **중요:** EM4100은 일반적으로 읽기 전용(Read Only) RFID 규격입니다. 이
> 문서의 "카드 등록"은 카드 칩에 데이터를 쓰는 기능이 아니라, 읽어 온
> 카드 ID를 PC의 CSV 파일에 등록하는 기능입니다. 카드 ID 쓰기 기능은
> 지원하지 않습니다.

## 목차

-   [1. 동작 개요](#1-동작-개요)
-   [2. 개발 환경 준비](#2-개발-환경-준비)
-   [3. 시리얼 포트 확인](#3-시리얼-포트-확인)
-   [4. 전체 소스 코드](#4-전체-소스-코드)
-   [5. 프로그램 실행](#5-프로그램-실행)
-   [6. EXE 파일 빌드](#6-exe-파일-빌드)
-   [7. 오류 해결](#7-오류-해결)
-   [8. 확인 사항 및 제한](#8-확인-사항-및-제한)

## 1. 동작 개요

프로그램은 다음 순서로 동작합니다.

1.  PC에 연결된 RFID 리더의 시리얼 포트를 엽니다.
2.  카드가 리더에 인식되면 RS-232C로 전송된 데이터를 수신합니다.
3.  수신 원본을 HEX 형식으로 표시합니다.
4.  수신 데이터에서 카드 ID 후보 문자열을 추출해 화면에 표시합니다.
5.  날짜, 시간, 카드 ID를 `rfid_cards.csv` 파일에 추가합니다.

### 기본 설정

  항목          기본값             설명
  ------------- ------------------ ------------------------------------
  포트          `COM3`             장치 관리자에서 확인한 포트로 변경
  통신 속도     `9600 bps`         리더 설명서에 맞게 설정
  데이터 비트   8                  일반적인 8N1 설정
  패리티        없음               일반적인 8N1 설정
  정지 비트     1                  일반적인 8N1 설정
  출력 파일     `rfid_cards.csv`   실행 작업 폴더에 생성

`9600, 8N1`은 예시 설정입니다. 반드시 해당 리더의 설명서를 확인하세요.

## 2. 개발 환경 준비

### 2.1 Python 설치 확인

PowerShell을 열고 다음 명령어를 실행합니다.

``` powershell
py --version
```

버전이 표시되지 않으면 Python을 설치하고, 설치 과정에서 Python 실행 경로
설정을 확인합니다.

### 2.2 작업 폴더 생성

예를 들어 다음 폴더를 프로젝트 폴더로 사용할 수 있습니다.

``` powershell
mkdir C:\RFIDProject
cd C:\RFIDProject
```

### 2.3 필요한 라이브러리 설치

Python의 `pyserial` 패키지는 시리얼 통신을 담당합니다.

``` powershell
py -m pip install --upgrade pip
py -m pip install pyserial
```

설치 여부를 확인합니다.

``` powershell
py -c "import serial; print(serial.__file__)"
```

`serial` 모듈의 경로가 출력되면 Python에서 모듈을 불러올 수 있는
상태입니다.

> 패키지 이름은 `pyserial`이지만, Python 코드에서는 `import serial`로
> 불러옵니다. 이름이 비슷한 별도 패키지 `serial`을 설치하지 않도록
> 주의하세요.

## 3. 시리얼 포트 확인

1.  RFID 리더를 PC에 연결합니다.
2.  Windows의 **장치 관리자 → 포트(COM 및 LPT)** 에서 포트 번호를
    확인합니다.
3.  소스 코드의 `COM_PORT` 값을 실제 포트로 변경합니다.

사용 가능한 포트를 Python에서 확인할 수도 있습니다.

``` powershell
py -c "import serial.tools.list_ports; [print(p.device, p.description) for p in serial.tools.list_ports.comports()]"
```

예시 출력:

``` text
COM3 USB Serial Port (COM3)
COM5 Communications Port (COM5)
```

리더가 `COM5`로 표시된다면 코드의 `COM_PORT = "COM5"`로 변경합니다.

> **전기적 연결 주의:** RS-232C 신호와 TTL UART 신호는 전기적 특성이
> 다릅니다. 일반 TTL UART 출력을 PC의 RS-232C 포트에 직접 연결하지
> 마세요. 장비 규격에 맞는 인터페이스 변환기를 사용해야 합니다.

## 4. 전체 소스 코드

VS Code에서 `rfid_reader.py` 파일을 만들고 다음 코드를 저장합니다.

``` python
import csv
import os
import re
import time
import serial
import serial.tools.list_ports
from datetime import datetime

# ===== 사용자 설정 =====
COM_PORT = "COM3"       # 장치 관리자에서 확인한 포트로 변경
BAUD_RATE = 9600         # 리더 설명서에 맞게 변경
DATA_BITS = serial.EIGHTBITS
PARITY = serial.PARITY_NONE
STOP_BITS = serial.STOPBITS_ONE

CSV_FILE = "rfid_cards.csv"


def list_ports():
    """사용 가능한 시리얼 포트 표시"""
    ports = serial.tools.list_ports.comports()

    print("\\n[사용 가능한 COM 포트]")
    if not ports:
        print("사용 가능한 시리얼 포트가 없습니다.")
        return

    for port in ports:
        print(f"{port.device}: {port.description}")


def save_card(card_id):
    """카드 ID를 CSV 파일에 추가"""
    file_exists = os.path.exists(CSV_FILE)

    with open(CSV_FILE, "a", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)

        if not file_exists or os.path.getsize(CSV_FILE) == 0:
            writer.writerow(["날짜", "시간", "카드 ID"])

        now = datetime.now()
        writer.writerow([
            now.strftime("%Y-%m-%d"),
            now.strftime("%H:%M:%S"),
            card_id
        ])


def extract_card_id(raw):
    """
    리더가 ASCII 형태로 ID를 전송하는 경우의 간단한 추출 예제.
    실제 출력 형식은 리더 설명서 및 수신 원본에 맞게 조정해야 합니다.
    """
    text = raw.decode("ascii", errors="ignore").strip()
    match = re.search(r"[0-9A-Fa-f]{8,}", text)

    if match:
        return match.group(0).upper()

    return None


def read_rfid():
    """RS-232C RFID 리더에서 카드 데이터를 수신"""
    list_ports()

    try:
        with serial.Serial(
            port=COM_PORT,
            baudrate=BAUD_RATE,
            bytesize=DATA_BITS,
            parity=PARITY,
            stopbits=STOP_BITS,
            timeout=0.2
        ) as ser:
            print(f"\\n연결 성공: {COM_PORT}")
            print("카드를 리더에 접촉하세요.")
            print("종료하려면 Ctrl+C를 누르세요.\\n")

            buffer = bytearray()
            last_data_time = None

            while True:
                data = ser.read(ser.in_waiting or 1)

                if data:
                    buffer.extend(data)
                    last_data_time = time.monotonic()

                # 데이터가 일정 시간 추가 수신되지 않으면 한 메시지로 처리
                if (
                    buffer
                    and last_data_time is not None
                    and time.monotonic() - last_data_time > 0.15
                ):
                    raw = bytes(buffer)
                    buffer.clear()
                    last_data_time = None

                    print("수신 HEX:", raw.hex(" ").upper())

                    card_id = extract_card_id(raw)

                    if card_id:
                        print("카드 ID:", card_id)
                        try:
                            save_card(card_id)
                            print(f"CSV 저장 완료: {CSV_FILE}\\n")
                        except OSError as e:
                            print("CSV 파일 저장 오류:", e)
                    else:
                        print("ASCII 카드 ID 후보를 찾지 못했습니다.")
                        print("수신 원본:", repr(raw), "\\n")

    except serial.SerialException as e:
        print("시리얼 통신 오류:", e)
    except KeyboardInterrupt:
        print("\\n프로그램을 종료합니다.")


if __name__ == "__main__":
    read_rfid()
```

### 코드의 주요 기능

-   `list_ports()`: 사용 가능한 시리얼 포트를 표시합니다.
-   `extract_card_id()`: ASCII 수신 데이터에서 8자리 이상의 16진수
    문자열 후보를 찾습니다.
-   `save_card()`: 날짜, 시간, 카드 ID를 CSV 파일에 추가합니다.
-   `read_rfid()`: 시리얼 포트를 열고 데이터를 수신합니다.

> **ID 추출 로직의 한계:** 위 정규식은 예제용입니다. 리더가 STX/ETX,
> 체크섬, 고정 길이 프레임, 10진수 문자열 또는 바이너리 데이터를
> 사용하는 경우 정확한 ID를 추출하지 못할 수 있습니다. `수신 HEX`와
> `수신 원본`을 확인하고 리더의 프로토콜에 맞게 파싱 로직을 수정하세요.
> 단순히 16진수처럼 보이는 문자열을 찾는 것만으로 카드 ID의 유효성을
> 보장할 수는 없습니다.

## 5. 프로그램 실행

PowerShell에서 소스 파일이 있는 폴더로 이동합니다.

``` powershell
cd C:\RFIDProject
py .\rfid_reader.py
```

정상 연결 예시:

``` text
[사용 가능한 COM 포트]
COM3: USB Serial Port (COM3)

연결 성공: COM3
카드를 리더에 접촉하세요.
종료하려면 Ctrl+C를 누르세요.
```

카드를 인식하면 다음과 같이 표시될 수 있습니다.

``` text
수신 HEX: 30 30 31 32 33 34 41 42 0D 0A
카드 ID: 001234AB
CSV 저장 완료: rfid_cards.csv
```

위 ID와 수신 데이터는 형식을 설명하기 위한 예시이며, 실제 리더 출력과
다를 수 있습니다.

### CSV 저장 결과

프로그램의 작업 폴더에 `rfid_cards.csv` 파일이 생성됩니다.

  날짜         시간       카드 ID
  ------------ ---------- ----------
  2026-10-09   09:30:15   001234AB

Excel에서 열 수 있도록 UTF-8 BOM(`utf-8-sig`) 인코딩을 사용합니다. 카드
ID는 선행 0이 유지되도록 CSV에서 문자열로 취급하는 것이 좋습니다.

### VS Code에서 실행

1.  VS Code에서 프로젝트 폴더를 엽니다.
2.  `rfid_reader.py`를 엽니다.
3.  Python 인터프리터를 선택합니다.
4.  **Run Python File** 또는 F5로 실행합니다.

VS Code에서 실행하더라도 `COM_PORT`, 통신 속도, 라이브러리 설치 환경은
동일하게 확인해야 합니다.

## 6. EXE 파일 빌드

Python이 설치되지 않은 다른 Windows PC에서도 실행할 수 있도록
PyInstaller로 실행 파일을 만들 수 있습니다.

### 6.1 PyInstaller 설치

소스 코드 실행에 사용한 것과 같은 Python 환경에서 설치합니다.

``` powershell
py -m pip install pyinstaller
```

설치 확인:

``` powershell
py -m PyInstaller --version
```

### 6.2 기존 빌드 결과 정리

프로젝트 폴더에서 실행합니다. 기존 결과를 보관해야 한다면 삭제 전에
백업하세요.

``` powershell
Remove-Item -Recurse -Force .\build, .\dist -ErrorAction SilentlyContinue
Remove-Item -Force .\rfid_reader.spec -ErrorAction SilentlyContinue
```

### 6.3 EXE 빌드

``` powershell
py -m PyInstaller --clean --onefile --console --name rfid_reader .\rfid_reader.py
```

옵션 설명:

-   `--clean`: PyInstaller 캐시를 정리합니다.
-   `--onefile`: 실행 파일 하나로 묶습니다.
-   `--console`: 통신 상태와 디버깅 메시지를 콘솔에 표시합니다.
-   `--name rfid_reader`: 결과 실행 파일 이름을 지정합니다.

빌드가 완료되면 다음 경로에 파일이 생성됩니다.

``` text
C:\RFIDProject\dist\rfid_reader.exe
```

### 6.4 EXE 실행

``` powershell
.\dist\rfid_reader.exe
```

EXE를 실행하는 PC에서도 리더 드라이버와 올바른 COM 포트가 필요합니다.
CSV 파일은 프로그램의 실행 파일 위치가 아니라 **현재 작업 디렉터리**에
생성될 수 있으므로, 예측 가능한 위치에 저장하려면 코드에서 CSV 경로를
별도로 지정하는 방법을 고려하세요.

> 개발 및 디버깅 단계에서는 `--console` 옵션을 유지하세요. `--windowed`
> 또는 `--noconsole`은 콘솔 메시지가 보이지 않게 하므로 통신 오류를
> 진단하기 어렵습니다.

## 7. 오류 해결

### 7.1 `could not open port 'COM3'`

오류 예시:

``` text
시리얼 통신 오류:
could not open port 'COM3':
FileNotFoundError(2, '지정된 파일을 찾을 수 없습니다.', None, 2)
```

가능한 원인:

-   리더가 다른 COM 포트로 연결되어 있습니다.
-   USB-RS232 변환기 드라이버가 설치되지 않았습니다.
-   장치가 분리되었거나 포트 번호가 변경되었습니다.
-   다른 프로그램이 해당 COM 포트를 사용 중입니다.

해결 순서:

1.  장치 관리자에서 실제 포트 번호를 확인합니다.
2.  포트 목록 명령으로 Python에서 해당 포트가 보이는지 확인합니다.
3.  `COM_PORT = "COM3"` 값을 실제 포트로 변경합니다.
4.  시리얼 터미널 등 다른 프로그램이 포트를 점유하고 있으면 종료합니다.
5.  리더 설명서에 맞는 baud rate 및 8N1 설정인지 확인합니다.

포트가 목록에 없으면 Python 코드보다 먼저 케이블, USB-RS232 변환기,
드라이버, 장치 관리자 상태를 확인해야 합니다.

### 7.2 `ModuleNotFoundError: No module named 'serial'`

오류 예시:

``` text
ModuleNotFoundError: No module named 'serial'
[PYI-xxxxx:ERROR] Failed to execute script 'rfid_reader'
```

먼저 Python 환경에서 `pyserial`이 정상적으로 설치되어 있는지 확인합니다.

``` powershell
py -m pip show pyserial
py -c "import serial; print(serial.__file__)"
```

모듈을 불러올 수 없다면 다음과 같이 재설치합니다.

``` powershell
py -m pip uninstall serial pyserial
py -m pip install pyserial
py -c "import serial; print(serial.__file__)"
```

> `pip uninstall serial pyserial` 명령은 두 패키지가 설치되어 있다면
> 모두 제거합니다. 다른 프로젝트가 별도 `serial` 패키지를 사용하고
> 있다면 영향을 확인한 뒤 실행하세요.

정상적으로 import되면 기존 빌드 결과를 정리하고 다시 빌드합니다.

``` powershell
Remove-Item -Recurse -Force .\build, .\dist -ErrorAction SilentlyContinue
Remove-Item -Force .\rfid_reader.spec -ErrorAction SilentlyContinue
py -m PyInstaller --clean --onefile --console --name rfid_reader .\rfid_reader.py
```

그래도 문제가 지속되면 다음 명령으로 빌드 로그를 자세히 확인합니다.

``` powershell
py -m PyInstaller --clean --onefile --console --debug=imports --name rfid_reader .\rfid_reader.py
```

### 7.3 `--hidden-import` 사용

PyInstaller가 모듈을 자동으로 수집하지 못한다는 증거가 있을 때 다음
옵션을 시험할 수 있습니다.

``` powershell
py -m PyInstaller --clean --onefile --console --hidden-import=serial --name rfid_reader .\rfid_reader.py
```

`--hidden-import=serial`은 수집 문제를 해결할 수 있는 경우에 사용하는
보조 방법입니다. 일반적으로는 올바른 Python 환경에 `pyserial`을 설치한
뒤 다시 빌드하는 것부터 확인하세요.

### 7.4 `.spec` 파일 수정

명령행 옵션으로 해결되지 않고 실제 수집 누락이 확인된 경우, 생성된
`rfid_reader.spec`의 `Analysis(...)` 항목을 확인합니다.

``` python
a = Analysis(
    ["rfid_reader.py"],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=["serial"],
    # 나머지 기존 설정 유지
)
```

실제 `.spec` 파일은 PyInstaller 버전에 따라 구조가 다를 수 있습니다.
기존 파일 전체를 위 예시로 교체하지 말고, 기존 `Analysis(...)` 설정을
유지하면서 `hiddenimports`만 수정하세요.

수정 후 프로젝트 폴더에서 다음을 실행합니다.

``` powershell
py -m PyInstaller --clean .\rfid_reader.spec
```

### 7.5 EXE 실행 시 콘솔이 바로 닫힘

PowerShell에서 EXE를 실행해 오류 메시지를 확인합니다.

``` powershell
.\dist\rfid_reader.exe
```

콘솔을 표시하는 `--console` 옵션으로 빌드하면 예외 메시지를 확인하기
쉽습니다.

### 7.6 카드 ID가 추출되지 않음

화면의 `수신 HEX` 및 `수신 원본`을 확인합니다.

-   데이터가 전혀 없다면 포트, baud rate, 배선, 리더 설정을 확인합니다.
-   데이터가 숫자나 영숫자 문자열이 아니라면 파싱 코드를 수정해야 할 수
    있습니다.
-   ID가 고정 길이라면 해당 길이와 프레임 규칙을 적용합니다.
-   체크섬이나 시작/종료 바이트가 있다면 프로토콜에 맞게 검증합니다.

수신 데이터 형식이 확인되지 않은 상태에서는 정규식만 변경해 실제 카드
ID가 정확히 추출된다고 보장할 수 없습니다.

## 8. 확인 사항 및 제한

-   이 예제는 리더가 RS-232C 시리얼 포트로 데이터를 출력한다는
    전제입니다.
-   일부 USB 리더는 키보드 입력(HID) 방식으로 동작하므로 `pyserial`
    방식으로 읽을 수 없습니다.
-   `COM3`, `9600 bps`, `8N1`은 예시값입니다. 장비 설명서의 설정을
    우선합니다.
-   CSV 등록은 PC 파일에 기록하는 기능이며 EM4100 카드에 쓰는 기능이
    아닙니다.
-   동일한 카드를 여러 번 인식하면 CSV에 여러 행이 저장됩니다. 중복을
    막으려면 별도의 중복 검사 로직을 추가해야 합니다.
-   실제 서비스에 사용하기 전에는 리더 프로토콜, ID 길이, 체크섬, 오류
    데이터, 중복 처리, 파일 저장 위치 및 접근 권한을 검증하세요.

## 프로젝트 파일 예시

``` text
RFIDProject/
├── rfid_reader.py
├── README.md
├── rfid_cards.csv       # 실행 후 생성
├── build/               # PyInstaller 빌드 중 생성
├── dist/
│   └── rfid_reader.exe
└── rfid_reader.spec     # PyInstaller 설정 파일
```

`build/`, `dist/`, CSV 파일 등 실행 중 생성되는 파일을 Git에 포함할지는
프로젝트 목적에 따라 결정하세요. 소스 중심 저장소라면 다음과 같은
`.gitignore`를 사용할 수 있습니다.

``` gitignore
__pycache__/
*.py[cod]
.venv/
venv/
build/
dist/
*.spec
rfid_cards.csv
```

> 실행 파일도 Git에서 공유해야 한다면 `dist/`를 무조건 제외하기보다,
> 릴리스(Release) 첨부 파일이나 Git LFS 등 저장소 정책에 맞는 배포
> 방법을 선택하세요.
