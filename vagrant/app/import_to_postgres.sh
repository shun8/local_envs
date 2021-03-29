#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -i CSV file         <string> CSV file path (Required)
  -e Encoding         <string> CSV file Encode (Default Not specified)
  -d Header           <boolean> Exists header (Default FALSE)
  -t Table name       <string> table_name [ ( column_name [, ...] ) ] (Required)
  -m Month            <string> yyyymm for delete (Required)
  -c Config file      <string> Config file path (Default ~/psql_config.sh)
EOM
  exit 2
}

ym_col_name=test_ym
migration_dir="/vagrant/migration/yyyymm"

# デフォルト値設定
encoding_option=""
header="FALSE"
config_file=~/psql_config.sh

# 引数の処理
while getopts ":i:e:d:t:m:c:h" OPTKEY; do
  case ${OPTKEY} in
    i)
      # 絶対パスに変換
      csv_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    e)
      encoding_option=", ENCODING "${OPTARG}
      ;;
    d)
      header=${OPTARG}
      ;;
    t)
      table=${OPTARG}
      ;;
    m)
      yyyymm=${OPTARG}
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
if [ -z "${table}" ] ; then
  echo "Table name is required."
  exit 1
fi
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -c "DELETE FROM ${table} WHERE ${ym_col_name} = '${yyyymm}'"
result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql delete error."
  exit ${result}
fi
result=0
psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -c "\COPY ${table} FROM '${csv_file}' WITH ( DELIMITER ',', FORMAT CSV, HEADER ${header}${encoding_option})" 
result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql copy error."
  exit ${result}
fi

exit 0
