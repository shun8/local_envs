#!/bin/bash
function usage {
  cat <<EOM
Usage: $(basename "$0") [OPTION]...
  -h Display help
  -j Config JSON    <string> Config JSON file path (Default ~/execute_config.json)
  -m Month          <string> yyyymm (Default Last month)
EOM
  exit 2
}

# TODO
function send_mail {
  # SES
  mail_from=$(jq -r ".mail.from" ${json_file})
  mail_subject=$(jq -r ".mail.subject" ${json_file} | sed "s/yyyymm/${yyyymm}/g")
  mail_text=$(jq -r ".mail.text" ${json_file} | sed "s/yyyymm/${yyyymm}/g")"\n"${presigned_urls}
  list=$(jq ".mail.to" ${json_file})
  len=$(echo "${list}" | jq length)
  for i in $( seq 0 $(($len - 1)) ); do
    mail_to=$(echo "${list}" | jq -r .[$i])
    aws ses send-email --to "${mail_to}" --from "${mail_from}" --subject "${mail_subject}" --text "$(echo -e "${mail_text}")"
    result=$?
    if [ ${result} -ne 0 ] ; then
      echo "ses error."
      exit ${result}
    fi
  done
}

# 自分自身のディレクトリを取得
script_dir=$(cd $(dirname ${0}) && pwd)

# デフォルト値設定
json_file=~/execute_config.json
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

len=$(jq ".commands[] | length" ${json_file})
for i in $(seq 0 $(($len - 1))); do
  command=$(jq -r .commands[$i].command ${json_file})
  options=$(jq -r .commands[$i].options ${json_file})
  if [ "${options}" != "null" ] ; then
    op_len=$(echo "${options}" | jq length)
    for j in $(seq 0 $((${op_len} - 1))); do
      option=$(echo "${options}" | jq -r .[$j])
      options_op="$(echo ${options} | sed "s/yyyymm/${yyyymm}/g")"
    done
  else
    options_op=""
  fi

  ${command} -m ${yyyymm} ${options_op}
  result=$?
  if [ ${result} -ne 0 ] ; then
    exit ${result}
  fi
done

exit 0
