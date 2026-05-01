# Test environment for yterminal install scripts.
#
# Builds an Ubuntu 24.04 image with just enough baseline (sudo, tzdata,
# locales, ca-certificates) for ./install.sh to run cleanly. The repo itself
# is bind-mounted at runtime so edits on the host take effect immediately —
# no rebuild needed when iterating on scripts/.
#
# Usage:
#   ./test/run.sh                 # build + run + drop into interactive shell
#
# Or by hand:
#   docker build -t yterminal-test test/
#   docker run -d --name yterminal-test -v "$PWD":/work -w /work yterminal-test
#   docker exec -it yterminal-test bash
#   ./install.sh

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends \
        sudo \
        tzdata \
        locales \
        ca-certificates \
 && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

# Repo is mounted here at runtime; install.sh runs from /work.
WORKDIR /work

# Default command keeps the container alive so `docker exec -it` can attach.
CMD ["sleep", "infinity"]
