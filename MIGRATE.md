```bash
export AWS_ACCESS_KEY_ID=<redacted>
export AWS_SECRET_ACCESS_KEY=<redacted>
export PYTHONPATH=/usr/local/lib/python2.6/dist-packages/

cd /usr/local/fieldpapers/site/www/files/mbtiles
aws s3 sync . s3://mbtiles.fieldpapers.org/ --exclude \* --include \*.mbtiles --acl public-read

cd /usr/local/fieldpapers/site/www/files/scans
aws s3 sync . s3://snapshots.fieldpapers.org/ --acl public-read

cd /usr/local/fieldpapers/site/www/files/prints
aws s3 sync . s3://atlases.fieldpapers.org/ --acl public-read
```
