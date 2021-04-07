FROM debian:buster AS builder

ENV PATH="$PATH:/usr/local/go/bin:~/go/bin$:~/.cargo/bin"
ENV GO_VER="1.16.2"
ENV GO_ARCH="linux-amd64"
ENV RUSTUP_VER=1.51.0

COPY src /src/inter-hub

RUN apt-get update && \
    apt-get install -y git build-essential wget curl libssl-dev pkg-config

RUN cd /tmp  && \
    wget https://golang.org/dl/go${GO_VER}.${GO_ARCH}.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go${GO_VER}.${GO_ARCH}.tar.gz

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/run  && \
    sh /tmp/run -y --default-toolchain $RUSTUP_VER

RUN cd /src/minter-hub/chain && make install && \
    cd /src/minter-hub/minter-connector && make install && \
    cd /src/minter-hub/oracle && make install

RUN cd /src/minter-hub/orchestrator && \
    /root/.cargo/bin/cargo install --locked --path orchestrator && \
    /root/.cargo/bin/cargo install --locked --path register_delegate_keys

FROM debian:buster-slim
LABEL project="hub-minter"
LABEL GO_VERSION=$GO_VER
LABEL GO_ARCH=$GO_ARCH
LABEL RUSTUP_VERSION=$RUSTUP_VER

RUN apt-get update && apt-get install libssl1.1
COPY --from=builder /root/go/bin /usr/local/bin
COPY --from=builder /root/.cargo/bin/orchestrator /usr/local/bin
COPY --from=builder /root/.cargo/bin/register-peggy-delegate-keys /usr/local/bin
