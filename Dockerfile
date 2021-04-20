# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE="ubuntu:latest"
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE

# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

# Add vscode user to the container
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

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
# Setup vscode as nonroot user
# ---
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ---
# Set Python 3.9 as the default Python
# ---
## Install python 3.9
## N.B.: Make sure to use this method to install python3.9, otherwise there will be two version-3 python available in ubuntu
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 &&\
    update-alternatives --config python3

## Install pip
## N.B.: Preserve the order of first installing python 3.9 then pip
RUN apt install -y python3-pip
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
RUN mkdir -p /home/$USERNAME
WORKDIR /home/$USERNAME

# N.B.: Keep the order 1. entrypoint, 2. cmd
USER $USERNAME

# N.B.: Keep the order entrypoint than cmd
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Keep the container running
CMD tail -f /dev/null