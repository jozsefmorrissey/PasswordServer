#!/bin/bash
mkdir ./info/
fullPath=$(readlink -f ${BASH_SOURCE[0]} | sed "s/\/installGlobal.sh//")/confidentalInfo.sh
echo "bash $fullPath \"\$@\"" > /usr/bin/confidentalInfo.sh
chmod +x /usr/bin/confidentalInfo.sh
