ApKdatabase123

# Creating an Amazon RDS DB intance:

requisites:

- network fort the db instance: You can create an Amazon RDS DB instance only in a virtual private cloud(VPC) based on the Amazon VPC service. It must be in an AWS Region that has at least 2 az.

To set up connectivity between your new db instance and an amazon ec2 instance in the same vpc. To connect to your db instance from resources other than ec2 instances in the same vpc, configure the network connections manually.

The db instance is created in the same vpc as the ec2 instance so that the ec2 instance can access the db instance.

- Requirements to connect an ec2 with the db instance:

- the ec2 must exist in the AWS region before you create the db instance.

DROP DATABASE IF EXISTS lotr;
CREATE DATABASE lotr;
use lotr;
CREATE TABLE characters(
id integer primary key auto_increment,
name varchar(255) not null,
details varchar(255) not null
);
INSERT INTO characters(nome, details) values("Aragon", "King of fools land in green peace.");
CREATE USER 'frodo'@'172.31.%.%' IDENTIFIED WITH mysql_native_password BY 'MyNewPass1';
GRANT ALL PRIVILEGES ON lotr* TO 'frodo'@'172.31.%.%';
SELECT * FROM characters;
