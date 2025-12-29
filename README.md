# contentree

## Terraform으로 VPC,EC2 생성
- 마스터,워커, Ansible 컨트롤러 작업용

## Kubespray를 통한 배포 
- kubespray 공식 컨테이너 이미지 사용 
- 클러스터 버전:1.25 

### 명령어
  
키 복사
``` bash
scp -i ~/.ssh/saltware.pem ~/.ssh/saltware.pem ubuntu@<ansible-instance-ip>:/home/ubuntu/.ssh/id_rsa
```