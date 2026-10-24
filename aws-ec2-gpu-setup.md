# AWS EC2에서 GPU 서버 설정하기

GPU 인스턴스를 만들고, 드라이버와 PyTorch가 GPU를 인식하는 것까지 확인하는 순서를 정리했습니다. 목표는 터미널에서 `nvidia-smi`로 GPU 정보가 보이는 상태입니다.

```text
ubuntu@ip-172-31-8-24:~$ nvidia-smi
+--------------------------------------------+
| NVIDIA-SMI 580.xx   Driver Version: 580.xx |
|--------------------------------------------|
| GPU  Name          Memory-Usage    GPU-Util|
|   0  NVIDIA A10G   1MiB / 23028MiB      0% |
+--------------------------------------------+
```

*예시 출력입니다. 버전과 GPU 종류는 환경마다 다릅니다.*

## 어떤 방법으로 할까요?

| 방법 | 설명 | 따라 할 단계 |
|------|------|--------------|
| **A. Deep Learning AMI 사용 (권장)** | NVIDIA 드라이버, CUDA, PyTorch가 미리 설치된 이미지입니다. 서버를 켜면 바로 GPU를 쓸 수 있어 초보자에게 가장 쉽습니다. | 1, 2, 3, 4단계 |
| **B. 일반 Ubuntu에 직접 설치** | 원하는 OS 버전과 소프트웨어 구성을 직접 정하고 싶을 때 씁니다. | 1, 2, 5단계 |

## 목차

1. [사전 준비: GPU 사용 한도(쿼터) 확인](#1-사전-준비-gpu-사용-한도쿼터-확인)
2. [GPU 인스턴스 고르기](#2-gpu-인스턴스-고르기)
3. [방법 A: Deep Learning AMI로 서버 시작하기](#3-방법-a-deep-learning-ami로-서버-시작하기)
4. [접속해서 GPU 확인하기](#4-접속해서-gpu-확인하기)
5. [방법 B: 일반 Ubuntu에 직접 설치하기](#5-방법-b-일반-ubuntu에-직접-설치하기)
6. [(선택) Docker에서 GPU 쓰기](#6-선택-docker에서-gpu-쓰기)
7. [비용 관리: 꼭 지키세요](#7-비용-관리-꼭-지키세요)
8. [자주 막히는 문제 해결](#8-자주-막히는-문제-해결)

---

## 1. 사전 준비: GPU 사용 한도(쿼터) 확인

새 AWS 계정은 GPU 인스턴스 기본 한도가 **0 vCPU**라서, 한도를 늘리지 않으면 서버 시작 단계에서 오류가 납니다. 가장 먼저 해 두세요.

1. AWS 콘솔 오른쪽 위에서 사용할 **리전**(예: 서울 `ap-northeast-2`)을 고릅니다. 한도는 리전마다 따로 관리됩니다.
2. 콘솔 검색창에 **Service Quotas**를 입력해 엽니다.
3. **AWS 서비스 → Amazon Elastic Compute Cloud (Amazon EC2)**를 선택합니다.
4. 목록에서 쓰려는 인스턴스 계열에 맞는 항목을 찾아 **할당량 증가 요청**을 누릅니다.

   | 쓰려는 인스턴스 | 요청할 할당량 이름 |
   |-----------------|--------------------|
   | g4dn, g5, g6, g6e | `Running On-Demand G and VT instances` |
   | p4d, p5 등 P 계열 | `Running On-Demand P instances` |

5. 필요한 vCPU 수를 입력합니다. 예를 들어 4 vCPU짜리 `g5.xlarge` 1대를 쓰려면 **4**를 요청합니다.

> **스팟(Spot)과 헷갈리지 마세요**
> "All G and VT **Spot** Instance Requests"는 스팟용 한도이고 별개입니다. 일반(온디맨드)으로 쓸 거라면 위 표의 **Running On-Demand** 항목을 늘려야 합니다.

승인에는 몇 분에서 며칠이 걸릴 수 있습니다. 새 계정은 거절될 수 있으니, 요청 사유(예: "머신러닝 학습 및 실험용")를 간단히 적어 두면 도움이 됩니다. 거절되면 AWS 지원 케이스로 문의하세요.

---

## 2. GPU 인스턴스 고르기

처음이라면 `g5.xlarge`나 `g4dn.xlarge`처럼 작은 것부터 시작하는 편이 비용 면에서 안전합니다.

| 계열 | GPU | 어울리는 용도 |
|------|-----|---------------|
| g4dn | NVIDIA T4 (16GB) | 입문, 학습 실습, 가벼운 추론 |
| g5 | NVIDIA A10G (24GB) | 중간 규모 학습, 이미지·LLM 추론 |
| g6 | NVIDIA L4 (24GB) | 추론, 가성비 위주 작업 |
| g6e | NVIDIA L40S (48GB) | 큰 모델 추론, 파인튜닝 |
| p4d / p5 | A100 / H100 | 대규모 학습 (고가, 한도 승인 까다로움) |

시간당 요금은 리전과 시기에 따라 달라지므로 [EC2 온디맨드 요금 페이지](https://aws.amazon.com/ec2/pricing/on-demand/)에서 직접 확인하세요.

---

## 3. 방법 A: Deep Learning AMI로 서버 시작하기

1. 콘솔에서 **EC2 → 인스턴스 → 인스턴스 시작**을 누릅니다.
2. **이름**에 구분하기 쉬운 이름(예: `gpu-test`)을 적습니다.
3. **애플리케이션 및 OS 이미지(AMI)** 검색창에 `Deep Learning OSS Nvidia Driver AMI GPU PyTorch`를 입력하고, 결과에서 **Ubuntu**용 이미지 중 가장 최신 버전을 선택합니다.
4. **인스턴스 유형**에서 2단계에서 고른 유형(예: `g5.xlarge`)을 선택합니다.
5. **키 페어**에서 **새 키 페어 생성**을 눌러 `.pem` 파일을 내려받고 안전한 곳에 보관합니다. 다시 받을 수 없습니다.
6. **네트워크 설정**에서 SSH(22번 포트)의 소스를 **내 IP**로 제한합니다. 전체 공개(`0.0.0.0/0`)는 피하세요.
7. **스토리지**를 **100GiB 이상**(gp3)으로 늘립니다. 모델과 데이터셋은 용량을 많이 차지합니다.
8. **인스턴스 시작**을 누르고, 상태가 **실행 중**, 상태 검사가 **2/2 통과**가 될 때까지 기다립니다.

> **AMI가 여러 개 보일 때**
> **PyTorch**가 이름에 들어간 이미지는 PyTorch까지 설치된 것이고, **Base**가 들어간 이미지는 드라이버와 CUDA만 들어 있어 원하는 프레임워크를 직접 설치합니다. 학습 목적이면 PyTorch 이미지가 편합니다. 지원하는 인스턴스 유형은 이미지마다 다르니 [DLAMI 릴리스 노트](https://docs.aws.amazon.com/dlami/latest/devguide/appendix-ami-release-notes.html)에서 확인하세요.

---

## 4. 접속해서 GPU 확인하기

1. 콘솔에서 인스턴스를 선택하고 **퍼블릭 IPv4 주소**를 복사합니다.
2. 내려받은 `.pem` 파일이 있는 폴더에서 터미널(Windows는 PowerShell)을 열고 접속합니다. Ubuntu 이미지의 사용자 이름은 `ubuntu`입니다.

   ```bash
   # macOS / Linux 에서는 먼저 키 파일 권한을 제한합니다
   chmod 400 my-key.pem
   ssh -i my-key.pem ubuntu@퍼블릭_IP주소
   ```

3. GPU가 보이는지 확인합니다.

   ```bash
   nvidia-smi
   ```

   GPU 이름과 메모리가 표로 나오면 드라이버는 정상입니다.

4. PyTorch가 GPU를 쓸 수 있는지 확인합니다. 최신 PyTorch DLAMI는 `/opt/pytorch`에 가상환경이 있습니다.

   ```bash
   source /opt/pytorch/bin/activate
   python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
   ```

`True`와 GPU 이름이 출력되면 방법 A는 끝입니다. 이미지 버전에 따라 가상환경 위치가 다를 수 있으니, 위 경로가 없다면 접속 직후 화면에 나오는 안내문(MOTD)을 확인하세요.

---

## 5. 방법 B: 일반 Ubuntu에 직접 설치하기

AMI 단계에서 **Ubuntu Server 22.04 LTS**를 선택해 같은 방식으로 서버를 시작하고 접속한 뒤 진행합니다. 스토리지는 마찬가지로 100GiB 이상을 권장합니다.

### NVIDIA 드라이버 설치

```bash
sudo apt update && sudo apt -y upgrade
sudo apt install -y build-essential linux-headers-$(uname -r) ubuntu-drivers-common

# 권장 드라이버 확인 (선택)
ubuntu-drivers devices

# 컴퓨팅(GPGPU)용 권장 드라이버 자동 설치
sudo ubuntu-drivers install --gpgpu
sudo reboot
```

재부팅 후 1~2분 기다렸다가 다시 SSH로 접속해 `nvidia-smi`를 실행합니다.

### PyTorch 설치

PyTorch의 pip 패키지는 필요한 CUDA 런타임을 함께 가져오므로, **CUDA Toolkit을 따로 설치하지 않아도** 됩니다. (직접 CUDA 코드를 컴파일하는 `nvcc`가 필요할 때만 Toolkit을 추가하세요.)

```bash
sudo apt install -y python3-venv python3-pip
python3 -m venv ~/venv
source ~/venv/bin/activate
pip install torch
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

> **그래픽(GRID) 드라이버와 헷갈리지 마세요**
> GPU를 계산용(AI, 학습, 추론)으로 쓸 때는 위 방법이면 충분합니다. 원격 데스크톱 같은 그래픽 용도는 별도의 드라이버 구성이 필요합니다.

---

## 6. (선택) Docker에서 GPU 쓰기

Deep Learning AMI에는 Docker와 NVIDIA Container Toolkit이 이미 들어 있는 경우가 많습니다. 일반 Ubuntu에 직접 설치했다면 아래를 따라 하세요. Docker가 없으면 먼저 `sudo apt install -y docker.io`를 실행합니다.

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

컨테이너 안에서 GPU가 보이는지 확인합니다.

```bash
sudo docker run --rm --gpus all ubuntu nvidia-smi
```

---

## 7. 비용 관리: 꼭 지키세요

GPU 인스턴스는 켜 둔 시간만큼 요금이 나옵니다. 쓰지 않을 때는 반드시 끄세요.

- **중지(Stop)**: 인스턴스 요금은 멈추지만 디스크(EBS) 요금은 계속 나옵니다. 나중에 이어서 쓸 때 선택합니다.
- **종료(Terminate)**: 인스턴스가 삭제되고 보통 디스크도 함께 사라집니다. 필요한 파일은 미리 S3 등에 백업하세요.
- 작업이 끝나면 서버 안에서 `sudo shutdown -h now`를 실행해도 인스턴스가 중지됩니다. 일정 시간 뒤 자동으로 끄려면 `sudo shutdown -h +120`처럼 쓰면 2시간 후에 종료됩니다.
- **Billing → 예산(Budgets)**에서 월 예산 알림을 만들어 두면 요금 폭탄을 막을 수 있습니다.
- 실험·학습용이라면 중단 가능성을 감수하는 대신 저렴한 **스팟 인스턴스**도 고려해 보세요. (스팟 한도는 따로 요청해야 합니다.)

---

## 8. 자주 막히는 문제 해결

### "You have requested more vCPU capacity than your current vCPU limit…" 오류가 나요

1단계의 vCPU 한도가 부족한 경우입니다. 해당 리전에서 **Running On-Demand G and VT instances**(또는 P) 한도를 필요한 vCPU 수만큼 늘렸는지, 요청한 리전과 서버를 만드는 리전이 같은지 확인하세요.

### "InsufficientInstanceCapacity" 오류가 나요

해당 시점에 AWS의 GPU 재고가 부족한 상태입니다. 몇 분 뒤 다시 시도하거나, 다른 가용 영역(서브넷)을 고르거나, 다른 인스턴스 유형(예: g5 대신 g6)이나 다른 리전을 시도하세요.

### SSH 접속이 안 돼요 (Timeout / Permission denied)

- 보안 그룹에서 22번 포트가 **현재 내 IP**에 열려 있는지 확인하세요. 집이나 카페에서 IP가 바뀌면 다시 설정해야 합니다.
- 사용자 이름이 `ubuntu`인지, 올바른 `.pem` 파일인지 확인하세요.
- `Permission denied (publickey)`는 대개 키 파일이 틀렸거나, 키 파일 권한이 너무 넓을 때(`chmod 400`) 나옵니다.

### nvidia-smi에서 "couldn't communicate with the NVIDIA driver"가 나와요

보통 커널이 업데이트된 뒤 드라이버 모듈이 새 커널에 맞게 빌드되지 않아서 생깁니다. 아래 순서로 확인해 보세요.

```bash
sudo apt install -y linux-headers-$(uname -r)
sudo dkms status
sudo reboot
```

그래도 해결되지 않으면 드라이버를 다시 설치(5단계)하거나, 처음부터 Deep Learning AMI로 새 서버를 만드는 편이 빠릅니다.

### torch.cuda.is_available()이 False로 나와요

- 먼저 `nvidia-smi`가 동작하는지 확인하세요. 안 되면 드라이버 문제입니다.
- 가상환경을 활성화한 상태인지 확인하세요. (`source /opt/pytorch/bin/activate` 등)
- CPU 전용 PyTorch가 깔려 있을 수 있습니다. `pip list | grep torch`로 확인하고, 필요하면 `pip uninstall torch` 후 다시 설치하세요.

### "No space left on device"가 나와요

스토리지가 부족한 경우입니다. 콘솔의 **EC2 → 볼륨**에서 볼륨 크기를 늘린 뒤 서버 안에서 파티션과 파일 시스템을 확장해야 합니다. 처음 만들 때 100GiB 이상으로 잡아 두면 이런 일을 줄일 수 있습니다.

---

AWS 콘솔 화면과 AMI 이름, 버전은 수시로 바뀔 수 있으니 막히면 [DLAMI 공식 문서](https://docs.aws.amazon.com/dlami/latest/devguide/what-is-dlami.html)를 함께 확인하세요.
