#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/sqlserver_config.json)
  -m Month          <string> yyyymm (Default Last month)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
json_file=~/sqlserver_config.json
yyyymm=$(date -d "$(date +'%Y-%m-01') 1 month ago" +'%Y%m')

# 引数の処理
while getopts ":j:m:h" OPTKEY; do
  case ${OPTKEY} in
    j)
      # 絶対パスに変換
      json_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    m)
      yyyymm=${OPTARG}
      ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done

len=$(jq length ${json_file})
for i in $( seq 0 $(($len - 1)) ); do
  file_path=$(jq -r .[$i].file_path ${json_file})
  table=$(jq -r .[$i].table ${json_file})
  vars=$(jq -c -r .[$i].vars ${json_file})
  if [ "${vars}" != "null" ] ; then
    vars_op=" -v "$(echo ${vars} | tr -d " ")
  else
    vars_op=""
  fi

  ${script_dir}/import_from_sqlserver.sh -s ${file_path} -t ${table} -m ${yyyymm}${vars_op}
  result=$?
  if [ ${result} -ne 0 ] ; then
    exit ${result}
  fi
done

exit 0
