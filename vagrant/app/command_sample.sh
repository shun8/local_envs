# SQLServerから出力する
# 参考: https://qiita.com/cindy-doyle/items/c75ffe8a4891a42c0ad8
sqlcmd -d testdb -U sa -P P@ssw0rd -S 192.168.33.12 -i test.sql -s , -W -o test.csv
# ヘッダを出力する場合は2行目消すとか編集必須かも

# テーブル全件なら
bcp testdb.dbo.test out test.csv -t, -r "\n" -c -C65001 -U sa -P P@ssw0rd -S 192.168.33.12

# postgresはパスワードファイル作る
# 参考: https://www.postgresql.jp/document/9.4/html/libpq-pgpass.html
