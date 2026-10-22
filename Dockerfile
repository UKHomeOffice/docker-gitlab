FROM sameersbn/gitlab:18.2.8 AS ruby-patched

# Rebuild libruby with GitLab's regexp patches for CVE-2026-110264
COPY patches/ruby/ /tmp/ruby-patches/
RUN rm -f /etc/apt/sources.list.d/pgdg.list /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      gcc g++ make patch libc6-dev zlib1g-dev libssl-dev libyaml-dev libgdbm-dev \
      libreadline-dev libncurses5-dev libffi-dev && \
    mkdir /tmp/ruby && cd /tmp/ruby && \
    curl -fsSL -o ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-${RUBY_VERSION}.tar.gz" && \
    echo "${RUBY_SOURCE_SHA256SUM}  ruby.tar.gz" | sha256sum -c - && \
    tar xzf ruby.tar.gz && cd "ruby-${RUBY_VERSION}" && \
    for p in /tmp/ruby-patches/*.patch; do echo "Applying ${p}" && patch -p1 -i "${p}" || exit 1; done && \
    ./configure --disable-install-rdoc --enable-shared && \
    make -j4 "libruby.so.${RUBY_VERSION}" && \
    mkdir /tmp/libruby && cp "libruby.so.${RUBY_VERSION}" /tmp/libruby/

FROM sameersbn/gitlab:18.2.8
LABEL Maintainer="Rohith <gambol99@gmail.com>"

COPY --from=ruby-patched /tmp/libruby/ /usr/local/lib/
# Fail the build if the patch isn't applied
RUN ldconfig && ldd "$(command -v ruby)" | grep libruby && \
    ruby -e 'begin; Regexp.new("(?:foobar){0,100}" * 100_000); rescue RegexpError => e; raise unless e.message.start_with?("too many range repeat"); puts "Onigmo patched"; else; abort "Onigmo NOT patched (CVE-2026-110264)"; end'

RUN rm -f /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt update -y && \
    apt install -y python3-setuptools && \
    rm -rf /var/lib/apt/lists/*

ENV S3CMD_VERSION=2.3.0

RUN curl -sL http://sourceforge.net/projects/s3tools/files/s3cmd/${S3CMD_VERSION}/s3cmd-${S3CMD_VERSION}.tar.gz/download -o /tmp/s3cmd-${S3CMD_VERSION}.tar && \
    tar zxvf /tmp/s3cmd-${S3CMD_VERSION}.tar -C /tmp && \
    cd /tmp/s3cmd-${S3CMD_VERSION} && \
    python3 setup.py install && \
    rm -rf /tmp/s3cmd-${S3CMD_VERSION}

ADD bin/run.sh /run.sh
ADD bin/kms_backup.sh /opt/bin/kms_backup.sh
ADD assets/logging.conf /etc/supervisor/conf.d/logging.conf
# Custom log rotation. Important because otherwise logs accumulate and the node GitLab is on starts to evict pods
# as a way to reclaim storage space.
COPY assets/logrotate_gitlab /etc/logrotate.d/gitlab
# Covered by the above (/etc/logrotate.d/gitlab).
RUN rm -f /etc/logrotate.d/supervisord

ENTRYPOINT [ "/run.sh" ]
