./confidentalInfo.sh help
appPort=$(./confidentalInfo.sh value confidentalInfo port)
dockerPort=9292
docker run -p $dockerPort:$appPort -ti pass/ub bash
