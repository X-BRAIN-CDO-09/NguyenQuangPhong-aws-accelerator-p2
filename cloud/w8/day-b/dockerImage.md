# Docker Image

```
[registry/][namespace/]repository[:tag]

   docker.io / library /  nginx     : alpine
   └────┬───┘ └───┬───┘  └──┬──┘     └──┬──┘
     registry  namespace   name       tag
    (default)  (default)
```

When type `nginx:alpine` -> `docker.io/library/nginx:alpine`
- `docker.io` is the default registry (Docker Hub)
- `library` is where official Docker images are stored (by publishers published)
- `nginx:alpine` is the image name, `alpine` is the tag
- `latest` is the default tag if no tag is specified

When type `docker run` -> Pulls automatically from the registry if not present locally. But can also pull explicitly by running `docker pull python:3.12-alpine`


```bash
docker images
```
Docker images will list all locally available images.
> Definition: images are read-only templates used to create containers.

## Build Cache
- Why 2nd run is faster? 
> Docker caches each layer of the image. On a rebuild, Docker only needs to rebuild the layers that have changed.
- The cache cascades down
> When a layer is rebuilt, All layers after that layer must run again. (If layer1 is rebuilt, layer2 and layer3 must run again)


In our case, `RUN npm install` is still cached though we edited the code, because it sits before `COPY . .` and its input (package.json) has not changed.
```bash
Dockerfile              build after changing server.js
─────────────────────────────────────────────────
FROM node:20-alpine     ✓ CACHED
WORKDIR /app            ✓ CACHED
COPY package.json ./    ✓ CACHED   (package.json unchanged)
RUN npm install         ✓ CACHED   ← NOT reinstalled, big saving
COPY . .                ✗ rebuild  ← server.js changed, rebuilds from here
CMD ["npm","start"]     ✗ rebuild
```

We can also use `.dockerignore` to exclude files from the build context, so Docker doesn't need to copy them. Things like:
```
node_modules
npm-debug.log
.git
.env
```

CLEANUP:
```bash
docker rmi demo:v1
docker builder prune     # remove old build cache to reclaim disk
```
