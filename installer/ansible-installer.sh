sudo apt update
sudo apt install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

docker run --rm -it --mount type=bind,source=/home/mixcre/kubernetes_installation/kubespray/inventory/mycluster,dst=/inventory \
  --mount type=bind,source=/home/mixcre/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
  --mount type=bind,source=/home/mixcre/.ssh/id_rsa,dst=/home/mixcre/.ssh/id_rsa \
  --mount type=bind,source=/etc/hosts,dst=/etc/hosts \
  quay.io/kubespray/kubespray:v2.16.0 bash 

ansible-playbook -i /inventory/hosts.yaml cluster.yml --user=mixcre --ask-pass --become --ask-become-pass
