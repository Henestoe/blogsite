#!/usr/bin/env bash
set -Eeuo pipefail

image="${1:?Usage: sudo deploy.sh ghcr.io/henestoe/blogsite:5b76a897c0efeee095d9f6a3687c1cb1f567fc53}"

if (( EUID != 0 )); then
    echo "Run this script with sudo." >&2
    exit 1
fi

if [[ ! "$image" =~ ^ghcr\.io/henestoe/blogsite:[0-9a-f]{40}$ ]]; then
    echo "Use the blogsite image tagged with a full commit SHA." >&2
    exit 1
fi

exec 9>/run/lock/blogsite-deploy.lock
flock -n 9 || { echo "Another deployment is running." >&2; exit 1; }

docker inspect blogsite >/dev/null
if docker inspect blogsite-previous >/dev/null 2>&1; then
    echo "blogsite-previous already exists; inspect it before continuing." >&2
    exit 1
fi

docker pull "$image"

healthy() {
    for attempt in {1..10}; do
        if [[ "$(curl -s --max-time 2 -o /dev/null -w '%{http_code}' \
            -H 'Host: blog.hph-info.xyz' http://127.0.0.1:8000/)" == "200" ]]; then
            return 0
        fi
        sleep 2
    done
    return 1
}

rollback() {
    trap - ERR INT TERM HUP
    set +e
    echo "Deployment failed; attempting to restore the previous container." >&2
    docker logs --tail 30 blogsite 2>&1

    if docker inspect blogsite-previous >/dev/null 2>&1; then
        if docker inspect blogsite >/dev/null 2>&1; then
            docker rm -f blogsite >/dev/null || exit 1
        fi
        docker rename blogsite-previous blogsite || exit 1
    fi

    docker start blogsite >/dev/null || exit 1
    if healthy; then
        echo "Previous container restored." >&2
    else
        echo "Rollback health check failed; check docker logs blogsite." >&2
    fi
    exit 1
}

trap rollback ERR INT TERM HUP
docker stop blogsite >/dev/null
docker rename blogsite blogsite-previous

docker run -d \
    --name blogsite \
    --restart unless-stopped \
    -p 127.0.0.1:8000:8000 \
    --mount source=flaskr-data,target=/app/instance \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    "$image" >/dev/null

if ! healthy; then
    rollback
fi

trap - ERR INT TERM HUP
if ! docker rm blogsite-previous >/dev/null; then
    echo "The new container is healthy, but old-container cleanup failed." >&2
    exit 1
fi
echo "Deployment successful: $image"
