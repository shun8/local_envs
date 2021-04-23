#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/date_config.json)
EOM
  exit 2
}

# デフォルト値設定
json_file=~/date_config.json

# 引数の処理
while getopts ":j:h" OPTKEY; do
  case ${OPTKEY} in
    j)
      # 絶対パスに変換
      json_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done

execute_date=$(jq -r .execute_date ${json_file})
current_date=$(date '+%-d')
if [ "${execute_date}" = "${current_date}" ] ; then
  exit 0
fi

exit 1
