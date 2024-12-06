apt update && apt install wget -y
wget https://github.com/prometheus/prometheus/releases/download/v2.42.0-rc.0/prometheus-2.42.0-rc.0.linux-amd64.tar.gz
tar -xzvf prometheus-2.42.0-rc.0.linux-amd64.tar.gz
rm -f prometheus-2.42.0-rc.0.linux-amd64.tar.gz