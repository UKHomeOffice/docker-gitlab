FROM sameersbn/gitlab:13.0.0
MAINTAINER Rohith <gambol99@gmail.com>

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    apt update -y && \
    apt install -y python-setuptools && \
    rm -rf /var/lib/apt/lists/*

ENV S3CMD_VERSION 1.6.1

RUN curl -sL http://sourceforge.net/projects/s3tools/files/s3cmd/${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz/download -o /tmp/s3cmd-${S3CMD_VERSION}.tar && \
    tar zxvf /tmp/s3cmd-${S3CMD_VERSION}.tar -C /tmp && \
    cd /tmp/s3cmd-${S3CMD_VERSION} && \
    python setup.py install && \
    rm -rf /tmp/s3cmd-${S3CMD_VERSION}

ADD bin/run.sh /run.sh
ADD bin/kms_backup.sh /opt/bin/kms_backup.sh
ADD assets/logging.conf /etc/supervisor/conf.d/logging.conf

ENTRYPOINT [ "/run.sh" ]
