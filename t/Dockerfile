# DOCKER_NAME=ngcp-klish-config-bullseye
FROM docker.mgm.sipwise.com/sipwise-bullseye:latest

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2021-05-03

RUN apt-get update && \
    apt-get install --assume-yes \
             jq \
             lua-busted \
             lua-dbi-mysql \
             lua-socket \
             lua-yaml \
             lua5.2

RUN echo './t/testrunner' >>/root/.bash_history

WORKDIR /code/

################################################################################
# Instructions for usage
# ----------------------
# To build the base image from scratch (or jump to the next section if
# you do not want to build it yourself):
#
# % docker build --tag="ngcp-klish-config-bullseye" -f t/Dockerfile .
# % docker run --rm -i -t -v $(pwd):/code:rw ngcp-klish-config-bullseye:latest bash
#
# To use the existing docker image:
#
# % docker pull docker.mgm.sipwise.com/ngcp-klish-config-bullseye
# NOTE: run the following command from the root folder of the git repository:
# % docker run --rm -i -t -v $(pwd):/code:rw \
#   docker.mgm.sipwise.com/ngcp-klish-config-bullseye:latest bash
#
# Inside docker (the command is in the history, just press the UP button):
#   ./t/testrunner
#
################################################################################
