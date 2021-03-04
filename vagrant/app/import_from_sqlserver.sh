#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -i SQL file     <string> SQL file path (Required)
  -m Month        <string> yyyymm (Required)
  -c Config file  <string> Config file path (Default ~/sqlcmd_config.sh)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
config_file=~/sqlcmd_config.sh

# 引数の処理
while getopts ":i:m:c:h" OPTKEY; do
  case ${OPTKEY} in
    i)
      # 絶対パスに変換
      sql_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
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

tmp_file=$(mktemp /tmp/tmp.XXXXXX)
sqlcmd -d ${DB_NAME} -U ${USER_NAME} -P ${PASSWORD} -S ${HOST} -i ${sql_file} -s, -W -h -1 -o ${tmp_file}
result=$?
if [ ${result} -ne 0 ] ; then
  echo "sqlcmd error."
  exit ${result}
fi

# CSV編集(必要なら)
#------,---の行を削除(ヘッダありの場合に使用)
#sed -i -r "/^[-,]+$/d" ${tmp_file}
#yyyymmのカラムを付加
sed -i -r "s/^([^,]+)/\1,${yyyymm}/" ${tmp_file}

# posgresへのインポート実行
${script_dir}/import_to_postgres.sh -i ${tmp_file}
result=$?
if [ ${result} -ne 0 ] ; then
  exit ${result}
fi

rm ${tmp_file}

exit 0
