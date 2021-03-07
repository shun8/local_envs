#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -f filepath     <string> filepath (Required)
  -e Encoding     <string> CSV file Encode (Default SJIS)
  -d Header       <boolean> Exists header (Default TRUE)
  -t Table name   <string> table_name [ ( column_name [, ...] ) ] (Required)
  -m Month        <string> yyyymm (Required)
  -c Config file  <string> Config file path (Default ~/scp_config.sh)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
config_file=~/scp_config.sh
encoding="SJIS"
header="TRUE"

# 引数の処理
while getopts ":f:e:d:t:m:c:h" OPTKEY; do
  case ${OPTKEY} in
    f)
      # 絶対パスに変換
      filepath=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    e)
      encoding=${OPTARG}
      ;;
    d)
      header=${OPTARG}
      ;;
    t)
      table=${OPTARG}
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
if [ -z "${filepath}" ] ; then
  echo "Filepath is required."
  exit 1
fi
if [ -z "${table}" ] ; then
  echo "Table is required."
  exit 1
fi
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

tmp_file=`mktemp /tmp/tmp.XXXXXX`
scp -i ${KEY_FILE} -P ${PORT} -o "StrictHostKeyChecking=no" ${USER_NAME}@${HOST}:"${filepath}" ${tmp_file}
result=$?
if [ ${result} -ne 0 ] ; then
  echo "scp error."
  exit ${result}
fi

# CSV編集
# CRLF -> LF (行末を正しく判定するため) & ダブルクォーテーション除去
sed -i -r 's/["'"\r]//g" ${tmp_file}
#yyyymmのカラムを付加
sed -i -r "s/$/,${yyyymm}/" ${tmp_file}

# posgresへのインポート実行
${script_dir}/import_to_postgres.sh -i ${tmp_file} -e ${encoding} -d ${header} -t ${table} -m ${yyyymm}
result=$?
if [ ${result} -ne 0 ] ; then
  exit ${result}
fi

rm ${tmp_file}

exit 0
