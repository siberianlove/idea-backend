FROM debian:latest

ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh
CMD ["/run.sh"]
EXPOSE 22

# Install packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server sudo
RUN mkdir -p /var/run/sshd \
    && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config \
    && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && touch /root/.Xauthority \
    && true

## Set a default user. Available via runtime flag `--user docker`
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory, but also be able to sudo
RUN useradd docker \
    && passwd -d docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff \
    && addgroup docker sudo \
    && true

# setup workdir
RUN mkdir -p /root/githome/
WORKDIR /root/githome/

# install git/curl/tar/wget and slim down image
RUN apt-get -y update \
    && apt-get -y install git \
    && apt-get -y install curl \
    && apt-get -y install tar \
    && apt-get -y install wget \
    && apt-get -y install iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/man/?? /usr/share/man/??_*

RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
ARG DOCKER_GROUP_ID
RUN groupadd -g $DOCKER_GROUP_ID docker