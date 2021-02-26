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

RUN apt-get update && apt-get install -y software-properties-common

RUN add-apt-repository ppa:deadsnakes/ppa

RUN apt-get update && DEBIAN_PACKAGES=$(egrep -v "^\s*(#|$)" /usr/local/debian-requirements.txt) && \
    apt-get install -y $DEBIAN_PACKAGES && \
    apt-get clean

RUN apt-get --purge remove -y .\*-doc$ && \
    apt-get clean -y

ENV PATH /usr/local/texlive/2017/bin/x86_64-linux:$PATH

# ---
# Set Python 3.9 as the default Python
# ---
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3.9 get-pip.py

## Remove old symbolic link and create new to python 3.9
RUN rm /usr/bin/python3 && ln -s /usr/bin/python3.9 /usr/bin/python3
# ---
# Copy Container Setup Scripts
# ---
COPY bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/setup_python.sh /usr/local/bin/setup_python.sh
COPY bin/test_environment.py /usr/local/bin/test_environment.py
COPY bin/setup.py /usr/local/bin/setup.py
COPY python_requirements.txt /usr/local/python_requirements.txt

RUN chmod +x /usr/local/bin/setup_python.sh && \
    chmod +x /usr/local/bin/entrypoint.sh && \
	chmod +x /usr/local/bin/test_environment.py && \
	chmod +x /usr/local/bin/setup.py

RUN bash /usr/local/bin/setup_python.sh test_environment && \
	bash /usr/local/bin/setup_python.sh requirements
	
# Create the "home" folder
RUN mkdir -p /home/docker_user
WORKDIR /home/docker_user

# N.B.: Keep the order entrypoint than cmd
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Keep the container running
CMD tail -f /dev/null