docker run \
--name=kubespray \
--network=host \
--detach \
--restart=always \
--mount type=bind,source="$(pwd)",dst=/kubespray/inventory \
--mount type=bind,source=/root/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
--env ANSIBLE_HOST_KEY_CHECKING=False \
kubespray:latest sleep infinity
