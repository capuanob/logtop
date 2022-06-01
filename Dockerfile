# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git clang make libncursesw5-dev uthash-dev pkg-config

## Add source code to the build stage.
WORKDIR /
ADD https://api.github.com/repos/capuanob/logtop/git/refs/heads/mayhem version.json
RUN git clone -b mayhem https://github.com/capuanob/logtop.git
WORKDIR logtop

## Build
RUN make all LIBFUZZ=1
RUN mv liblogtop.so /usr/lib && ldconfig
RUN clang -fsanitize=fuzzer fuzz/fuzz.c -llogtop -o logtop-fuzz

## Consolidate all dynamic libraries used by the fuzzer
RUN mkdir /deps
RUN cp `ldd /logtop/logtop-fuzz | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
COPY --from=builder /logtop/logtop-fuzz /logtop-fuzz
COPY --from=builder /deps /usr/lib

CMD /logtop-fuzz -close_fd_mask=2
