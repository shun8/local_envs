#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -f filepath     <string> filepath (Required)
  -m Month        <string> yyyymm (Required)
  -c Config file  <string> Config file path (Default ~/scp_config.sh)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
config_file=~/scp_config.sh

# 引数の処理
while getopts ":f:m:c:h" OPTKEY; do
  case ${OPTKEY} in
    f)
      # 絶対パスに変換
      filepath=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
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
if [ -z "${yyyymm}" ] ; then
  echo "Month is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

tmp_file=`mktemp /tmp/tmp.XXXXXX`
scp -i ${KEY_FILE} -P ${PORT} -o "StrictHostKeyChecking=no" ${USER_NAME}@${HOST}:${filepath} ${tmp_file}
result=$?
if [ ${result} -ne 0 ] ; then
  echo "scp error."
  exit ${result}
fi

# CSV編集
sed -i -r "s/^([^,]+)/\1,${yyyymm}/" ${tmp_file}

# posgresへのインポート実行
${script_dir}/import_to_postgres.sh -i ${tmp_file}
result=$?
if [ ${result} -ne 0 ] ; then
  exit ${result}
fi

rm ${tmp_file}

exit 0
