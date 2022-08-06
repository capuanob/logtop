# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git clang make libncursesw5-dev uthash-dev pkg-config

## Add source code to the build stage.
ADD . /logtop
WORKDIR logtop

## Build
RUN make all LIBFUZZ=1
RUN mv liblogtop.so /usr/lib && ldconfig
RUN clang -fsanitize=fuzzer fuzz/fuzz_logtop_feed.c -llogtop -o logtop-fuzz

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /logtop/logtop-fuzz /logtop-fuzz
COPY --from=builder /usr/lib/liblogtop.so /usr/lib

CMD /logtop-fuzz
