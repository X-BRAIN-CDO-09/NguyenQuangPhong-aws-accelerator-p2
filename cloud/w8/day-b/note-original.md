# DAY2'S NOTES

## Docker

- Docker client (docker): Is just a command-line tool that allows you to interact with the Docker daemon.
- Docker daemon (dockerd): Is the background service that manages Docker containers.
- Docker image (docker image): Is a read-only template that contains the instructions for creating a Docker container.
- Docker container (docker container): Is a running instance of a Docker image.

### Beneath the daemon: containerd and runc

```
dockerd            ── API, build, network, volume (high level)
   │ gRPC
   ▼
containerd         ── pull images, manage storage, lifecycle
   │
   ▼
containerd-shim    ── stays behind to watch the container
   │ calls
   ▼
runc               ── builds namespaces + cgroups then EXITS (OCI)
   │
   ▼
[ process inside the container, e.g. nginx ]
```

- containerd-shim: Stays behind to watch the container and calls runc.
- MacOS and Windows has a lightweight Linux VM that runs the Docker daemon -> Docker on MacOS and Windows runs slower than on Linux.
- Restarting daemon doesn't kill containers because of the containerd-shim layer.
- The "cannot connect" error means the Docker daemon is not running or not accessible. (no permissions perhaps)

### What is a container?

- A container is a lightweight, standalone, executable package of software that includes everything needed to run an application: code, runtime, system tools, libraries, and settings.
- A container isn't a kind of virtual machine; it's a lightweight process that shares the host's kernel. It has its own filesystem, network, and process isolation.

Three things that created the isolation:
```
An ordinary process  ──────────►  A "container"
                          wrapped with:
┌───────────────────────────────────────────────┐
│  namespaces   → what it sees (proc, net, mnt) │
│  cgroups      → how much it can use (CPU, RAM)│
│  union FS     → which fs it sees (layers)     │
└───────────────────────────────────────────────┘
```

#### What is Namespace?
- A namespace is a Linux kernel feature that isolates processes from each other. It provides a way to isolate resources (filesystem, network, process) so that containers can run without affecting each other.

There are several types of namespaces:
- **PID namespace**: isolates process IDs.
- **Network namespace**: isolates network resources.
- **Mount namespace**: isolates filesystem mounts.
- **UTS namespace**: isolates hostname and domain name.
- **IPC namespace**: isolates inter-process communication resources.
- **User namespace**: isolates user and group IDs.

CMD to check:
```bash
docker run --rm nameOfContainer ls -l /proc/self/ns/
```

#### What is CGroups?
- A cgroup (short for control group) is a Linux kernel feature that isolates resources (CPU, memory, disk I/O, network) for a group of processes. It provides a way to limit and control the resources used by a group of processes.
- TLDR: A cgroup is a way to limit and control the resources used by a group of processes.

Limit a container to 50mb of RAM and then have it read its own limit:
```bash
docker run --rm --memory=50m nameOfContainer cat /sys/fs/cgroup/memory.max
```
Would probably returns something like:
```
52428800 (50 x 1024 x 1024 = 50 MB)
```
The `--memory=50m` flag limits the container to 50 MB of RAM. It is translated into a cgroup limit of 52428800 bytes (50 MB). Can also use `--cpus` to limit CPU usage, or `--cpu-shares` to limit CPU shares.

#### What is Union Filesystem?
- A union filesystem (or union mount) is a type of filesystem that allows multiple directories to be merged into a single virtual filesystem.
- TLDR: Where does the container get its filesystem (directories, files, commands) from? Union Filesystem, it stacks multiple layers (base image, container layer) on top of each other and combines them into a single virtual filesystem.

```
Running container
┌─────────────────────────────────────────┐
│  Writable layer (the container's own)     │  ← writes go here
├─────────────────────────────────────────┤
│  Layer 4 (read-only)  CMD/ENV...         │  ┐
│  Layer 3 (read-only)  copy code          │  │  the image's
│  Layer 2 (read-only)  install libs       │  │  layers
│  Layer 1 (read-only)  base OS (alpine...)│  ┘  (shared)
└─────────────────────────────────────────┘
     union mount → process sees 1 seamless file tree
```

Can check image's layer by:
```bash
docker pull nginx:alpine
docker image inspect nginx:alpine --format '{{range .RootFS.Layers}}{{println .}}{{end}}'
```

Runs
```bash
docker history nginx:alpine
```
Will returns something like:
```bash
CREATED BY                                      SIZE
RUN /bin/sh -c set -x  && apkArch="$(cat …      48.3MB
ENV ACME_VERSION=0.4.1                          0B
CMD ["nginx" "-g" "daemon off;"]                0B
EXPOSE map[80/tcp:{}]                           0B
```
Only `RUN` that installs software, which would create a heavy layer (48.3mb). Rest are just metadata or configuration changes.
