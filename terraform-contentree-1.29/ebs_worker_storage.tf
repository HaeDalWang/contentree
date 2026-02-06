#---------------------------------------------------------------
# 워커 노드 Rook-Ceph 테스트용 EBS 볼륨 (노드당 3GB 1개)
# Attach 후 인스턴스에서 lsblk 시 nvme1n1 등으로 노출됨 (Nitro)
#---------------------------------------------------------------
resource "aws_ebs_volume" "worker_ceph_01" {
  availability_zone = aws_instance.mvd_kubewk01.availability_zone
  size              = 3
  type              = "gp3"

  tags = merge(local.tags, {
    Name = "mvd-kubewk01-ceph-data"
  })
}

resource "aws_ebs_volume" "worker_ceph_02" {
  availability_zone = aws_instance.mvd_kubewk02.availability_zone
  size              = 3
  type              = "gp3"

  tags = merge(local.tags, {
    Name = "mvd-kubewk02-ceph-data"
  })
}

resource "aws_ebs_volume" "worker_ceph_03" {
  availability_zone = aws_instance.mvd_kubewk03.availability_zone
  size              = 3
  type              = "gp3"

  tags = merge(local.tags, {
    Name = "mvd-kubewk03-ceph-data"
  })
}

resource "aws_volume_attachment" "worker_ceph_01" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.worker_ceph_01.id
  instance_id = aws_instance.mvd_kubewk01.id
}

resource "aws_volume_attachment" "worker_ceph_02" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.worker_ceph_02.id
  instance_id = aws_instance.mvd_kubewk02.id
}

resource "aws_volume_attachment" "worker_ceph_03" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.worker_ceph_03.id
  instance_id = aws_instance.mvd_kubewk03.id
}
