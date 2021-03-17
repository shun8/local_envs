#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/export_config.json)
  -m Month          <string> yyyymm (Default Last month)
EOM
  exit 2
}

function upload_and_presign {
  local bucket=$1
  local key=$2
  local body=$3
  local presign_expires_in=$4
  aws s3api put_object --bucket ${bucket} --key ${key} --body ${body}
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "s3 upload error."
    exit ${result}
  fi

  local presigned_url=$(aws s3 presign s3://${bucket}/${key} --expires-in ${presign_expires_in})
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "s3 presign error."
    exit ${result}
  fi

  echo "${presigned_url}"
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
json_file=~/export_config.json
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

venv_path=$(jq -r ".venv_path" ${json_file})
xlsx_exportpy_path=$(jq -r ".xlsx_exportpy_path" ${json_file})
csv_exportsh_path=$(jq -r "csv_exportsh_path" ${json_file})

presigned_urls=""

# xlsx files
list=$(jq ".files.xlsx" ${json_file})
len=$(echo "${list}" | jq length)
for i in $( seq 0 $(($len - 1)) ); do
  format_file_path=$(echo "${list}" | jq -r .[$i].formatfile)
  tmp_file=$(mktemp /tmp/tmp.XXXXXX)
  source ${venv_path}
  python ${xlsx_exportpy_path} ${format_file_path} ${tmp_file} ${yyyymm}
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "xlsx create error."
    exit ${result}
  fi

  s3_bucket=$(echo "${list}" | jq -r .[$i].s3.bucket)
  s3_key=$(echo "${list}" | jq -r .[$i].s3.key | sed "s/yyyymm/${yyyymm}/g")
  s3_presign_expires_in=$(echo "${list}" | jq -r .[$i].s3.presign_expires_in)
  presigned_url=$(upload_and_presign ${s3_bucket} ${s3_key} ${tmp_file} ${s3_presign_expires_in})

  presigned_urls=${presigned_urls}"${s3_bucket}/${s3_key}\n${presigned_url}\n"
  rm ${tmp_file}
done

# csv files
list=$(jq ".files.csv" ${json_file})
len=$(echo "${list}" | jq length)
for i in $( seq 0 $(($len - 1)) ); do
  encoding=$(echo "${list}" | jq -r .[$i].encoding)
  sql_file=$(echo "${list}" | jq -r .[$i].sqlfile)
  tmp_file=$(mktemp /tmp/tmp.XXXXXX)
  source ${venv_path}
  ${csv_exportsh_path} -o ${tmp_file} -f ${sql_file} -e ${encoding} -m ${yyyymm}
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "csv create error."
    exit ${result}
  fi

  s3_bucket=$(echo "${list}" | jq -r .[$i].s3.bucket)
  s3_key=$(echo "${list}" | jq -r .[$i].s3.key | sed "s/yyyymm/${yyyymm}/g")
  s3_presign_expires_in=$(echo "${list}" | jq -r .[$i].s3.presign_expires_in)
  presigned_url=$(upload_and_presign ${s3_bucket} ${s3_key} ${tmp_file} ${s3_presign_expires_in})

  presigned_urls=${presigned_urls}"${s3_bucket}/${s3_key}\n${presigned_url}\n"
  rm ${tmp_file}
done

# SES
mail_from=$(jq -r ".mail.from" ${json_file})
mail_subject=$(jq -r ".mail.subject" ${json_file} | sed "s/yyyymm/${yyyymm}/g")
mail_text=$(jq -r ".mail.text" ${json_file} | sed "s/yyyymm/${yyyymm}/g")"\n"${presigned_urls}
list=$(jq ".mail.to" ${json_file})
len=$(echo "${list}" | jq length)
for i in $( seq 0 $(($len - 1)) ); do
  mailto=$(echo "${list}" | jq -r .[$i])
  aws ses send-email --to ${mail_to} --from ${mail_from} --subject ${mail_subject} --text $(echo -e "${mail_text}")
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "ses error."
    exit ${result}
  fi
done

# 正常終了
exit 0
