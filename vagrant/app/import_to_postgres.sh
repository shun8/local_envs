#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -i CSV file     <string> CSV file path (Required)
  -c Config file  <string> Config file path (Default ~/psql_config.sh)
EOM
  exit 2
}

# デフォルト値設定
config_file=~/psql_config.sh

# 引数の処理
while getopts ":i:c:h" OPTKEY; do
  case ${OPTKEY} in
    i)
      # 絶対パスに変換
      csv_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    c)
      # 絶対パスに変換
      config_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done

# 必須項目
if [ -z "${csv_file}" ] ; then
  echo "CSV file is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -c "\COPY test FROM '${csv_file}' WITH ( DELIMITER ',', FORMAT CSV, HEADER TRUE)" 
result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql error."
  exit ${result}
fi

# 正常終了
exit 0
