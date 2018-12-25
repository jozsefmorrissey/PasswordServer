#!/bin/bash

# All functions will deal with the same following properties
#   @$1 - String Id
#   @$2 - Property Key

source ./debugLogger.sh

if  touch /usr/test.txt 2>/dev/null; then
    rm /usr/test.txt
else
  echo Must have admin privaliges to run this application.
  exit;
fi

password="amu0ohMihohQuoh3AuYo1aihiet9ei"
relDir=$(echo "${BASH_SOURCE[0]}" | sed "s/confidentalInfo.sh//g")
infoDir=${relDir}info/
tempName="thahb9da7aegahpaic3ohKahchoube"
tempExt='.txt'
encryptExt='.des3'
logId="log-history-unlikely-user-name"
defaultPort=8080

log() {
  halfPart=$(echo -n -e "------------------------- ")
  oHalfPart=$(echo -n -e $halfPart | rev)
  d=$(date +%F_%H-%M-%S)
  lg=$(echo -n -e "\n\n$d\n$halfPart $1:$2:$3 $oHalfPart\n$4")
  appendToFile "$logId" "$lg"
}

getFileName() {
  if [ $1 == 'infoMap' ]
  then
    file='Heena6airooshahze8eeh2fohruu4c';
  else
    file=$(getValue infoMap $1)
  fi

  if [ "$file" ]
  then
    echo $infoDir$file
  fi
}

getTempName () {
  echo $(getFileName $1)$tempExt
}

getEncryptName() {
  echo $(getFileName $1)$encryptExt
}

getValue() {
  decoded=$(decode "$1")
  value=$(echo "$decoded" | grep -oP "$2=.*" | sed "s/.*=//g")
  if [ "$2" == "token" ]
  then
    updateTokens=$(getValue $1 updateTokens)
    if [ "$updateTokens" == "true" ] || [ -z "$value" ]
    then
      update "$1" token
      decoded=$(decode "$1")
      value=$(echo "$decoded" | grep -oP "$2=.*" | sed "s/.*=//g")
    fi
  fi

  if [ ! -z "$value" ]
  then
    echo $value
  fi
}

decode() {
  encryptName=$(getEncryptName $1)
  if [ -f "$encryptName" ];
  then
    cmd="openssl des3 -d < $encryptName -pass pass:$password"
    # Unlock -> decrypt -> Lock.... TODO: Find a way to simplify this.
    decoded=$(sudo chmod +r $encryptName && openssl des3 -d < $encryptName -pass pass:$password && sudo chmod -r $encryptName)
    echo "$decoded"
  else
    echo "";
  fi
}

setupTemp() {
  tempName=$(getTempName $1)
  encryptName=$(getEncryptName $1)
  touch $tempName
  touch $encryptName
  echo "$(decode $1)" > $tempName
}

mapFile() {
  getValue infoMap "$1"
  filename=$(getValue infoMap "$1")
  if [[ -z $filename ]] && [ $1 != "infoMap" ]
  then
    genValue=$(pwgen 30 1)
    filename="$genValue"
    touch $infoDir$filename$encryptExt
    appendToFile "infoMap" "$1=$filename"
  fi

  echo $filename
}

saveAndRemoveTemp () {
  tempName=$(getTempName $1)
  encryptName=$(getEncryptName $1)
  # Unlock -> encrypt -> Lock.... TODO: Find a way to simplify this.
  sudo chmod +rw $encryptName && openssl des3 < $tempName > $encryptName -pass pass:$password && sudo chmod -rw $encryptName
  rm $tempName
}

viewFile() {
  filename=$(mapFile "$1")
  temporaryName=$(getTempName "$1")
  setupTemp "$1"
  oldContents=$(cat $temporaryName)
  editor=gedit
  $(eval "$editor $temporaryName")
}

appendToFile () {
  tempFileName=$(getTempName "$1")
  filename=$(mapFile "$1")
  setupTemp "$1"
  echo "$2" >> $tempFileName
  saveAndRemoveTemp $1
}

update () {
  if [ ! -z "$2" ]
  then
    silence=$(mapFile "$1")
    tempFileName=$(getTempName "$1")

    setupTemp "$1"
    sed -i "s/$2=.*//g" $tempFileName
    log "$1" "$2" "$old" "Updated"
    saveAndRemoveTemp $1

    newVal=$3
    if [ -z "$newVal" ]
    then
      newVal=$(pwgen 30 1)
    fi

    appendToFile "$1" "$2=$newVal"
  fi
}

replace() {
  value=$(getValue $1 $2)
  sed -i -re "s/_\{$2\}_/$value/g" $3
}

remove() {
  value=$(getValue $1 $2)
  sed -i -re "s/$value/_{$2}_/g" $3
}

determinePort() {
  numRe='^[0-9]{1,}$'
  if [[ $1 =~ $numRe ]]; then
    port=$1
  else
    savedPort=$(getValue confidentalInfo port)
    if [[ $savedPort =~ $numRe ]]; then
      port=$savedPort
    else
      port=$defaultPort
    fi
  fi
  update confidentalInfo port $port 1>/dev/null
  echo $port
}

getWithToken() {
  token=$(getValue $1 token)
  if [ "$token" == "$3" ];then
    value=$(getValue $1 $2)
    # password=$(getValue $1 passSalt)
    # encrypted=$(${relDir}jasypt-1.9.2/bin/encrypt.sh algorithm=PBEWithMD5AndDES input="$input" password="$password" |
    #   tr "\n" " " |
    #   sed "s/\(\(.*----OUTPUT----\)\|\([- \t]\)\)//g")
    echo $value
  else
    echo Your not supposed to be here...
  fi
}

getServerPid() {
  sudo netstat -plten | grep $1 | awk '{print $9}' | sed "s/\(.*\)\/.*/\1/"
}

startServer() {
  port=$(determinePort $1)
  serverPid=$(getServerPid $port)
  confInfoToken=$(getValue confidentalInfo token)
  if [ -z $serverPid ]; then
    node ${relDir}password-server.js $port $confInfoToken 1>/dev/null &
    echo Password server running on port: $port
  fi
}

declare -A cmdHelp
declare -A moreDetail

openHelpDoc() {
  port=$(determinePort $2)
  serverPid=$(getServerPid $port)
  startServer
  url="xdg-open http://localhost:$port/help.html";
  echo -e "URL:\n\t"$url"\n"
  su jozsef -c "$url"
}

case "$1" in
  replace)
    replace $2 $3 $4
  ;;
  remove)
    remove $2 $3 $4
  ;;
  edit)
    oldContents=$(viewFile "$2")
    log $2 "" "" "$oldContents"
    saveAndRemoveTemp "$2"
  ;;
  value)
    getValue "$2" "$3"
  ;;
  append)
    appendToFile "$2" "$3"
  ;;
  update)
    update "$2" "$3" "$4"
  ;;
  map)
    mapFile "$2"
  ;;
  view)
    viewFile "$2"
  ;;
  --help)
    openHelpDoc "$2"
  ;;
  -help)
    openHelpDoc "$2"
  ;;
  help)
    openHelpDoc "$2"
  ;;
  log)
    $oldContents=$(viewFile "$logId")
    saveAndRemoveTemp "$logId"
  ;;
  start-server)
    startServer $2
  ;;
  stop-server)
    port=$(determinePort $2)
    sudo kill -9 $(getServerPid $port)
  ;;
  setup-server)
    update "$2" "$3" "$4"
    update "$2" "token"
  ;;
  getWithToken)
    getWithToken "$2" "$3" "$4"
  ;;
  defaultPort)
    echo $defaultPort
  ;;
esac
