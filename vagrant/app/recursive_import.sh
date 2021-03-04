#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -d SQL file Dir   <string> SQL file Dir path (Required)
  -m Month          <string> yyyymm (Required)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

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

# 必須項目
if [ -z "${sql_file_dir}" ] ; then
  echo "SQL file Dir is required."
  exit 1
fi
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

for file in $(ls ${sql_file_dir}/*.sql) ; do
    table=$(basename ${file})
    ${script_dir}/import_from_sqlserver.sh -s ${file} -t ${table%.*} -m ${yyyymm}
done
result=$?
if [ ${result} -ne 0 ] ; then
  exit ${result}
fi

exit 0
