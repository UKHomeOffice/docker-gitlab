FROM sameersbn/gitlab:8.2.1
MAINTAINER Rohith <gambol99@gmail.com>

RUN apt update -y && \
    apt install -y python-setuptools && \
    rm -rf /var/lib/apt/lists/*

ADD http://sourceforge.net/projects/s3tools/files/s3cmd/1.6.0/s3cmd-1.6.0.tar.gz/download /tmp/s3cmd-1.6.0.tar
RUN tar zxvf /tmp/s3cmd-1.6.0.tar -C /tmp && \
    cd /tmp/s3cmd-1.6.0 && \
    python setup.py install && \ 
    rm -rf /tmp/s3cmd-1.6.0cd && \

ADD bin/run.sh /run.sh
ADD bin/kms_backup.sh /opt/bin/kms_backup.sh

ENTRYPOINT [ "/run.sh" ]
