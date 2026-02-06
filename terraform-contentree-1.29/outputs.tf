# Kubespray/Helmfile POC 실행 시 참조용 (CP 3, Worker 3, Ingress 1)

output "vpc_id" {
  description = "POC VPC ID"
  value       = module.vpc.vpc_id
}

output "ansible_controller_public_ip" {
  description = "Ansible 컨트롤러 퍼블릭 IP (Bastion)"
  value       = aws_instance.ansible_controller.public_ip
}

output "control_plane_private_ips" {
  description = "Control Plane 노드 사설 IP (kubeconfig server는 첫 번째 10.150.46.16 사용 가능)"
  value       = ["10.150.46.16", "10.150.46.17", "10.150.46.18"]
}

output "worker_private_ips" {
  description = "Worker 노드 사설 IP"
  value       = ["10.150.46.19", "10.150.46.20", "10.150.46.21"]
}

output "ingress_private_ip" {
  description = "Ingress 노드 사설 IP"
  value       = "10.150.44.16"
}

output "ingress_public_ip" {
  description = "Ingress 노드 EIP (외부 접근)"
  value       = aws_eip.ingress.public_ip
}

# # Kubespray 인벤토리 생성용 (호스트명: mvd-kubecp01~03, mvd-kubewk01~03, mvd-kubert01)
# output "kubespray_inventory" {
#   description = "Kubespray inventory YAML"
#   value       = templatefile("${path.module}/templates/inventory.yaml.tpl", {
#     cp_hosts = [
#       { name = "mvd-kubecp01", ip = "10.150.46.16" },
#       { name = "mvd-kubecp02", ip = "10.150.46.17" },
#       { name = "mvd-kubecp03", ip = "10.150.46.18" },
#     ]
#     worker_hosts = [
#       { name = "mvd-kubewk01", ip = "10.150.46.19" },
#       { name = "mvd-kubewk02", ip = "10.150.46.20" },
#       { name = "mvd-kubewk03", ip = "10.150.46.21" },
#     ]
#     router_host  = { name = "mvd-kubert01", ip = "10.150.44.16" }
#     ansible_user = "ubuntu"
#     ansible_port = 22
#   })
# }

# output "kubespray_inventory_path_hint" {
#   description = "인벤토리 저장 권장 경로"
#   value       = "k8s/kubespray/inventory/poc-contentree-1.29/inventory.yaml"
# }
