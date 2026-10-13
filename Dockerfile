# BankLite lab image: the BankLite target system plus every tool used in the labs.
# All tools are free and open source; versions are pinned so results are repeatable.

FROM golang:1.26.9-trixie AS theia
ARG THEIA_COMMIT=445206c522c6b1621f8326f1f05bc79e195a28e2
RUN git clone https://github.com/cbomkit/cbomkit-theia /src \
 && cd /src && git checkout ${THEIA_COMMIT} \
 && CGO_ENABLED=0 go build -o /out/cbomkit-theia .

FROM debian:trixie-slim
ARG CDXGEN_VERSION=12.8.5
ARG CYCLONEDX_CLI_VERSION=v0.33.1
ENV DEBIAN_FRONTEND=noninteractive \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

RUN apt-get update && apt-get install -y --no-install-recommends \
      openssl nodejs npm testssl.sh jq ca-certificates curl git procps \
      bsdextrautils dnsutils python3 nano vim-tiny \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g @cyclonedx/cdxgen@${CDXGEN_VERSION} && npm cache clean --force
RUN curl -fsSL -o /usr/local/bin/cyclonedx \
      https://github.com/CycloneDX/cyclonedx-cli/releases/download/${CYCLONEDX_CLI_VERSION}/cyclonedx-linux-x64 \
 && chmod +x /usr/local/bin/cyclonedx
COPY --from=theia /out/cbomkit-theia /usr/local/bin/cbomkit-theia

# Target system. Keys are made world-readable so the scanners can read them as a normal user.
COPY banklite /banklite
RUN sh /banklite/scripts/gen-material.sh && chmod -R a+rX /banklite

# Lab files. The answer key is inside the image so the facilitator can score offline.
COPY lab /lab
COPY worksheet /lab/worksheet
COPY facilitator /lab/facilitator
COPY answer-key /lab/answer-key
COPY solutions /lab/solutions
RUN useradd -m -u 1000 lab && mkdir -p /lab/out && chown lab:lab /lab/out

USER lab
WORKDIR /lab
EXPOSE 8443 8444
ENTRYPOINT ["/lab/start.sh"]
CMD ["bash"]
