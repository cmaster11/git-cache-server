# git-cache-server

Simple `git` cache server, which clones on startup the repo provided in env var `GIT_MASTER_URL` and serves it on port `80`.

E.g. 
```
# Start the docker container locally
docker run --rm -it -p 8099:80 \
  --env GIT_MASTER_URL="https://github.com/cmaster11/git-cache-server" \
  git-cache-server:latest

# You can now clone the repo straight from the container
git clone http://localhost:8099/alpine-util.git
```

## Master-slave

This cache server is meant to be used in a clustered manner (e.g. k8s). If you provide a `GIT_SIBLING_URL` environment variable, the cache server will clone the repo provided at the sibling url in case the master one is not available. 

```
# ...
# Using the previously started container

# The slave container will clone first from the provided master url, and fall back on the sibling if not successful.
docker run --rm -it -p 8098:80 \
  --env GIT_MASTER_URL="https://github.com/cmaster11/git-cache-server" \
  --env GIT_SIBLING_URL="http://192.168.1.108:8099/git-cache-server.git" \
  git-cache-server:latest

# You can now clone the repo straight from the slave container
git clone http://localhost:8098/alpine-util.git
```

A use case for this behavior is when you want to replicate a `git` repo (e.g. hosting configurations) for faster access.

NOTE: the cache server does not have any self-updating logic, which means that you need to spawn a new cluster of cache servers for each update you trigger to the original `git` repository.