# 参考: https://qiita.com/cindy-doyle/items/c75ffe8a4891a42c0ad8
sqlcmd -d testdb -U sa -P P@ssw0rd -S 192.168.33.12 -i test.sql -s , -o test.csv

bcp testdb.dbo.test out test.csv -t, -r "\n" -c -C65001 -U sa -P P@ssw0rd -S 192.168.33.12
