#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/file_config.json)
  -m Month          <string> yyyymm (Required)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
json_file=~/file_config.json

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

# 必須項目
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

len=$(jq length ${json_file})
for i in $( seq 0 $(($len - 1)) ); do
  file_path=$(jq -r .[$i].file_path ${json_file})
  encode=$(jq -r .[$i].encode ${json_file})
  if [ ${encode} != "null" ] ; then
    encode_op=" -e ${encode}"
  else
    encode_op=""
  fi
  table=$(jq -r .[$i].table ${json_file})

  ${script_dir}/import_from_fileserver.sh -f "${file_path}" -t ${table} -m ${yyyymm}${encode_op}
  result=$?
  if [ ${result} -ne 0 ] ; then
    exit ${result}
  fi
done

exit 0
