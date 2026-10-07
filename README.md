# MinIO Quickstart Guide

[![license](https://img.shields.io/badge/license-AGPL%20V3-blue)](https://github.com/pixel365/minio/blob/master/LICENSE)

[![MinIO](https://raw.githubusercontent.com/pixel365/minio/master/.github/logo.svg?sanitize=true)](https://min.io)

MinIO is a high-performance, S3-compatible object storage solution released under the GNU AGPL v3.0 license.
Designed for speed and scalability, it powers AI/ML, analytics, and data-intensive workloads with industry-leading performance.

- S3 API Compatible – Seamless integration with existing S3 tools
- Built for AI & Analytics – Optimized for large-scale data pipelines
- High Performance – Ideal for demanding storage workloads.

This README provides instructions for building MinIO from source and deploying onto baremetal hardware.
Use the [MinIO Documentation](https://github.com/minio/docs) project to build and host a local copy of the documentation.

## MinIO is Open Source Software

We designed MinIO as Open Source software for the Open Source software community. We encourage the community to remix, redesign, and reshare MinIO under the terms of the AGPLv3 license.

All usage of MinIO in your application stack requires validation against AGPLv3 obligations, which include but are not limited to the release of modified code to the community from which you have benefited. Any commercial/proprietary usage of the AGPLv3 software, including repackaging or reselling services/features, is done at your own risk.

The AGPLv3 provides no obligation by any party to support, maintain, or warranty the original or any modified work.
All support is provided on a best-effort basis through Github and our [Slack](https://slack.min.io) channel, and any member of the community is welcome to contribute and assist others in their usage of the software.

MinIO [AIStor](https://www.min.io/product/aistor) includes enterprise-grade support and licensing for workloads which require commercial or proprietary usage and production-level SLA/SLO-backed support. For more information, [reach out for a quote](https://min.io/pricing).

## Source-Only Distribution

**Important:** The MinIO community edition is now distributed as source code only. We will no longer provide pre-compiled binary releases for the community version.

### Installing Latest MinIO Community Edition

To use MinIO community edition, you have two options:

1. **Install from source** using `go install github.com/minio/minio@latest` (recommended)
2. **Build a Docker image** from the provided Dockerfile

See the sections below for detailed instructions on each method.

### Legacy Binary Releases

Historical pre-compiled binary releases remain available for reference but are no longer maintained:

- GitHub Releases: https://github.com/minio/minio/releases
- Direct downloads: https://dl.min.io/server/minio/release/

**These legacy binaries will not receive updates.** We strongly recommend using source builds for access to the latest features, bug fixes, and security updates.

## Install from Source

Use the following commands to compile and run a standalone MinIO server from source.
If you do not have a working Golang environment, please follow [How to install Golang](https://golang.org/doc/install). Minimum version required is [go1.27](https://golang.org/dl/#stable)

```sh
go install github.com/minio/minio@latest
```

You can alternatively run `go build` and use the `GOOS` and `GOARCH` environment variables to control the OS and architecture target.
For example:

```
env GOOS=linux GOARCH=arm64 go build
```

Start MinIO by running `minio server PATH` where `PATH` is any empty folder on your local filesystem.

The MinIO deployment starts using default root credentials `minioadmin:minioadmin`.
You can test the deployment using the MinIO Console, an embedded web-based object browser built into MinIO Server.
Point a web browser running on the host machine to <http://127.0.0.1:9000> and log in with the root credentials.
You can use the Browser to create buckets, upload objects, and browse the contents of the MinIO server.

You can also connect using any S3-compatible tool, such as the MinIO Client `mc` commandline tool:

```sh
mc alias set local http://localhost:9000 minioadmin minioadmin
mc admin info local
```

See [Test using MinIO Client `mc`](#test-using-minio-client-mc) for more information on using the `mc` commandline tool.
For application developers, see <https://docs.min.io/enterprise/aistor-object-store/developers/sdk/> to view MinIO SDKs for supported languages.

> [!NOTE]
> Production environments using compiled-from-source MinIO binaries do so at their own risk.
> The AGPLv3 license provides no warranties nor liabilities for any such usage.

## Docker Image

Images are published to the GitHub Container Registry for `linux/amd64` and `linux/arm64`:

- `ghcr.io/pixel365/minio:latest` – the latest release
- `ghcr.io/pixel365/minio:RELEASE.<date>` – a specific release
- `ghcr.io/pixel365/minio:edge` – the latest `master` build

```sh
docker run -p 9000:9000 -p 9001:9001 ghcr.io/pixel365/minio server /data --console-address :9001
```

The image also contains the MinIO Client `mc` and `curl` for health checks, e.g. `mc ready local`.

## Build Docker Image

The `Dockerfile` builds MinIO from source, no prebuilt binary is required.
The following command builds the image for the host platform with version information taken from git and tags it as `ghcr.io/pixel365/minio:<version>`:

```sh
make docker
```

Use `TAG` to choose another image name, for example `make docker TAG=myminio:minio`.
A plain `docker build -t myminio:minio .` works as well, but the binary then carries no version information.

Use `docker image ls` to confirm the image exists in your local repository.
You can run the server using standard Docker invocation:

```sh
docker run -p 9000:9000 -p 9001:9001 myminio:minio server /tmp/minio --console-address :9001
```

Complete documentation for building Docker containers, managing custom images, or loading images into orchestration platforms is out of scope for this documentation.
You can modify the `Dockerfile` and `dockerscripts/docker-entrypoint.sh` as-needed to reflect your specific image requirements.

See the [MinIO Container](https://docs.min.io/community/minio-object-store/operations/deployments/baremetal-deploy-minio-as-a-container.html#deploy-minio-container) documentation for more guidance on running MinIO within a Container image.

## Install using Helm Charts

There are two paths for installing MinIO onto Kubernetes infrastructure:

- Use the [MinIO Operator](https://github.com/minio/operator)
- Use the community-maintained [Helm charts](https://github.com/pixel365/minio/tree/master/helm/minio)

See the [MinIO Documentation](https://docs.min.io/community/minio-object-store/operations/deployments/kubernetes.html) for guidance on deploying using the Operator.
The Community Helm chart has instructions in the folder-level README.

## Test MinIO Connectivity

### Test using MinIO Console

MinIO Server comes with an embedded web based object browser.
Point your web browser to <http://127.0.0.1:9000> to ensure your server has started successfully.

> [!NOTE]
> MinIO runs console on random port by default, if you wish to choose a specific port use `--console-address` to pick a specific interface and port.

### Test using MinIO Client `mc`

`mc` provides a modern alternative to UNIX commands like ls, cat, cp, mirror, diff etc. It supports filesystems and Amazon S3 compatible cloud storage services.

The following commands set a local alias, validate the server information, create a bucket, copy data to that bucket, and list the contents of the bucket.

```sh
mc alias set local http://localhost:9000 minioadmin minioadmin
mc admin info
mc mb data
mc cp ~/Downloads/mydata data/
mc ls data/
```

Follow the MinIO Client [Quickstart Guide](https://docs.min.io/community/minio-object-store/reference/minio-mc.html#quickstart) for further instructions.

## Explore Further

- [The MinIO documentation website](https://docs.min.io/community/minio-object-store/index.html)
- [MinIO Erasure Code Overview](https://docs.min.io/community/minio-object-store/operations/concepts/erasure-coding.html)
- [Use `mc` with MinIO Server](https://docs.min.io/community/minio-object-store/reference/minio-mc.html)
- [Use `minio-go` SDK with MinIO Server](https://docs.min.io/enterprise/aistor-object-store/developers/sdk/go/)

## Contribute to MinIO Project

Please follow MinIO [Contributor's Guide](https://github.com/pixel365/minio/blob/master/CONTRIBUTING.md) for guidance on making new contributions to the repository.

## License

- MinIO source is licensed under the [GNU AGPLv3](https://github.com/pixel365/minio/blob/master/LICENSE).
- MinIO [documentation](https://github.com/pixel365/minio/tree/master/docs) is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [License Compliance](https://github.com/pixel365/minio/blob/master/COMPLIANCE.md)
