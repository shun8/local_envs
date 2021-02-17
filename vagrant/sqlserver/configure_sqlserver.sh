#!/bin/bash
# 設定する変数
# 共有フォルダのパス
shared_folder="/vagrant"
# システム管理者(SA)のパスワード
password="P@ssw0rd"
# 作成するデータベース名
db_name="testdb"

# インストールで使うパッケージ
sudo yum -y install expect

# インストール 参考:https://docs.microsoft.com/ja-jp/sql/linux/quickstart-install-connect-red-hat?view=sql-server-ver15
# SQLServerのyumリポジトリ登録 参考:https://docs.microsoft.com/ja-jp/sql/linux/sql-server-linux-change-repo?view=sql-server-ver15&pivots=ld2-rhel
sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/8/mssql-server-2019.repo
sudo yum -y install compat-openssl10
sudo yum -y install mssql-server
# expectで対話式の設定 参考:https://qiita.com/ine1127/items/cd6bc91174635016db9b
expect -c "
set timeout 10
spawn sudo alternatives --config python
expect \"number:\"
send \"2\n\"
expect \"$\"
exit 0
"

expect -c "
set timeout 10
spawn sudo /opt/mssql/bin/mssql-conf setup
expect \"edition\"
send \"2\n\"
expect \"license terms\"
send \"Yes\n\"
expect \"password:\"
send \"${password}\n\"
expect \"password:\"
send \"${password}\n\"
expect \"$\"
exit 0
"

# 自動起動
sudo systemctl enable mssql-server

# sqlcmdとbcp 参考:https://docs.microsoft.com/ja-jp/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
if !(type "sqlcmd" > /dev/null 2>&1); then
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
  echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
  source ~/.bashrc
fi

sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/8/prod.repo
sudo yum -y remove unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
sudo ACCEPT_EULA=Y yum -y install msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y yum -y install mssql-tools
# optional: for unixODBC development headers
sudo yum -y install unixODBC-devel

# Configure DB
sqlcmd -U "sa" -P "${password}" -S "localhost" -Q "CREATE DATABASE ${db_name}"

for file in `find ${shared_folder}/sql -maxdepth 1 -type f -name *.ddl`; do
    sqlcmd -U "sa" -P "${password}" -S "localhost" -d "${db_name}" -i "${file}"
done

for file in `find ${shared_folder}/sql -maxdepth 1 -type f -name *.sql`; do
    sqlcmd -U "sa" -P "${password}" -S "localhost" -d "${db_name}" -i "${file}"
done
