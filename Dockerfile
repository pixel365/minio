# syntax=docker/dockerfile:1

ARG GO_VERSION=1.27
ARG UBI_VERSION=9.8
ARG MC_IMAGE=ghcr.io/pixel365/mc:RELEASE.2026-10-07T07-29-18Z

FROM ${MC_IMAGE} AS mc

# Cross-compile natively on the build platform; Go does not need emulation.
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build

ARG TARGETOS
ARG TARGETARCH
# Version metadata is computed on the host by buildscripts/gen-ldflags.go,
# because .git is not part of the build context.
ARG LDFLAGS="-s -w"

WORKDIR /src

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -trimpath -tags kqueue -ldflags "${LDFLAGS}" -o /out/minio .

# Static curl for container healthchecks, pinned and verified by checksum.
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS curl

ARG TARGETARCH
ARG CURL_VERSION=8.22.0
ARG CURL_SHA256_AMD64=dfb02460ba2abe513087538f12a3cf79b74b64a5ea3787ce8ac0cdb11251f884
ARG CURL_SHA256_ARM64=cf94cbeaae1b3c1944a4a761ef04478f8f0b23e93a324b5ed009b2082eda11f3

RUN set -eu; \
    case "${TARGETARCH}" in \
    amd64) arch=x86_64;  sum="${CURL_SHA256_AMD64}" ;; \
    arm64) arch=aarch64; sum="${CURL_SHA256_ARM64}" ;; \
    *) echo "static curl is not configured for ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    file="curl-linux-${arch}-musl-${CURL_VERSION}.tar.xz"; \
    wget -q -O "/tmp/${file}" "https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/${file}"; \
    echo "${sum}  /tmp/${file}" | sha256sum -c -; \
    mkdir -p /out; \
    tar -xJf "/tmp/${file}" -C /out curl

# ubi-micro ships without a CA bundle; it is architecture independent,
# so take it from ubi-minimal on the build platform.
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi9/ubi-minimal:${UBI_VERSION} AS certs

FROM registry.access.redhat.com/ubi9/ubi-micro:${UBI_VERSION}

ARG VERSION
ARG REVISION

LABEL name="MinIO" \
    version="${VERSION}" \
    release="${VERSION}" \
    summary="MinIO object storage server (fork of minio/minio)" \
    description="MinIO object storage server, built from https://github.com/pixel365/minio" \
    org.opencontainers.image.title="minio" \
    org.opencontainers.image.description="MinIO object storage server (fork of minio/minio)" \
    org.opencontainers.image.source="https://github.com/pixel365/minio" \
    org.opencontainers.image.licenses="AGPL-3.0-only" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.revision="${REVISION}"

# Upstream update endpoints (dl.min.io) are gone, so in-place updates of
# minio and the update check of mc are disabled.
ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_SECRET_KEY_FILE=kms_master_key \
    MINIO_CONFIG_ENV_FILE=config.env \
    MINIO_UPDATE=off \
    MC_UPDATE=off \
    MC_CONFIG_DIR=/tmp/.mc

COPY --from=certs /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/minio /usr/bin/minio
COPY --from=mc /usr/bin/mc /usr/bin/mc
COPY --from=curl /out/curl /usr/bin/curl
COPY CREDITS LICENSE /licenses/
COPY dockerscripts/docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

EXPOSE 9000
VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["minio"]
