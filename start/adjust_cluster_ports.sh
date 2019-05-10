port1=`./jenkins/start/port.sh`
port2=`./jenkins/start/port.sh`
port3=`./jenkins/start/port.sh`

echo "using ports $port1, $port2, $port3"

clean_ports () {
  [ ! -z "$port1" ] && ./jenkins/start/port.sh --clean $port1
  [ ! -z "$port2" ] && ./jenkins/start/port.sh --clean $port2
  [ ! -z "$port3" ] && ./jenkins/start/port.sh --clean $port3
}

trap clean_ports EXIT

export ARANGO_STORAGE_ENGINE=$engine
export ARANGO_MODE=$mode
export ARANGO_EDITION=$edition
export ARANGO_PORT=$port1
export ARANGO_PORTS=("$port1" "$port2" "$port3")
export ARANGO_AUTH=$auth
