port=`./jenkins/start/port.sh`
trap "./jenkins/start/port.sh --clean $port" EXIT

echo "using port $port"

export ARANGO_STORAGE_ENGINE=$engine
export ARANGO_MODE=$mode
export ARANGO_EDITION=$edition
export ARANGO_PORT=$port
export ARANGO_AUTH=$auth
