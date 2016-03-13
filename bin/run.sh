#!/bin/bash

GITLAB_ENV_FILE=${GITLAB_ENV_FILE:-""}

# step: read in the gitlab enviroment file if there is one
if [ -f ${GITLAB_ENV_FILE} ]; then
  source ${GITLAB_ENV_FILE}
fi

cat > /etc/aws-environment << EOF
BACKUP_DIR=${GITLAB_BACKUP_DIR:-/home/git/data/backups}
AWS_BACKUP_REGION=${AWS_BACKUP_REGION:-"eu-west-1"}
AWS_BACKUP_ACCESS_KEY_ID=${AWS_BACKUP_ACCESS_KEY_ID}
AWS_BACKUP_SECRET_ACCESS_KEY=${AWS_BACKUP_SECRET_ACCESS_KEY}
AWS_BACKUP_BUCKET=${AWS_BACKUP_BUCKET}
AWS_BACKUP_KMS_ID=${AWS_BACKUP_KMS_ID}
AWS_BACKUP_FILTER=${AWS_BACKUP_FILTER:-"*_gitlab_backup.tar"}
EOF

# step: inject the custom backup cron
case ${GITLAB_KMS_BACKUPS} in
  daily|weekly|monthly)
    echo "Configuring gitlab::backups::cron..."
    read hour min <<< ${GITLAB_KMS_BACKUP_TIME//[:]/ }
    day_of_month=*
    month=*
    day_of_week=*
    case ${GITLAB_KMS_BACKUPS} in
      daily)   ;;
      weekly)  day_of_week=0   ;;
      monthly) day_of_month=01 ;;
    esac
    cat >> /tmp/cron.${GITLAB_USER} <<EOF
$min $hour $day_of_month $month $day_of_week /bin/bash -l -c 'cd ${GITLAB_INSTALL_DIR} && bundle exec rake gitlab:backup:create RAILS_ENV=${RAILS_ENV} && /opt/bin/kms_backup.sh'
EOF
    crontab -u ${GITLAB_USER} /tmp/cron.${GITLAB_USER}
    rm -rf /tmp/cron.${GITLAB_USER}
    ;;
esac

# step: jump into the gitlab entrypoint
. /sbin/entrypoint.sh app:start
