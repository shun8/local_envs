#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -f SQL file          <string> SQL file path (Required)
  -t delete Table name <string> table_name (Default Without Deleting)
  -m Month             <string> yyyymm for delete and execute (Default last month)
  -v list of Vars ([var1=Value1,var2=Value2,...]) <list> List of psql params (Defarult [])
  -c Config file       <string> Config file path (Default ~/psql_config.sh)  
EOM
  exit 2
}

ym_col_name=test_ym

# デフォルト値設定
config_file=~/psql_config.sh
yyyymm=$(date -d "$(date +'%Y-%m-01') 1 month ago" +'%Y%m')
var_list="[]"

# 引数の処理
while getopts ":f:t:m:v:c:h" OPTKEY; do
  case ${OPTKEY} in
    f)
      # 絶対パスに変換
      sql_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    t)
      table=${OPTARG}
      ;;
    m)
      yyyymm=${OPTARG}
      ;;
    v)
      var_list=${OPTARG}
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
if [ -z "${sql_file}" ] ; then
  echo "SQL file is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

vars_op=""
len=$(echo "${var_list}" | jq length)
for i in $(seq 0 $(($len - 1))); do
  l_var=$(echo "${var_list}" | jq -r .[$i])
  if [ ${l_var} != "null" ] ; then
    vars_op="${vars_op} -v ${l_var}"
  fi
done

if [ -n "${table}" ] ; then
  psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -c "DELETE FROM ${table} WHERE ${ym_col_name} = '${yyyymm}'"
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "psql delete error."
    exit ${result}
  fi
fi
psql ${DB_NAME} -U ${USER_NAME} -p ${PORT} -h ${HOST} -f ${sql_file}${vars_op}
result=$?
if [ ${result} -ne 0 ] ; then
  echo "psql copy error."
  exit ${result}
fi

# 正常終了
exit 0
