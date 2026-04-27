FROM debian:bookworm-slim AS base

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apt update -qy && \
    apt install -qy librocksdb-dev curl

FROM base as build

RUN apt install -qy git clang cmake

ENV RUSTUP_HOME=/rust
ENV CARGO_HOME=/cargo 
ENV PATH=/cargo/bin:/rust/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

WORKDIR /build
COPY . .

ARG CARGO_EXTRA_ARGS=""
RUN cargo build --release --bin electrs ${CARGO_EXTRA_ARGS}

FROM base as deploy

COPY --from=build /build/target/release/electrs /bin/electrs

EXPOSE 50001

ENTRYPOINT ["/bin/electrs"]