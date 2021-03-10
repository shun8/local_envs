#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -d SQL file Dir   <string> SQL file Dir path (Default ~/sql)
  -m Month          <string> yyyymm (Default Last month)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
sql_file_dir=~/sql
yyyymm=$(date -d "$(date +'%Y-%m-01') 1 month ago" +'%Y%m')

# 引数の処理
while getopts ":d:m:h" OPTKEY; do
  case ${OPTKEY} in
    d)
      # 絶対パスに変換
      sql_file_dir=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    m)
      yyyymm=${OPTARG}
      ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done

for file in $(ls ${sql_file_dir}/*.sql) ; do
    table=$(basename ${file})
    ${script_dir}/import_from_sqlserver.sh -s ${file} -t ${table%.*} -m ${yyyymm}
    result=$?
    if [ ${result} -ne 0 ] ; then
      exit ${result}
    fi
done

exit 0
