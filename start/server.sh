if [ -z "$ARANGO_AUTH" ]; then
    ARANGO_AUTH="auth"
fi

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
docker pull c1.triagens-gmbh.zz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:devel

if [ "$ARANGO_MODE" == "cluster" ]; then
    if [ "ARANGO_AUTH" == "auth" ]; then
        JWTFILE="jwtsecret.$$"
        rm -f $JWTFILE

        echo "geheim" > $JWTFILE

        docker run \
            --name=$ARANGO_DOCKER_NAME \
            -d \
            -v $JWTFILE:/jwtsecret:ro \
            -p $ARANGO_PORT:8529 \
            -e ARANGO_ROOT_PASSWORD=$ARANGO_ROOT_PASSWORD \
            c1.triagens-gmbh.zz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:devel \
            arangodb --starter.local --server.storage-engine $ARANGO_STORAGE_ENGINE --starter.data-dir testrun

        rm -f $JWTFILE
    else
        docker run \
            --name=$ARANGO_DOCKER_NAME \
            -d \
            -p $ARANGO_PORT:8529 \
            c1.triagens-gmbh.zz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:devel \
            arangodb --starter.local --server.storage-engine $ARANGO_STORAGE_ENGINE --starter.data-dir testrun
    fi
elif [ "$ARANGO_MODE" == "singleserver" ]; then
    if [ "ARANGO_AUTH" == "auth" ]; then
        docker run \
            --name=$ARANGO_DOCKER_NAME \
            -d \
            -p $ARANGO_PORT:8529 \
            -e ARANGO_ROOT_PASSWORD=$ARANGO_ROOT_PASSWORD \
            -e ARANGO_STORAGE_ENGINE=$ARANGO_STORAGE_ENGINE \
            c1.triagens-gmbh.zz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:devel
    else
        docker run \
            --name=$ARANGO_DOCKER_NAME \
            -d \
            -p $ARANGO_PORT:8529 \
            -e ARANGO_NO_PASSWORD=1 \
            -e ARANGO_STORAGE_ENGINE=$ARANGO_STORAGE_ENGINE \
            c1.triagens-gmbh.zz:5000/arangodb/linux-${ARANGO_EDITION}-maintainer:devel
    fi
else
    echo "unknown mode $ARANGO_MODE"
    exit 1
fi

trap "docker rm -fv $ARANGO_DOCKER_NAME" EXIT

echo "Waiting until ArangoDB is ready on port $ARANGO_PORT"

count=0
while [ "$count" -lt 120 -a -z "`curl -uroot:$ARANGO_ROOT_PASSWORD -s http://127.0.0.1:$ARANGO_PORT/_api/version || true`" ]; do
  count=`expr $count + 1`
  echo "waiting ($count)..."
  sleep 2s
done

if [ $count -ge 120 ]; then
    echo "ArangoDB did not start"
    exit 1
fi

echo "ArangoDB is up"
