port1=`./jenkins/start/port.sh`
trap "./jenkins/start/port.sh --clean $port1" EXIT

port2=`./jenkins/start/port.sh`
trap "./jenkins/start/port.sh --clean $port2" EXIT

port3=`./jenkins/start/port.sh`
trap "./jenkins/start/port.sh --clean $port3" EXIT

echo "using ports $port1, $port2, $port3"

export ARANGO_STORAGE_ENGINE=$engine
export ARANGO_MODE=$mode
export ARANGO_EDITION=$edition
export ARANGO_PORT=$port1
export ARANGO_PORTS=("$port1" "$port2" "$port3")
export ARANGO_AUTH=$auth

exit 0
