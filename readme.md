# Docker e AWS - Wordpress.

Esse projeto de forma geral fará uso de EC2s(Elastic Compute Clouding), Amazon RDS, Load Balancer, Auto Scaling.

---

##### Passo 1: Criando uma VPC.

##### Passo 2: Criando os Security groups.

##### Passo 3: Criando o RDS.

##### Passo 4: Criando o EFS.

##### Passo 5: Criando e configurando o Nat Gateway.

##### Passo 6: Organizando os endpoints no script user data.

##### Passo 7: Criando um Bastion Host.

##### Passo 8: Criando um launch template.

##### Passo 9: Criando instancias.

##### Passo 10: Criando um Load Balancer.

##### Passo 10: Finalmente! Criando um auto scaling group e testando a nossa aplicação final.

---

##### Passo 1: Criando uma VPC.

No seu AWS Console, busque por VPC, em seguida clique em criar VPC.

- Especificações:
  - ###### Nome: WEB-WORDPRESS-VPC
  - 2 AZ(Zonas de disponilidade)
  - 3 subnets públicas e 2 privadas.

![alt text](/images/VPC.jpeg)

##### Passo 2: Criando os Security groups.

Agora iremos criar os Security Groups(SG), iremos criar dois SG, um público, que será usado pelo Load Balancer e o Bastion Host. E um privado, que será usado, pelas instancias EC2, RDS e todos os resources que exigem níveis de seguranaça.

![alt text](/images/SGs.jpeg)

Vá para:

##### `VPC > Security Groups > Criar Security Group`

- Especificações:

  - ###### Nome: WEB-WORDPRESS-PUBLIC-SG
  - VPC: WEB-WORDPRESS-VPC-vpc
  - Inbound rules(regras de entrada): HTTP - 80 - 0.0.0.0/0 ; SSH - 22 - 0.0.0.0/0.

  - ###### Nome: WEB-WORDPRESS-PRIVATE-SG
  - VPC: WEB-WORDPRESS-VPC-vpc
  - Inbound rules(regras de entrada): Mysql/Aurora - 3306 - 0.0.0.0/0; HTTPS - 444 - WEB-WORDPRESS-PUBLIC-SG ; HTTP - 80 - WEB-WORDPRESS-PUBLIC-SG ; SSH - 22 - WEB-WORDPRESS-PUBLIC-SG; HTTPS - 443 - WEB-WORDPRESS-PUBLIC-SG.

Após ter criado os security groups, vá no WEB-WORDPRESS-PRIVATE-SG, em editar regras de entrada, e adicione a seguinte regra:

- NFS - Source: WEB-WORDPRESS-PRIVATE-SG

##### Passo 3: Criando o RDS.

##### `RDS > Criar database`

- Especificações:

  - ###### WEB-WORDPRESS-RDS
  - MYSQL.
  - FreeTier.
  - WEB-WORDPRESS-RDS
  - Autenticação: Admin - MyNewPass1.
  - db.t3.micro.
  - Não conecte com uma EC2.
  - WEB-WORDPRESS-VPC-vpc.
  - SG : WEB-WORDPRESS-PRIVATE-SG.
  - Configuração adicional: Banco de dados inicial: wordpress.
  - ###### Criar banco.

##### Passo 4: Criando o EFS.

##### `EFS > Criar File System`

- Especificações:

  - ###### Nome: WEB-WORDPRESS-EFS.
  - WEB-WORDPRESS-VPC-vpc.
  - ###### Criar.

Clique no file system criado, na seção de Network clique em manage e mude os security groups para o WEB-WORDPRESS-PRIVATE1-SG.

![alt text](/images/efsconfig.png)

##### Passo 5: Criando e configurando o Nat Gateway.

O Nat Gateway vai permitir a conexão das instancias privadas com a internet.

##### `VPC > Nat Gateways > Criar Nat Gateway`

- Especificações:

  - ###### Nome: WEB-WORDPRESS-NAT-GATEWAY.
  - Subnet: WEB-WORDPRESS-VPC-subnet-public1-us-east-1a.
  - Tipo de Conectividade: Publica.
  - Clicar em Alocar IP Elastico.
  - WEB-WORDPRESS-VPC-vpc.

  ![alt text](/images/nat-gateway.jpeg)

  - ###### Criar.

Agora iremos associar o nat gateway às subnets privadas através da route table.

##### `VPC > Route tables`

- Na subnet: WEB-WORDPRESS-VPC-rtb-private1-us-east-1a:
  - Clique na subnet, e vá na seção Routes
    ![alt text](/images/rotas.jpeg)
  - Editar rotas, clique em nova rota, e coloque `0.0.0.0/0` como destino e Nat Gateway como target, em seguida selecione o nat gateway criado anteriormente.
    ![alt text](/images/editRoutes.jpeg)
- Na subnet: WEB-WORDPRESS-VPC-rtb-private2-us-east-1b, faça o mesmo processo.

##### Passo 6: Organizando os endpoints no script user data.

No nosso user data usamos dois endpoints, um do RDS e outro do EFS.

- Copie o user data abaixo e colo em um editor de código, ou qualquer outro editor de texto.

- Vá no seu RDS criado, clique nele, e na seção Conectivade e segurança, copie o endpoint.
- No user data que está no seu editor de texto, vá no `<ENDPOINT RDS>` e substitua pelo endpoint do RDS.

- Vá no EFS criado, clique nele, clique em `Attach/anexar`, e copie o comando abaixo de `Usando o client NFS`.
- No user data procure a linha que inicia com `sudo mount -t nfs4`, substitua-a pelo comando que você copiou. E no final do comando onde tiver `:/ efs`, substitiua por `:/ /mnt/efs`.

```
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

```

Verifique todos os seus endpoints antes de prosseguir.

##### Passo 7: Criando um Bastion Host.

Por questões de segurança, criamos uma máquina que possa acessar as nossas instancias privadas, e também para testar o nosso script user data.

##### `EC2 > Instancias > Launch Instances`

- Especificações:

  - ###### Nome: WEB-WORDPRESS-BASTION-HOST.
  - Key pair : pbnov24
  - Editar configurações de rede: WEB-WORDPRESS-VPC;
  - Subnet-public1-us-east-1a;
  - Habilitar IP Público;
  - Selecionar SG: WEB-WORDPRESS-PUBLIC-SG.
  - Detalhes avançados, User data: Cole o seu user data no campo.
  - ###### Launch Instance.

Espere a instancia ficar com o status checked.

Clique na instancia, Copie o IP Público dela e cole no seu navegador.

Ela pode demorar um pouco pra carregar por conta de ainda estar iniciando o container. Então enquanto ela carrega você pode seguir para o próximo passo.

Deve aparecer a página inicial do Wordpress.

![alt text](/images/BH.png)

##### Passo 8: Criando um launch template.

##### `Instancias > Launch Templates > Launch Instances > Criar template`

- Especificações:

  - ###### Nome: WEB-WORDPRESS-SERVERS.
  - Quick start: Amazon Linux
  - t2.micro
  - Key pair : pbnov24
  - Não selecione a subnet.
  - Selecionar SG: WEB-WORDPRESS-PRIVATE-SG.
  - Detalhes avançados, User data: Cole o seu user data no campo.
  - ###### Launch Instance.

##### Passo 9: Criando instancias.

##### `Instancias > Launch Instance.Launch Instance from template`

Selecione o template criado.

- Especificações:
  - Subnet: WEB-WORDPESS-VPC-subnet-private1-us-east-1a.

Cheque se todos os campos estão ok, principalmente o SG e o user data.

- ###### Launch Instance.

Agora iremos verificar se a instancia está ok, acessando-a pelo Bastion Host.

![alt text](/images/accessSSHBH.png)

Clique em conect, e ele irá abrir dentro do BastionHost.

Iremos agora fazer o acesso ssh da instancia privada.

Abra a sua keypair utilizada na instancia e cole no arquivo pbnov24 aberto pelo nano, `Ctrl + o` e Enter e depois `Ctrl + x` para sair.
Copie o Ip privado da instancia criada.
` sudo ssh -i "pbnov24" ec2-user@<ip privado da instancia>`

![alt text](/images/sshS1.png)

Siga os comonados da imagem acima.

```
> cd .ssh
> nano pbnov24 #cole o conteúdo da sua keypair
> ls
> sudo ssh -i "pbnov24" ec2-user@<ip privado da instancia>
```

![alt text](/images/sshprivate.png)

Siga os comonados da imagem acima.

```
> sudo docker ps
> cd /mnt
> df -h
```

Observe se o seu mount está ok. Se o seu Bastion Host está mostrando o wordpress e o seu mount está mostrando o link do efs amazon, então agora nos resta apenas criar um Load Balancer e o Auto Scaling.

##### Passo 10: Criando um Load Balancer.

##### `Load Balancers > Criar Load Balancer`

Procure por Classic Load Balancer e clique em criar.

- Especificações:
- ###### Nome: WEB-WORDPRESS-CLB.
- Internet-facing.
- Network mapping: WEB-WORDPRESS-VPC, Selecione as duas az e coloque a subnte public.
- SG: WEB-WORDPRESS-PUBLIC-SG.
- Healthy checks: /wp-admin/install.php

- ###### Criar.

- Agora crie outra instancia usando o template WEB-WORDPRESS-SERVERS para testarmos o Load Balancer.

![alt text](/images/instances.png)

- Neste mommento o que nos resta é associar as instancias criadas para verificar se o Load Balancer está de fato funcionando.

##### `Load Balancers > WEB-WORDPRESS-CLB > Seção no LB de Target Instances > Manage Instances`

- Vá para a seção de target Instances, Manage Instances.

![alt text](/images/manageInstances.png)

- Agora na targe=t Instances, verifique se o Healthy status das instancias está In-Service.

Copie e acesse o DNS do load balancer no seu navegador.

![alt text](/images/lbtest.png)

Testando em outro dispositivo:

![alt text](/images/lbtest2.jpeg)

Já que o nosso Load Balancer está rodando, iremos dar inicio a criação do Auto Scaling.

Até agora temos:

![alt text](/images/diagrama.png)

##### Passo 10: Finalmente! Criando um auto scaling group e testando a nossa aplicação final.

##### `Auto Scaling groups> Criar Auto Scaling group >`

- Especificações:
- ###### Nome: WEB-WORDPRESS-ASG.
- Selecione o Launch template WEB-WORDPRESS-SERVERS.
- WEB-WORDPRESS-VPC
- Selecione as subnets privadas.
- Anexar a um Load Balancer existente.
- Escolher Classic Load Balancer: WEB-WORDPRESS-CLB.
- Habilitar ELB health checks.
- Group size: Capacidade desejada (2), Min(1), Max(2).
- Target tracking scaling policy: Average CPU utilization (target - 70, 200s), a média de utilização da CPU será 70% e ele avaliará as métricas com uma janela de 200 segundos.
- Terminate and Launch.
- Enable group metrics collection within CloudWatch.
- Add Notification: ex: my-sns-topic(seuemail@gmai.com).

- ###### Criar.

Vá no link DNS aberto do Load balancer e faça o refresh ou recarregue com F5. Se você for nas suas instancias, o número delas deve ter aumentado.

![alt text](/images/teste.png)

Agora, a estrutura do nosso projeto
![alt text](/images/diagrama3.png)

Testando em um dispositivo de outra rede:

![alt text](/images/teste4.jpeg)

Portanto temos agora a nossa aplicação funcionando e completa.
