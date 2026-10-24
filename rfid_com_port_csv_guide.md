# 새 문서
from pathlib import Path

md_content = r'''# RFID 리더 COM 포트 선택 및 CSV 저장 코드 수정 가이드

이 문서는 COM 포트 선택 기능이 정상적으로 동작하도록 통신 설정을 복구하고, RFID 카드 ID와 HEX 데이터를 CSV 파일에 함께 저장하는 방법을 설명합니다.

## 1. 발견된 주요 오류

| 위치 | 문제 | 수정 방법 |
|---|---|---|
| 통신 설정 | `BAUD_RATE`, `DATA_BITS`, `PARITY`, `STOP_BITS`가 주석 처리됨 | 설정값을 활성화 |
| CSV 저장 | `save_card(card_id)`로 호출하지만 함수는 `save_card(card_id, hex_data)`를 요구함 | HEX 데이터도 전달 |
| HEX 출력 | HEX 문자열을 출력만 하고 변수에 저장하지 않음 | `hex_data` 변수에 저장 |

통신 설정이 정의되지 않으면 `NameError: name 'BAUD_RATE' is not defined`와 같은 오류가 발생할 수 있습니다.

## 2. 수정한 전체 Python 코드

아래 코드를 기존 코드 대신 사용하세요.

```python
import csv
import os
import re
import time
import serial
import serial.tools.list_ports
from datetime import datetime

# ===== 시리얼 통신 설정 =====
BAUD_RATE = 9600
DATA_BITS = serial.EIGHTBITS
PARITY = serial.PARITY_NONE
STOP_BITS = serial.STOPBITS_ONE

# CSV 저장 파일
CSV_FILE = "rfid_cards.csv"


def list_ports():
    """사용 가능한 시리얼 포트를 표시하고 선택"""
    ports = list(serial.tools.list_ports.comports())

    if not ports:
        print("사용 가능한 COM 포트가 없습니다.")
        return None

    print("\\n[사용 가능한 COM 포트]")

    for i, port in enumerate(ports, start=1):
        print(f"{i}. {port.device}: {port.description}")

    while True:
        choice = input("\\n사용할 COM 포트 번호를 입력하세요: ").strip()

        if choice.isdigit():
            index = int(choice)

            if 1 <= index <= len(ports):
                selected_port = ports[index - 1].device
                print(f"선택한 포트: {selected_port}")
                return selected_port

        print("잘못된 선택입니다. 목록에 있는 번호를 입력하세요.")


def save_card(card_id, hex_data):
    """카드 ID와 원본 HEX 데이터를 CSV 파일에 저장"""

    file_exists = (
        os.path.exists(CSV_FILE)
        and os.path.getsize(CSV_FILE) > 0
    )

    with open(
        CSV_FILE, "a", newline="", encoding="utf-8-sig"
    ) as file:
        writer = csv.writer(file)

        if not file_exists:
            writer.writerow([
                "날짜", "시간", "카드 ID", "HEX 데이터"
            ])

        now = datetime.now()

        writer.writerow([
            now.strftime("%Y-%m-%d"),
            now.strftime("%H:%M:%S"),
            card_id,
            hex_data
        ])


def read_rfid():
    """RS-232C RFID 리더에서 카드 데이터 수신"""

    selected_port = list_ports()

    if selected_port is None:
        return

    try:
        with serial.Serial(
            port=selected_port,
            baudrate=BAUD_RATE,
            bytesize=DATA_BITS,
            parity=PARITY,
            stopbits=STOP_BITS,
            timeout=0.2
        ) as ser:

            print(f"\\n연결 성공: {selected_port}")
            print("카드를 리더에 접촉하세요.")
            print("종료하려면 Ctrl+C를 누르세요.\\n")

            buffer = bytearray()
            last_data_time = None

            while True:
                data = ser.read(ser.in_waiting or 1)

                if data:
                    buffer.extend(data)
                    last_data_time = time.monotonic()

                # 수신이 잠시 멈추면 하나의 메시지로 처리
                if (
                    buffer
                    and last_data_time is not None
                    and time.monotonic() - last_data_time > 0.15
                ):
                    raw = bytes(buffer)
                    buffer.clear()
                    last_data_time = None

                    # HEX 데이터 생성 및 출력
                    hex_data = raw.hex(" ").upper()
                    print("수신 HEX:", hex_data)

                    # ASCII 문자열로 변환
                    text = raw.decode("ascii", errors="ignore").strip()

                    # 카드 ID 추출
                    match = re.search(
                        r"[0-9A-Fa-f]{8,}",
                        text
                    )

                    if match:
                        card_id = match.group(0).upper()
                        print("카드 ID:", card_id)
                    else:
                        card_id = "추출 실패"
                        print("문자열 카드 ID를 찾지 못했습니다.")
                        print("수신 원본:", repr(raw))

                    # 추출 성공 여부와 관계없이 저장
                    save_card(card_id, hex_data)
                    print("CSV 저장 완료\\n")

    except serial.SerialException as e:
        print("시리얼 통신 오류:", e)

    except KeyboardInterrupt:
        print("\\n프로그램을 종료합니다.")


if __name__ == "__main__":
    read_rfid()
```

## 3. 실행 방법

1. RFID 리더를 PC에 연결합니다.
2. Windows 장치 관리자에서 리더의 COM 포트 번호를 확인합니다.
3. Python 프로그램을 실행하고 목록에서 해당 포트 번호를 선택합니다.
4. 카드를 리더에 접촉합니다.
5. 프로그램의 작업 폴더에 생성되는 `rfid_cards.csv` 파일을 확인합니다.

예를 들어 포트가 COM5라면 목록에서 COM5에 해당하는 번호를 선택합니다. 코드에서 COM 포트를 직접 지정할 필요가 없습니다.

## 4. 연결 문제 확인

- **포트 목록에 장치가 없음:** USB 케이블, 드라이버, 장치 관리자 상태를 확인합니다.
- **포트 열기 실패:** 다른 프로그램이 해당 COM 포트를 사용 중인지 확인합니다.
- **연결은 되지만 데이터가 안 들어옴:** 리더의 통신 속도(9600), 데이터 비트, 패리티, 정지 비트가 장치 설정과 일치하는지 확인합니다.
- **CSV 저장 시 오류:** `save_card(card_id, hex_data)`처럼 두 인자를 모두 전달해야 합니다.

## 참고

코드는 COM 포트를 열 수 있으면 `연결 성공`을 출력합니다. 이것만으로 RFID 리더와 실제 데이터 통신까지 확인된 것은 아닙니다. 데이터가 들어오지 않는다면 장치의 통신 설정과 출력 형식을 확인하세요.



