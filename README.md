[![GitHub issues](https://img.shields.io/github/issues/itzg/mc-router.svg)](https://github.com/itzg/mc-router/issues)
[![Docker Pulls](https://img.shields.io/docker/pulls/itzg/mc-router.svg)](https://cloud.docker.com/u/itzg/repository/docker/itzg/mc-router)
[![GitHub release](https://img.shields.io/github/release/itzg/mc-router.svg)](https://github.com/itzg/mc-router/releases)
[![CircleCI](https://circleci.com/gh/itzg/mc-router.svg?style=svg)](https://circleci.com/gh/itzg/mc-router)
[![Buy me a coffee](https://img.shields.io/badge/Donate-Buy%20me%20a%20coffee-orange.svg)](https://www.buymeacoffee.com/itzg)

Routes Minecraft client connections to backend servers based upon the requested server address.

# Usage

```text
Flags:
  --help                     Show context-sensitive help (also try --help-long
                             and --help-man).
  --port=25565               The port bound to listen for Minecraft client
                             connections
  --api-binding=API-BINDING  The host:port bound for servicing API requests
  --mapping=MAPPING,MAPPING  Where MAPPING is externalHostname=host:port
```

# REST API

* `GET /routes`
   Retrieves the currently configured routes
* `POST /routes`
   Registers a route given a JSON body structured like:
```json
{
  "serverAddress": "CLIENT REQUESTED SERVER ADDRESS",
  "backend": "HOST:PORT"
}
```
* `POST /defaultRoute`
  Registers a default route to the given backend. JSON body is structured as:
```json
{
  "backend": "HOST:PORT"
}
```
* `DELETE /routes/{serverAddress}`
  Deletes an existing route for the given `serverAddress`
  
# Docker Compose Usage

The following diagram shows how [the example docker-compose.yml](docs/docker-compose.yml)
configures two Minecraft server services named `vanilla` and `forge`, which also become the internal
network aliases. _Notice those services don't need their ports exposed since the internal
networking allows for the inter-container access._

The `router` service is only one of the services that needs to exposed on the external 
network. The `--mapping` declares how the hostname users will enter into their Minecraft client
will map to the internal services.

![](docs/compose-diagram.png)
  
To test out this example, I added these two entries to my "hosts" file:

```
127.0.0.1 vanilla.example.com
127.0.0.1 forge.example.com
```
  
# Kubernetes Usage

## Using kubernetes service auto-discovery

When running `mc-router` as a kubernetes pod and you pass the `--in-kube-cluster` command-line argument, then
it will automatically watch for any services annotated with 
- `mc-router.itzg.me/externalServerName` : The value of the annotation will be registered as the external hostname Minecraft clients would used to connect to the
   routed service. The service's clusterIP and target port are used as the routed backend.
- `mc-router.itzg.me/defaultServer` : The service's clusterIP and target port are used as the default if
  no other `externalServiceName` annotations applies.

For example, start `mc-router`'s container spec with

```yaml
image: itzg/mc-router
name: mc-router
args: ["--in-kube-cluster"]
```

and configure the backend minecraft server's service with the annotation:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mc-forge
  annotations:
    "mc-router.itzg.me/externalServerName": "external.host.name"
```

## Example kubernetes deployment

[This example deployment](docs/k8s-example-auto.yaml) 
* Declares an `mc-router` service that exposes a node port 25565
* Declares a service account with access to watch and list services
* Declares `--in-kube-cluster` in the `mc-router` container arguments
* Two "backend" Minecraft servers are declared each with an 
  `"mc-router.itzg.me/externalServerName"` annotation that declares their external server name

```bash
kubectl apply -f https://raw.githubusercontent.com/itzg/mc-router/master/docs/k8s-example-auto.yaml
```

![](docs/example-deployment-auto.drawio.png)

#### Notes
* This deployment assumes two persistent volume claims: `mc-stable` and `mc-snapshot`
* I extended the allowed node port range by adding `--service-node-port-range=25000-32767` 
  to `/etc/kubernetes/manifests/kube-apiserver.yaml` 

# Development

## Building locally with Docker

```bash
docker run -it --rm \
  -v gopkg:/go/pkg \
  -v ${PWD}:/build -w /build \
  golang:1.12 \
  go build ./cmd/mc-router
```

## Performing snapshot release with Docker

```bash
docker run -it --rm \
  -v ${PWD}:/build -w /build \
  -v /var/run/docker.sock:/var/run/docker.sock \
  goreleaser/goreleaser \
  release --snapshot --rm-dist
```