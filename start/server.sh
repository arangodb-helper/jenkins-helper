if [ -z "$ARANGO_AUTH" ]; then ARANGO_AUTH="auth"; fi
if [ -z "$ARANGO_BRANCH" ]; then ARANGO_BRANCH="devel"; fi

for name in ARANGO_DOCKER_NAME ARANGO_PORT ARANGO_MODE ARANGO_STORAGE_ENGINE ARANGO_EDITION ARANGO_AUTH; do
    if [ -z "${!name}" ]; then
        echo "$name missing"
        exit 1
    fi
done

echo "NAME: $ARANGO_DOCKER_NAME"
echo "PORT: $ARANGO_PORT"
echo "MODE: $ARANGO_MODE"
echo "ENGINE: $ARANGO_STORAGE_ENGINE"
echo "AUTH: $ARANGO_AUTH"
echo "EDITION: $ARANGO_EDITION"
echo

docker kill $ARANGO_DOCKER_NAME > /dev/null 2>&1 || true
docker rm -fv $ARANGO_DOCKER_NAME > /dev/null 2>&1 || true
docker pull registry.arangodb.biz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:$ARANGO_BRANCH
docker run registry.arangodb.biz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:$ARANGO_BRANCH arangosh --version

OUTDIR="`pwd`/output"
rm -rf $OUTDIR
mkdir $OUTDIR
DOCKER_AUTH=""
STARTER_AUTH=""
DOCKER_CMD="docker run --name $ARANGO_DOCKER_NAME -d -p $ARANGO_PORT:8529 -v $OUTDIR:/testrun"
DOCKER_IMAGE="registry.arangodb.biz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:$ARANGO_BRANCH"
STARTER_CMD="arangodb --starter.local --server.storage-engine $ARANGO_STORAGE_ENGINE --starter.data-dir /testrun"
STARTER_MODE=""

if [ "$ARANGO_AUTH" == "auth" ]; then
  JWTDIR="`pwd`/jwtsecret.$$"
  rm -rf $JWTDIR
  mkdir $JWTDIR
  echo "geheim" > $JWTDIR/geheim
  DOCKER_AUTH="-v $JWTDIR:/jwtsecret -e ARANGO_ROOT_PASSWORD=$ARANGO_ROOT_PASSWORD -e ARANGODB_DEFAULT_ROOT_PASSWORD=$ARANGO_ROOT_PASSWORD"
  STARTER_AUTH="--auth.jwt-secret /jwtsecret/geheim" 
fi

if [ "$ARANGO_MODE" == "cluster" ]; then
  STARTER_MODE="--starter.mode cluster" 
elif [ "$ARANGO_MODE" == "singleserver" ]; then
  STARTER_MODE="--starter.mode single" 
else
    echo "unknown mode $ARANGO_MODE"
    exit 1
fi

echo "Starting the container with the following command:"
command="$DOCKER_CMD $DOCKER_AUTH $DOCKER_IMAGE $STARTER_CMD $STARTER_MODE $STARTER_AUTH"
echo $command
$command

if [ "$ARANGO_AUTH" == "auth" ]; then
  rm -rf $JWTDIR
fi

trap "docker rm -fv $ARANGO_DOCKER_NAME" EXIT

echo "Waiting until ArangoDB is ready on port $ARANGO_PORT"

if [ "$ARANGO_AUTH" == "auth" ]; then
    CURL_USER="-uroot:$ARANGO_ROOT_PASSWORD"
else
    CURL_USER=""
fi

count=0
while [ "$count" -lt 120 ]; do
  responseCode=`curl -s -I $CURL_USER http://127.0.0.1:$ARANGO_PORT/_api/version | head -n 1 | cut -d$' ' -f2`
  if [ -n "${responseCode}" ];
  then
    if [ $responseCode -eq 200 ];
    then
          echo "We are finally ready and authenticated."
          break
    fi
  fi

  count=`expr $count + 1`
  echo "waiting ($count)..."
  sleep 2s
done

if [ $count -ge 120 ]; then
    echo "docker logs:"
    docker logs $ARANGO_DOCKER_NAME

    echo
    echo "curl:"
    curl $CURL_USER -v http://127.0.0.1:$ARANGO_PORT/_api/version

    echo "ArangoDB did not start"
    exit 1
fi

echo "ArangoDB is up"
