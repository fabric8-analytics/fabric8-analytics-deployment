#!/usr/bin/python3

"""One-shot script to delete specified files from a bucket.
   BE CAREFUL, YOU'RE PLAYING WITH FIRE !

   Usage:
   $ source ../env.sh
   $ DEPLOYMENT_PREFIX=STAGE python3 s3_delete_objects.py
"""

from argparse import ArgumentParser
import boto3
from os import getenv
from sys import exit, stderr

_AWS_ACCESS_KEY_ID = getenv('AWS_ACCESS_KEY_ID')
_AWS_SECRET_ACCESS_KEY = getenv('AWS_SECRET_ACCESS_KEY')
_AWS_DEFAULT_REGION = getenv('AWS_DEFAULT_REGION')
_DEPLOYMENT_PREFIX = getenv('DEPLOYMENT_PREFIX')

_BUCKET = _DEPLOYMENT_PREFIX + '-bayesian-core-data'
_FILE_NAME = 'github_details.json'


class S3Cleaner(object):
    """Remove specified file from all 'folders' of a bucket."""

    @staticmethod
    def delete_s3_objects(delete=False):
        """Delete S3 objects."""
        resource = boto3.resource('s3',
                                  aws_access_key_id=_AWS_ACCESS_KEY_ID,
                                  aws_secret_access_key=_AWS_SECRET_ACCESS_KEY,
                                  region_name=_AWS_DEFAULT_REGION)

        print("About to {operation} all {file} files in {bucket} bucket:".
              format(operation="delete" if delete else "list", file=_FILE_NAME, bucket=_BUCKET))

        for object_summary in resource.Bucket(_BUCKET).objects.all():
            if object_summary.key.endswith('/' + _FILE_NAME):
                if delete:
                    print("Deleting", object_summary.key)
                    object_summary.delete()
                else:
                    print(object_summary.key)


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument("-d", "--delete",
                        help="Really delete the resources, not just list.",
                        action="store_true")
    args = parser.parse_args()

    if not all((_AWS_ACCESS_KEY_ID, _AWS_SECRET_ACCESS_KEY, _AWS_DEFAULT_REGION,
                _DEPLOYMENT_PREFIX)):
        print("Not all environment variables are properly defined.", file=stderr)
        exit(1)

    if not args.delete:
        print("This is dry-run. Use -d/--delete to really delete the resources.")

    S3Cleaner.delete_s3_objects(args.delete)
