# SQLServerから出力する
# 参考: https://qiita.com/cindy-doyle/items/c75ffe8a4891a42c0ad8
sqlcmd -d testdb -U sa -P P@ssw0rd -S 192.168.33.12 -i test.sql -s , -W -o test.csv
# ヘッダを出力する場合は2行目消すとか編集必須かも

# テーブル全件なら
# ""で囲ったりとかフォーマット指定する必要あるならこっちやる必要ある
# フォーマットファイル作成+クエリはたぶんファイル参照できないのでファイルの内容をコマンドに埋め込み
bcp testdb.dbo.test out test.csv -t, -r "\n" -c -C65001 -U sa -P P@ssw0rd -S 192.168.33.12

# CSV編集
sed -i -r "/^[-,]+$/d" test.csv
sed -i -r "s/^([^,]+)/\1,202102/" test.csv

# postgresにインポート
# 参考:https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.html#PostgreSQL.Procedural.Importing.Copy
psql testdb -U testuser -p 5432 -h 192.168.33.11 -c "\COPY test FROM 'test.csv' WITH ( DELIMITER ',', FORMAT CSV, HEADER TRUE)" 

# パスワードファイルについて 参考: https://www.postgresql.jp/document/9.4/html/libpq-pgpass.html
cp /vagrant/pgpassfile ~/.pgpass
chmod 600 ~/.pgpass

# AuroraにつなぐならIAM認証？