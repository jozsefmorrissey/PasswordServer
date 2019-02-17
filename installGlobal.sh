#!/bin/bash
dataHome=~/.opsc/PasswordServer/
mkdir -p $dataHome/info/
mkdir -p $dataHome/na/
mkdir -p $dataHome/sd/
chmod $dataHome/info/
chmod 777 $dataHome/na/
chmod 777 $dataHome/sd/

fullPath=$(readlink -f ${BASH_SOURCE[0]} | sed "s/\/installGlobal.sh//")/confidentalInfo.sh
echo "bash $fullPath \"\$@\"" > /usr/bin/confidentalInfo.sh
chmod +x /usr/bin/confidentalInfo.sh
