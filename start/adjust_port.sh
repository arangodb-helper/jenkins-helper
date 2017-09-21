if test $engine == "mmfiles"; then
  port=`expr $port + 1`
fi

if test $mode == "cluster"; then
  port=`expr $port + 2`
fi

if test $edition == "enterprise"; then
  port=`expr $port + 4`
fi

if test $auth == "auth"; then
  port=`expr $port + 8`
fi

export ARANGO_STORAGE_ENGINE=$engine
export ARANGO_MODE=$mode
export ARANGO_EDITION=$edition
export ARANGO_PORT=$port
export ARANGO_AUTH=$auth
