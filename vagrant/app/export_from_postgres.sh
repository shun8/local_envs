#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -o CSV file Path <string> Output CSV file path (Required)
  -d Header        <boolean> Add header row (Default TRUE)
  -s SQL file Path <string> SQL file path (Required)
  -c Config file   <string> Config file path (Default ~/psql_config.sh)
EOM
  exit 2
}

# デフォルト値設定
header=""
config_file=~/psql_config.sh

# 引数の処理
while getopts ":i:c:h" OPTKEY; do
  case ${OPTKEY} in
    o)
      # 絶対パスに変換
      csv_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    s)
      # 絶対パスに変換
      sql_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    d)
      # 列名と行数表示を無効にするオプション
      header='-t'
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
  echo "Output CSV file is required."
  exit 1
fi
if [ -z "${sql_file}" ] ; then
  echo "SQL file is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -f ${sql_file} -A -F, ${header} | grep -v "^(" > ${csv_file}

result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql error."
  exit ${result}
fi

# 正常終了
exit 0
