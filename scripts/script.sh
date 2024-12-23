#!/bin/bash

# Atualiza os pacotes da maquina
yum update -y

# Instala o git e o docker
yum install git docker amazon-efs-utils  -y
# Inicia o docker e instala o docker compose
systemctl enable docker
systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Cria uma pasta no diretório raiz, para que o compose.yml não fique nos arquivos temporarios

mkdir -p  /files

# Cria um arquivo compose.yml na pasta files
cat <<EOF> /files/compose.yml
services:
  wordpress:
    image: wordpress
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: <ENDPOINT RDS>:3306
      WORDPRESS_DB_USER: admin
      WORDPRESS_DB_PASSWORD: MyNewPass1
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - /mnt/efs:/var/www/html
EOF

sudo mkdir -p /mnt/efs

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-05cf370359e4902e5.efs.us-east-1.amazonaws.com:/ /mnt/efs


sudo docker-compose -f /files/compose.yml up -d