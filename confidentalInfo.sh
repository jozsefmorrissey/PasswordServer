#!/bin/bash

# All functions will deal with the same following properties
#   @$1 - String Id
#   @$2 - Property Key
passServRelDir=$(dirname "${BASH_SOURCE[0]}")
source ${passServRelDir}/BashScripts/debugLogger.sh

infoDir=${passServRelDir}/info/
propFile=${passServRelDir}/passwordServer.properties
password=$(grep -oP "password=.*" $propFile | sed "s/.*=\(.*\)/\1/")
tempExt='.txt'
encryptExt='.des3'
logId="log-history-unlikely-user-name"
defaultPort=8080
mapFile=$(grep -oP "mapFile=.*" $propFile | sed "s/.*=\(.*\)/\1/")

log() {
  halfPart=$(echo -n -e "------------------------- ")
  oHalfPart=$(echo -n -e $halfPart | rev)
  d=$(date +%F_%H-%M-%S)
  lg=$(echo -n -e "\n\n$d\n$halfPart $1 $oHalfPart\n$2:$3\n$4")
  appendToFile "$logId" "$lg"
}

getFileName() {
  if [ $1 == 'infoMap' ]
  then
    file=$mapFile;
  else
    file=$(getValue infoMap $1)
  fi

  if [ "$file" ]
  then
    echo $infoDir$file
  fi
}

getTempName () {
  echo $passServRelDir/sd/$1'_temp'$tempExt
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

getNewFileName() {
  found=1
  newName=here
  while [ $found == 1 ]
  do
    found=0
    newName=$(pwgen 30 1)
    filenames=$(ls $passServRelDir/info/)
    for filename in $filenames
    do
      if [ "$newName$encryptExt" == "$filename" ]
      then
        found=1
      fi
    done
  done
  echo $newName
}

mapFile() {
  getValue infoMap "$1"
  filename=$(getValue infoMap "$1")
  if [[ -z $filename ]] && [ $1 != "infoMap" ]
  then
    genValue=$(getNewFileName)
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

cleanFile() {
  sed -i '/^[[:space:]]*$/d' $1
  sort $1 > ${1}_ && cp ${1}_ $1 && rm ${1}_
}

viewFile() {
  filename=$(mapFile "$1")
  temporaryName=$(getTempName "$1")
  setupTemp "$1"
  cleanFile "$temporaryName"
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
    old=$(grep -oP "$2=.*" $tempFileName | sed "s/.*=\(.*\)/\1/")
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
    echo $value
  else
    echo '[Error:CI] Your not supposed to be here...'
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
    node ${passServRelDir}/password-server.js $port $confInfoToken 1>/dev/null &
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

areYouSure() {
  echo -e "$1"
  read -p "" yes
  echo $yes
  if [ "$yes" != "YES" ]
  then
    exit
  fi
}

generateProperties() {
  areYouSure "Are you sure you want to regnerate Properties?(YES to proceed)\nAll Passwords will be lost."
  areYouSure "Seriosly there is no going back.... You have been warned?(YES to proceed)"
  rm $propFile
  pass=$(pwgen 30)
  mapFile=$(pwgen 30)
  echo -e "password=$pass\nmapFile=$mapFile" > $propFile
}

adminCheck() {
  if  touch /usr/test.txt 2>/dev/null; then
      rm /usr/test.txt
  else
    echo Must have admin privaliges to run this application.
    if [ "$1" != "true" ]
    then
      exit
    fi
  fi
}

selfDistruct() {
  t=60
  if [ ! -z $2 ]
  then
    t=$2
  fi
  filepath=$(getTempName "$1")
  setupTemp "$1"
  sleep $t && rm $filepath &
}

naFp() {
  echo $passServRelDir/na/$1.txt
}


toJson() {
  filepathNa=$(naFp "$1")
  properties=$(grep -oP "^.{1,}" $filepathNa)
  json="{\n"$(echo "$properties" | sed 's/\(.*\?\)=\(.*\)/\t\"\1\": "\2",/g')"\n"
  echo -e "${json:0:-3}\n}"

}

valueNonAdmin() {
  filepathSd=$(getTempName "$1")
  filepathNa=$(naFp "$1")
  valSd=$(grep -oP "^$2=.*" $filepathSd 2>/dev/null | sed "s/^$2=\(.*\)/\1/")
  valNa=$(grep -oP "^$2=.*" $filepathNa 2>/dev/null | sed "s/^$2=\(.*\)/\1/")
  [ ! -z $valSd ] && [ ! -z $valNa ] &&
    debug warn 'There is a secure and insecure Property with the same collection and identifier. One of these needs to be renamed'

  [ -z "$valSd" ] && [ -z "$valNa" ] && [ "${booleans[a]}" != "true" ] && adminCheck && getValue "$1" "$2" && exit
  # debug fatal "$valSd : $valNa" - $filepathNa
  [ ! -z "$valNa" ] && echo $valNa && debug info "Insecure value returned" && exit

  [ ! -z "$valSd" ] && echo $valSd && debug info "Secure value returned" && exit

  debug info "Property not found $1 - $2"
  echo "[Error:CI] Property '$2' not found. - You may need to run selfDistruct with admin privaliges before execution."
  exit
}

updateNonAdmin() {
  adminErr=$(adminCheck "true")
  if [ ! -z "$adminErr" ]
  then
    val=$3
    if [ -z $val ]
    then
      val=$(pwgen 30 1)
    fi
    filepath=$(naFp $1)
    mkdir -p $(dirname $filepath)
    sed -i "s/^$2=.*//" $filepath
    echo $2=$val >> $filepath
    cleanFile $filepath
    exit
  fi
}

insecureFunctions() {
  case "$1" in
    value)
      valueNonAdmin "$2" "$3"
    ;;
    update)
      updateNonAdmin "$2" "$3" "$4"
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
    getWithToken)
      getWithToken "$2" "$3" "$4"
    ;;
    retTemp)
      retTemp "$2" "$3"
    ;;
    toJson)
      toJson "$2"
    ;;
  esac
}

secureFunctions() {
  case "$1" in
    replace)
      adminCheck
      replace $2 $3 $4
    ;;
    remove)
      adminCheck
      remove $2 $3 $4
    ;;
    edit)
      adminCheck
      oldContents=$(viewFile "$2")
      log $2 "" "" "$oldContents"
      saveAndRemoveTemp "$2"
    ;;
    append)
      adminCheck
      appendToFile "$2" "$3"
    ;;
    update)
      adminCheck
      update "$2" "$3" "$4"
    ;;
    map)
      adminCheck
      mapFile "$2"
    ;;
    view)
      adminCheck
      viewFile "$2"
      temporaryName=$(getTempName "$1")
      rm "$temporaryName"
    ;;
    generateProperties)
      adminCheck
      generateProperties
    ;;
    setup-server)
      adminCheck
      update "$2" "$3" "$4"
      update "$2" "token"
    ;;
    log)
      adminCheck
      $oldContents=$(viewFile "$logId")
      saveAndRemoveTemp "$logId"
    ;;
    start-server)
      adminCheck
      startServer $2
    ;;
    stop-server)
      adminCheck
      port=$(determinePort $2)
      sudo kill -9 $(getServerPid $port)
    ;;
    defaultPort)
      adminCheck
      determinePort $2
    ;;
    selfDistruct)
      selfDistruct "$2" "$3"
    ;;
  esac
}

insecureFunctions "$@"
secureFunctions "$@"
