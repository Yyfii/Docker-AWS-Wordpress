# Docker e AWS - Wordpress.

- Esse projeto de forma geral fará uso de EC2s(Elastic Compute Clouding), Amazon RDS, Load Balancer.

## Construindo um Container Wordpress

Siga os babies steps abaixo:

## Passo 1: Testando o worpress localmente:

1. Baixar a imagem (pode ser baixada durante a )
   No link official da image : pull wordpress, mas por questões de eficiencia, podemos fazer o pull da imagem diretamente no run.

`> docker run -d -p 3002:80 --name 
wordpress_app_v2 wordpress`

- Esse comando está criando um container que está rodando em modo detached(no background), ou seja ele não vai ficar executando no terminal. `-p 3002:80`, a 3002 indica a porta que está sendo exposta no host para acessar a aplicação wordpress que está sendo exposta na porta 80(porta padrão da web).
- Agora no browser: localhost:3002, é possível acessar a aplicação wordpress.

O Wordpress por padrão deve receber as informações de um banco de dados para que ele possa realizar consultas. O que configuraremos em breve.

![alt text](images/wordpress.png)

## Passo 2: Testando o wordpress com o banco.

No site oficial: https://hub.docker.com/_/wordpress
Tem um exemplo docker-compose.yml, copie e crie um arquivo .yml no seu diretório.

- compose.yml

```
services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: rds
      WORDPRESS_DB_USER: mainUser
      WORDPRESS_DB_PASSWORD: mainPassword
      WORDPRESS_DB_NAME: website
      - wordpress:/var/www/html
  rds:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: website
      MYSQL_USER: mainUser
      MYSQL_PASSWORD: mainPassword
      MYSQL_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - rds:/var/lib/mysql

volumes:
  wordpress:
  rds:

```

```
>docker compose up
```

Isso vai criar dois containers, um para o wordpress e outro para o mysql.
O nosso objetivo agora é criar uma instancia EC2 que se conecte a esse container mysql.
agora você pode acessar na porta 8080.
localhost:8080

![alt text](images/wordpressHello.png)

## Passo 3: Criando uma instancia EC2

![alt text](images/ec2.png)

- - EBS(Elastic Block Storage) : Armazenamento persistente.

1. Primeiramente é necessário uma conta AWS.
2. Uma vez, que você conseguiu logar na sua conta. Busque por EC2 (Elastic Compute Clouding).
3. Click em Launch Instances.
   3.1 Name -> o nome da sua ec2 - "ec2-wordpress"
   3.2 Escolher o OS(sistema operacional da sua ec2), Amazon Linux.
   3.3 Key pair: create new pair> RSA > .pem. (\*.pem para mac, linux e windows e .ppk para versões do windows menores que a versão 10) Create pair.

Ele irá automaticamento baixar a keypair, você pode colocá-la na pasta do seu projeto. Ela pode ser usada para acesso ssh(remoto) da sua ec2.

3.4 Network settings > Security Groups > create security group > allow ssh traffic from anywhere 0.0.0.0/0 e allow http traffic from the internet.

3.5 Launch Instance.

Agora você tem uma instancia ec2 criada, clique em cima dela e na parte inferior e mostrará as informações sobre a ec2. Em detalhes busque por ipv4 público, copie-o, pois ele será usado para fazer o acesso remoto via ssh.

Agora no seu diretório do projeto.

Onde sua keypair está presente, abra com uma IDE de escolha, por exemplo estou usando o VSCode. Com o seu diretório aberto no vscode, abra um novo terminal e digite:

`> ssh -i video.pem ec2-user@<ip_publico_ec2>`

Pontos Importantes: Tenha certeza de que sua keypair esteja no mesmo diretorio em que você se encontre no terminal.

- Se você encontrar o mesmo erro descrito na imagem abaixo:
  ![alt text](images/errorSSH.png)

Esse erro ocorre pois esse arquivo não deve ter permissões abertas para todos, já que se trata de uma chave de segurança. Portanto, ele não aceita uma keypair/chave de segurança que não está devidamente protegida, é uma forma de segurança.
Para corrigir o erro:
Vá até a sua pasta no Windows, clique com o botão direito no arquivo video.pem : Conceder acesso> Pessoas específicas> E escolha o proprietário apenas, compartilhe e pronto! Appós isso, o comando deverá rodar novamente.

![alt text](images/ec2running.jpeg)

Agora, temos uma instancia EC2 rodando.
Infelizmente devemos deletar a nossa instancia agora, pois ele serviu como um aprendizado para conhecer o processo de criação de uma EC2. Mas, é como dizem "Pods are cattle, not pets", não devemos tratar as nossas instancias como pets, elas devem servir ao nosso objetivo, o qual é o aprendizado.

## Passo 3: Deletando uma instância EC2.

Em instancias, clique na sua instancia.

1. Instancia State > Stop Instance.
2. Espere até que o estado dela passe de stopping para stopped, isso pode levar até 3 minutos.
3. Clique novamente em instance state > Terminate(delete) instance.

Isso pode demorar um pouco, mas não se preocupe.

## Passo 4: Criando EC2 e User Data script.

- User data : é um setup bootstarp para configurar a ec2 durante a primeira launch(execução).

##### EC2 User Data scripts são executados com a User Info

##### 1. Launch Instance

##### 1.2 Keypair : RSA, .pem > Criar par.

##### 1.3 Network Settings.

Nossa instancia vai ter um ip público, com um grupo de segurança(que vai controlar o tráfico da e para a nossa instancia ec2) e podemos adicionar rules(regras).

1. SSH traffic from and HTTP traffic from the internet -> Anywhere (0.0.0.0/0)

##### 1.4 Advanced Details

##### User data

Você pode criar um arquivo.sh e fazer o upload tbm, mas por motivos de aprendizado colocaremos manualmente.

```
#!/bin/bash
#Install httpd
yum update
yum install -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1> Hello World from $(hostname -f) </h1>" > /var/www/html/index.htlml
```

Cole o código acima no user data.

[![Watch the video](https://img.youtube.com/vi/T-D1KVIuvjA/maxresdefault.jpg)](images/launchInstance.mp4)
