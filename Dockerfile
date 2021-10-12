FROM sameersbn/gitlab:14.1.1-1
LABEL Maintainer="Rohith <gambol99@gmail.com>"

# Lets Encrypt root cert expired which causes apt update to fail due to a expired cert (https://github.com/nodesource/distributions/issues/1266#issuecomment-931550203). 
# renaming the nodesource.list to .disabled, updating and installing the latest ca-certificates versions fixes this issue as it updates the certs
# this should be able to be removed in later versions of the base-image

RUN mv /etc/apt/sources.list.d/nodesource.list /etc/apt/sources.list.d/nodesource.list.disabled \
    && apt update -y \
    && apt install -y \
         ca-certificates \
    && mv /etc/apt/sources.list.d/nodesource.list.disabled /etc/apt/sources.list.d/nodesource.list

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    apt update -y && \
    apt install -y python3-setuptools && \
    rm -rf /var/lib/apt/lists/*

ENV S3CMD_VERSION 2.1.0

RUN curl -sL http://sourceforge.net/projects/s3tools/files/s3cmd/${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz/download -o /tmp/s3cmd-${S3CMD_VERSION}.tar && \
    tar zxvf /tmp/s3cmd-${S3CMD_VERSION}.tar -C /tmp && \
    cd /tmp/s3cmd-${S3CMD_VERSION} && \
    python3 setup.py install && \
    rm -rf /tmp/s3cmd-${S3CMD_VERSION}

ADD bin/run.sh /run.sh
ADD bin/kms_backup.sh /opt/bin/kms_backup.sh
ADD assets/logging.conf /etc/supervisor/conf.d/logging.conf

ENTRYPOINT [ "/run.sh" ]
