#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -s SQL file                 <string> SQL file path (Required)
  -m Month                    <string> yyyymm (Default Last month)
  -v List of Vars (["var1=Value1","var2=Value2",...]) <list> List of sqlcmd params. yyyymm replase to Month. (Defarult [])
  -c Config file              <string> Config file path (Default ~/sqlcmd_config.sh)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
config_file=~/sqlcmd_config.sh
var_list="[]"
yyyymm=$(date -d "$(date +'%Y-%m-01') 1 month ago" +'%Y%m')

# 引数の処理
while getopts ":s:m:t:v:c:h" OPTKEY; do
  case ${OPTKEY} in
    s)
      # 絶対パスに変換
      sql_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
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
for i in $( seq 0 $(($len - 1)) ); do
  l_var=$(echo "${var_list}" | jq -r .[$i])
  if [ ${l_var} != "null" ] ; then
    vars_op="${vars_op}"$(echo " -v ${l_var}" | sed "s/yyyymm/${yyyymm}/g")
  fi
done

sql_result=$(sqlcmd -d ${DB_NAME} -U ${USER_NAME} -P ${PASSWORD} -S ${HOST} -i ${sql_file} -W -h -1 -w 65535 ${vars_op})
result=$?
if [ ${result} -ne 0 ] ; then
  echo "sqlcmd error."
  exit ${result}
fi

if [ "${sql_result}" = "0" ] ; then
  exit 0
fi

exit 1
