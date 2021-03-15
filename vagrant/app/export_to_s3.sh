#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -i Input file Path <string> Input file path (Required)
  -k S3 Key          <string> S3 Object key (Required)  
  -c Config file     <string> Config file path (Default ~/aws_config.sh)
EOM
  exit 2
}

# デフォルト値設定
config_file=~/aws_config.sh

# 引数の処理
while getopts ":i:c:h" OPTKEY; do
  case ${OPTKEY} in
    i)
      # 絶対パスに変換
      input_file=$(cd $(dirname ${OPTARG}) && pwd)/$(basename ${OPTARG})
      ;;
    k)
      s3_key=${OPTARG}
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
if [ -z "${input_file}" ] ; then
  echo "input file is required."
  exit 1
fi

# Config呼び出し
source ${config_file}

aws s3api put_object --bucket ${s3_bucket} --key ${s3_key} --body ${input_file}
result=$?
if [ ${result} -ne 0 ] ; then
  echo "upload error."
  exit ${result}
fi
presigned_url=$(aws s3 presign s3://${s3_bucket}/${s3_key} --expires-in ${s3_presign_expires_in})
if [ ${result} -ne 0 ] ; then
  echo "presign error."
  exit ${result}
fi

# SES動作未検証
tmp_file=$(mktemp /tmp/tmp.XXXXXX)
cp ${ses_json} ${tmp_file}
sed -i "s/presigned_url/${presigned_url}/" ${tmp_file}
# file:// プレフィックスは相対パスで解釈される
cd /tmp
# https://docs.aws.amazon.com/ja_jp/ses/latest/DeveloperGuide/send-personalized-email-api.html
aws ses send-templated-email --cli-input-json ${tmp_file}
if [ ${result} -ne 0 ] ; then
  echo "ses error."
  exit ${result}
fi
rm ${tmp_file}

# 正常終了
exit 0
