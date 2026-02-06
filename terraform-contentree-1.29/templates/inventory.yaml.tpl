# POC 인벤토리 — CP 3, Worker 3, Ingress 1 (인벤토리 호스트명 k8s 분석과 동일)
# Terraform output: terraform output -raw kubespray_inventory
all:
  vars:
    ansible_port: ${ansible_port}
    ansible_user: ${ansible_user}
    ansible_become: yes
    ansible_hostname: "{{ inventory_hostname }}"
  hosts:
%{for h in cp_hosts~}
    ${h.name}:
      ansible_host: ${h.ip}
%{endfor~}
%{for h in worker_hosts~}
    ${h.name}:
      ansible_host: ${h.ip}
%{endfor~}
    ${router_host.name}:
      ansible_host: ${router_host.ip}
      ip: ${router_host.ip}
  children:
    kube_control_plane:
      hosts:
%{for h in cp_hosts~}
        ${h.name}:
%{endfor~}
    kube_worker:
      hosts:
%{for h in worker_hosts~}
        ${h.name}:
%{endfor~}
      vars:
        node_labels:
          role: worker
          node-role.kubernetes.io/worker: ""
    kube_router:
      hosts:
        ${router_host.name}:
      vars:
        node_labels:
          role: router
          node-role.kubernetes.io/router: ""
    etcd:
      children:
        kube_control_plane:
    kube_node:
      children:
        kube_worker:
        kube_router:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
