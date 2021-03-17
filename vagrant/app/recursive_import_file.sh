#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/file_config.json)
  -m Month          <string> yyyymm (Default Last month)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
json_file=~/file_config.json
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
  file_path=$(echo ${file_path} | sed "s/yyyymm/${yyyymm}/g")
  encode=$(jq -r .[$i].encode ${json_file})
  if [ ${encode} != "null" ] ; then
    encode_op=" -e ${encode}"
  else
    encode_op=""
  fi
  
  null_to_zero_cols=$(jq -r .[$i].null_to_zero_cols ${json_file})
  if [ "${null_to_zero_cols}" != "null" ] ; then
    null_to_zero_cols_op=" -z "$(echo ${null_to_zero_cols} | tr -d " ")
  else
    null_to_zero_cols_op=""
  fi
  table=$(jq -r .[$i].table ${json_file})

  ${script_dir}/import_from_fileserver.sh -f "${file_path}" -t ${table} -m ${yyyymm}${null_to_zero_cols_op}${encode_op}
  result=$?
  if [ ${result} -ne 0 ] ; then
    exit ${result}
  fi
done

exit 0
