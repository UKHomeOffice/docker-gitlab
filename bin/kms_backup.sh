#!/bin/bash

S3CMD=`which s3cmd`

annonce() {
  (>&2 echo "[backup] $@")
}

# step: load the aws environment file
if [ -f /etc/aws-environment ]; then
  annonce "loading the aws environment file: /etc/aws-environment"
  . /etc/aws-environment
fi

BACKUP_DIR=${BACKUP_DIR:-/backups}
AWS_BACKUP_REGION=${AWS_BACKUP_REGION:-"eu-west-1"}
AWS_BACKUP_ACCESS_KEY_ID=${AWS_BACKUP_ACCESS_KEY_ID}
AWS_BACKUP_SECRET_ACCESS_KEY=${AWS_BACKUP_SECRET_ACCESS_KEY}
AWS_BACKUP_BUCKET=${AWS_BACKUP_BUCKET}
AWS_BACKUP_KMS_ID=${AWS_BACKUP_KMS_ID}
AWS_BACKUP_FILTER=${AWS_BACKUP_FILTER:-"*_gitlab_backup.tar"}
S3OPTS=${S3OPTS:-""}

usage() {
   cat <<EOF
   Usage: $(basename $0) [options]
    -d|--directory PATH		: a directory of files to backup to s3 (defaults ${BACKUP_DIR})
    -r|--region REGION          : the aws region we are presently seated
    -K|--key AWS_KEY            : the aws access key to use when uploading to the bucket
    -s|--secret AWS_SECRET      : the aws key to use when uploading to the bucket
    -b|--bucket NAME		: the aws name of the bucket to upload the backups to
    -k|--kms ID			: the aws kms id to use when encrypting the files
    -f|--filter                 : the file filter to apply to the files to backup (defaults ${AWS_BACKUP_FILTER})
EOF
   if [ -n "$1" ]; then
     echo "[error] $1"
     exit 1
   fi
   exit 0
}

# step: the command line options
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--directory)	BACKUP_DIR=$2 ; shift 2 ;;
    -b|--bucket)        AWS_BACKUP_BUCKET=$2 ; shift 2 ;;
    -r|--region)        AWS_BACKUP_REGION=$2 ; shift 2 ;;
    -K|--key)           AWS_BACKUP_ACCESS_KEY_ID=$2 ; shift 2 ;;
    -s|--secret)        AWS_BACKUP_SECRET_ACCESS_KEY=$2 ; shift 2 ;;
    -k|--kms)           AWS_BACKUP_KMS_ID=$2 ; shift 2 ;;
    -f|--filter)        AWS_BACKUP_FILTER=$2 ; shift 2 ;;
    *)                  shift 1 ; ;;
  esac
done

# step: validate we have everything
[ -z "${BACKUP_DIR}" ] && usage "you have not specified the BACKUP_DIR option"
[ -z "${AWS_BACKUP_BUCKET}" ] && usage "you have not specified the AWS_BACKUP_BUCKET option"
[ -z "${AWS_BACKUP_KMS_ID}" ] && usage "you have not specified the AWS_BACKUP_KMS_ID option"
[ -z "${AWS_BACKUP_REGION}" ] && usage "you have not specified the AWS_BACKUP_REGION option"
[ -z "${AWS_BACKUP_ACCESS_KEY_ID}" ] && usage "you have not specified the AWS_BACKUP_ACCESS_KEY_ID option"
[ -z "${AWS_BACKUP_SECRET_ACCESS_KEY}" ] && usage "you have not specified the AWS_BACKUP_SECRET_ACCESS_KEY option"

annonce "attempting to perform a backup of gitlab"

# step: find all files
while read backup_file; do
   annonce "processing the backup file: ${backup_file}"
   filename=$(basename $backup_file)
   bucket=s3://${AWS_BACKUP_BUCKET}/${filename}.encrypted

   time $S3CMD -v --no-progress \
     --region=${AWS_BACKUP_REGION} \
     --access_key=${AWS_BACKUP_ACCESS_KEY_ID} \
     --secret_key=${AWS_BACKUP_SECRET_ACCESS_KEY} \
     --server-side-encryption \
     --server-side-encryption-kms-id=${AWS_BACKUP_KMS_ID} ${S3OPTS} \
     put ${backup_file} $bucket

   if [ $? -ne 0 ]; then
     annonce "failed to upload the backup file to s3"
   else
     annonce "successfully uploaded the file to s3 backups $bucket"
     rm -f ${backup_file}
   fi

done < <(find ${BACKUP_DIR} -name "${AWS_BACKUP_FILTER}" -type f)
