# git-cache-server

Simple `git` cache server, which clones on startup the repo provided in env var `GIT_MASTER_HOST` and `GIT_REPO_NAME` and serves it on port `80`.

E.g. 
```
# Start the docker container locally
docker run --rm -it -p 8099:80 \
  --env GIT_REPO_NAME="cmaster11/alpine-util" \
  --env GIT_MASTER_HOST="github.com" \
  "$IMAGE_NAME:$VERSION"

# You can now clone the repo straight from the container
git clone http://localhost:8099/alpine-util.git
```

## Master-slave

This cache server is meant to be used in a clustered manner (e.g. k8s). If you provide a `GIT_FALLBACK_HOST` environment variable, the cache server will clone the repo provided at the fallback url in case the master one is not available. 

```
# ...
# Using the previously started container

# The slave container will clone first from the provided master url, and fall back on GIT_FALLBACK_HOST if not successful.
docker run --rm -it -p 8098:80 \
  --network host \
  --env GIT_REPO_NAME="cmaster11/alpine-util" \
  --env GIT_MASTER_HOST="github.com" \
  --env GIT_FALLBACK_PROTOCOL=http \
  --env GIT_FALLBACK_HOST="localhost:8099" \
  "$IMAGE_NAME:$VERSION"

# You can now clone the repo straight from the slave container
git clone http://localhost:8098/alpine-util.git
```

A use case for this behavior is when you want to replicate a `git` repo (e.g. hosting configurations) for faster access.

NOTE: the cache server does not have any self-updating logic, which means that you need to spawn a new cluster of cache servers for each update you trigger to the original `git` repository.