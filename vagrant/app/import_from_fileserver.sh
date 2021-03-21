#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -f filepath             <string> filepath (Required)
  -e Encoding             <string> CSV file Encode (Default SJIS)
  -d Header               <boolean> Exists header (Default TRUE)
  -t Table name           <string> table_name [ ( column_name [, ...] ) ] (Required)
  -m Month                <string> yyyymm (Required)
  -z Null to Zero Columns <list> List of Column indexes convert null to 0 (Defarult [])
  -c Config file          <string> Config file path (Default ~/scp_config.sh)
EOM
  exit 2
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
config_file=~/scp_config.sh
#config_file=~/sftp_config.sh
encoding="SJIS"
header="TRUE"
null_to_zero_cols="[]"

# 引数の処理
while getopts ":f:e:d:t:m:z:c:h" OPTKEY; do
  case ${OPTKEY} in
    f)
      filepath=${OPTARG}
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
    z)
      null_to_zero_cols=${OPTARG}
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
# expect -c "
# spawn sftp -P ${PORT} ${USER_NAME}@${HOST}
# expect \"password:\"
# send \"${PASSWORD}\n\"
# expect \"sftp&gt;\"
# send \"get ${filepath} ${tmp_file}\n\"
# expect \"sftp&gt;\"
# send \"bye\n\"
# expect eof
# exit
# "

result=$?
if [ ${result} -ne 0 ] ; then
  echo "scp error."
  #echo "sftp error."  
  exit ${result}
fi

# CSV編集
# CRLF -> LF (行末を正しく判定するため)
sed -i -r "s/\r//" ${tmp_file}
#yyyymmのカラムを付加
sed -i -r 's/$/,"'"${yyyymm}"'"/' ${tmp_file}

len=$(echo ${null_to_zero_cols} | jq length)
for i in $( seq 0 $(($len - 1)) ); do
  col_i=$(echo ${null_to_zero_cols} | jq -r .[$i])
  sed -i -r 's/^([^,]*,){'"${col_i}"'}""/\1"0"/' ${tmp_file}
done

# posgresへのインポート実行
${script_dir}/import_to_postgres.sh -i ${tmp_file} -e ${encoding} -d ${header} -t ${table} -m ${yyyymm}
result=$?
if [ ${result} -ne 0 ] ; then
  exit ${result}
fi

rm ${tmp_file}

exit 0
