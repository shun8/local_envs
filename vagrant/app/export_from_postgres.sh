#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -o CSV file     <string> output CSV file path (Required)
  -f SQL file     <string> SQL file (Required)
  -e Encoding     <string> CSV file Encode (Default Not specified)
  -d Header       <boolean> Exists header (Default TRUE)
  -m Month        <string> yyyymm for output (Required)
  -c Config file  <string> Config file path (Default ~/psql_config.sh)  
EOM
  exit 2
}

# デフォルト値設定
encoding_option=""
header="TRUE"
config_file=~/psql_config.sh

# 引数の処理
while getopts ":o:f:e:d:m:c:h" OPTKEY; do
  case ${OPTKEY} in
    o)
      # 絶対パスに変換
      csv_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    f)
      # 絶対パスに変換
      sql_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    e)
      encoding_option=", ENCODING "${OPTARG}
      ;;
    d)
      header=${OPTARG}
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
if [ -z "${sql_file}" ] ; then
  echo "SQL file is required."
  exit 1
fi
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

# Config呼び出し
source ${config_file}
sql=$(sed -r "s/\r//g" "${sql_file}" | tr -d ";" | sed -r "s/--.*$//" | sed "s/%(yyyymm)s/'${yyyymm}'/g")
psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -c "\COPY (${sql}) TO '${output}' WITH ( FORMAT CSV, HEADER ${header}${encoding_option})"
result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql error."
  exit ${result}
fi

# 正常終了
exit 0
