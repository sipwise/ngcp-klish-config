# DOCKER_NAME=ngcp-klish-config-buster
FROM docker.mgm.sipwise.com/sipwise-buster:latest

# Important! Update this no-op ENV variable when this Dockerfile
# is updated with the current date. It will force refresh of all
# of the base images and things like `apt-get update` won't be using
# old cached versions when the Dockerfile is built.
ENV REFRESHED_AT 2020-04-01

# files that get-code generates
COPY t/sources.list.d/builddeps.list /etc/apt/sources.list.d/
COPY t/sources.list.d/preferences /etc/apt/preferences.d/

RUN apt-get update && \
    apt-get install --assume-yes \
             jq \
             lua-unit \
             lua-lemock \
             lua-dbi-mysql \
             lua-socket \
             lua-uri \
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
# You need to put the proper NGCP sources at t/sources.list.d/builddeps.list
# for instance, trunk:
#
# % echo "deb https://deb.sipwise.com/autobuild/ release-trunk-buster main" \
#   >t/sources.list.d/builddeps.list
#
# % docker build --tag="ngcp-klish-config-buster" -f t/Dockerfile .
# % docker run --rm -i -t -v $(pwd):/code:rw ngcp-klish-config-buster:latest bash
#
# To use the existing docker image:
#
# % docker pull docker.mgm.sipwise.com/ngcp-klish-config-buster
# NOTE: run the following command from the root folder of the git repository:
# % docker run --rm -i -t -v $(pwd):/code:rw \
#   docker.mgm.sipwise.com/ngcp-klish-config-buster:latest bash
#
# Inside docker (the command is in the history, just press the UP button):
#   ./t/testrunner
#
################################################################################
