#!/bin/sh

mv -fv bingo.sql bingo.sql.old
rm -f bingo.sql.old.bz2
bzip2 -vv bingo.sql.old
mysqldump -ubi -pngo bingo > bingo.sql

mv -fv bingo-schema.sql bingo-schema.sql.old
rm -f bingo-schema.sql.old.bz2
bzip2 -vv bingo-schema.sql.old
mysqldump -ubi -pngo --no-data bingo > bingo-schema.sql

echo "Done!"
