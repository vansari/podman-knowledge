# podman knowledge

Here I have created a little repository with an example how it is possible to use podman for development.

Please read and learn usage of podman before you try to use this example.

### shortcuts

- Build php tools and fpm container
```shell
make build
```

- start pod and services
- each service checks the pod before and start one if not exists
```shell
make start[-fpm, -nginx, -pg]
```

- stop services
```shell
make stop[-fpm, -nginx, -pg]
```

- start/stop the pod only
```shell
make check-pod
```
```shell
make stop-pod
```
- execute some code in the pod universe
```shell
pod-console php -v
```
```shell
pod-console composer show
```