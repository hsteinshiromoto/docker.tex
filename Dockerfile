# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE="ubuntu:latest"
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE

# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
ENV TZ Australia/Sydney

# Set container time zone
USER root
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
        maintainer="Humberto STEIN SHIROMOTO <h.stein.shiromoto@gmail.com>"

# ---
# Set up the necessary Debian packages
# ---
COPY debian-requirements.txt /usr/local/debian-requirements.txt

RUN apt-get update && \
	DEBIAN_PACKAGES=$(egrep -v "^\s*(#|$)" /usr/local/debian-requirements.txt) && \
    apt-get install -y $DEBIAN_PACKAGES && \
    apt-get clean

RUN apt-get --purge remove -y .\*-doc$ && \
    apt-get clean -y

ENV PATH /usr/local/texlive/2017/bin/x86_64-linux:$PATH
# ---
# Copy Container Setup Scripts
# ---
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh
	
# Create the "home" folder
RUN mkdir -p /home/docker_user
WORKDIR /home/docker_user

# N.B.: Keep the order entrypoint than cmd
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]