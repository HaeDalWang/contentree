docker run \
--name=kubespray \
--network=host \
--detach \
--restart=always \
--mount type=bind,source="$(pwd)/inventory",dst=/kubespray/inventory \
--mount type=bind,source="$(pwd)/extra_playbooks",dst=/kubespray/extra_playbooks \
--mount type=bind,source="$(pwd)/artifacts",dst=/kubespray/artifacts \
--mount type=bind,source=/root/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
--env ANSIBLE_HOST_KEY_CHECKING=False \
quay.io/kubespray/kubespray:v2.21.0 sleep infinity
