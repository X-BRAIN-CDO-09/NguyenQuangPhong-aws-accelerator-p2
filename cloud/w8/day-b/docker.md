# Docker running instructions


> Instead of having to write `sudo` before every `docker` command, you can run it as a regular user by adding your user to the `docker` group. Using the command `sudo usermod -aG docker $USER` then log back in to apply the changes.

```bash
docker run hello-world
```

Runs an nginx web server:
```bash
docker run -d --name web -p 8080:80 nginx:alpine
```
FLAGS:
- `-d`: Run in detached mode (background)
- `--name web`: Assign a name to the container
- `-p 8080:80`: Map port 8080 on the host to port 80 in the container

> `stop` is not `rm`. `stop` will stop the container, while `rm` will remove it.

USEFUL cmds:
```bash
docker ps -a
docker start <container_name>
docker restart <container_name>
docker stop <container_name>
docker rm <container_name>
docker logs -f web
```
Adding `--rm` tag to `docker run` will automatically remove the container when it stops.
```bash
docker run --rm -d --name tmp -p 8081:80 nginx:alpine
```

CLEANUP:
```bash
docker rm -f web tmp 2>/dev/null
```
REMOVE PULLED IMAGES:
```bash
docker rmi <image_name>
```

[dockerImage](dockerImage.md)
