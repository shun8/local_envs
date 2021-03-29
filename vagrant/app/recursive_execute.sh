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

function send_error_mail {
  local mail_config=$1
  local error_text=$2
  local from=$(echo "${mail_config}" | jq -r ".from")
  local subject=$(echo "${mail_config}" | jq -r ".subject" | sed "s/yyyymm/${yyyymm}/g")
  local text=$(echo "${mail_config}" | jq -r ".text" | sed "s/yyyymm/${yyyymm}/g")"\n"${error_text}
  list=$(echo "${mail_config}" |jq ".to")
  len=$(echo "${list}" | jq length)
  for i in $( seq 0 $(($len - 1)) ); do
    local to=$(echo "${list}" | jq -r .[$i])
    aws ses send-email --to "${to}" --from "${from}" --subject "${subject}" --text "$(echo -e "${text}")"
    local result=$?
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

log_file=$(jq -r .log ${json_file})
log_file=$(cd $(dirname ${log_file}) && pwd)/$(basename ${log_file})

len=$(jq ".commands | length" ${json_file})
for i in $(seq 0 $(($len - 1))); do
  command=$(jq -r .commands[$i].command ${json_file})
  options=$(jq -r .commands[$i].options ${json_file})
  if [ "${options}" != "null" ] ; then
    op_len=$(echo "${options}" | jq length)
    for j in $(seq 0 $((${op_len} - 1))); do
      option=$(echo "${options}" | jq -r .[$j])
      options_op="$(echo "${options_op} ${option}" | sed "s/yyyymm/${yyyymm}/g")"
    done
  else
    options_op=""
  fi

  echo "$(date '+%Y-%m-%dT%H:%M:%S') START :  ${command} -m ${yyyymm} ${options_op}" >> "${log_file}"
  ${command} -m ${yyyymm} ${options_op} >> ${log_file} 2>&1
  result=$?
  if [ ${result} -ne 0 ] ; then
    echo "$(date '+%Y-%m-%dT%H:%M:%S') ERROR :  ${command} -m ${yyyymm} ${options_op}" >> "${log_file}"
    mail_config="$(jq -r .mail ${json_file})"
    send_error_mail "${mail_config}" "ERROR :  ${command} -m ${yyyymm} ${options_op}"
    exit ${result}
  fi
  echo "$(date '+%Y-%m-%dT%H:%M:%S') FINISH:  ${command} -m ${yyyymm} ${options_op}" >> "${log_file}"
done

exit 0
