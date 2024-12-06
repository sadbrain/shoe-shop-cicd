apt update && apt install wget -y
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar -xzvf node_exporter-1.5.0.linux-amd64.tar.gz
cd node_exporter-1.5.0.linux-amd64
mv node_exporter /usr/local/bin
cd ..
rm -rf node_exporter-1.5.0.linux-amd64.tar.gz node_exporter-1.5.0.linux-amd64
cd /usr/local/bin
chown node_exporter:node_exporter /usr/local/bin/node_exporter
node_exporter --version