#!/bin/bash
# 共有フォルダのパス
shared_folder="/vagrant"
# 接続ユーザ名
user_name="testuser"
# 接続ユーザのパスワード
password="P@ssw0rd"
# 作成するデータベース名
db_name="testdb"

# インストールで使うパッケージ
sudo yum -y install expect

# インストール 参考:http://note.kurodigi.com/centos7-postgresql/
sudo yum -y install postgresql postgresql-server

sudo -u postgres postgresql-setup initdb

sudo -u postgres sed -r "s/^(local +all +peer)$/#\1/" /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres sed -i -r "s/^(local +all +all +peer)$/#\1\nlocal   all             postgres                                peer\nlocal   all             all                                     md5/" /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres sed -i -r "s/^(host +all +all +127.0.0.1\/32 +ident)$/\1\nhost    all             all             192.168.0.0\/16            md5/" /var/lib/pgsql/data/pg_hba.conf
echo "listen_addresses = '*'" | sudo -u postgres tee -a /var/lib/pgsql/data/postgresql.conf

sudo systemctl start postgresql
sudo systemctl enable postgresql

# vagrantユーザのディレクトリだとpostgresユーザの権限がなくてエラーになるので適当なディレクトリに移動
cd /tmp
sudo -u postgres psql -c "CREATE ROLE ${user_name} LOGIN PASSWORD '${password}'"
sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER '${user_name}'"

# Configure DB
for file in `find ${shared_folder}/sql -maxdepth 1 -type f -name *.ddl`; do
    sudo -u postgres psql -U postgres -d ${db_name} -f "${file}"
done

for file in `find ${shared_folder}/sql -maxdepth 1 -type f -name *.sql`; do
    sudo -u postgres psql -U postgres -d ${db_name} -f "${file}"
done

# 雑に権限付与しておく
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} To ${user_name}"
sudo -u postgres psql -d ${db_name} -c "GRANT ALL PRIVILEGES ON SCHEMA public To ${user_name}"
sudo -u postgres psql -d ${db_name} -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public To ${user_name}"