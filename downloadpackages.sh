#!/bin/sh
if [ -z "$1" ]; then
  mirror="https://mirror.sanin.dev/arch-linux"
else
  mirror="$1"
fi
printf "downloadpackages.sh\nusing %s/\$repo/os/\$arch for mirror.\n" "$mirror"
repos="core extra multilib core-testing extra-testing multilib-testing core-staging extra-staging multilib-staging"
mkdir -p ./archives
rm -f archives/*.tar.gz
for repo in $repos
do
    curl "$mirror/$repo/os/x86_64/$repo.db.tar.gz" -o "archives/$repo.db.tar.gz"
    if [ $? -eq 0 ]; then
        ./manage.py reporead x86_64 "archives/$repo.db.tar.gz"
    fi
    curl "$mirror/$repo/os/x86_64/$repo.files.tar.gz" -o "archives/$repo.files.tar.gz"
    if [ $? -eq 0 ]; then
        ./manage.py reporead --filesonly x86_64 "archives/$repo.files.tar.gz"
    fi
    curl "$mirror/$repo/os/x86_64/$repo.links.tar.gz" -o "archives/$repo.links.tar.gz"
    if [ $? -eq 0 ]; then
        ./manage.py readlinks "archives/$repo.links.tar.gz"
    fi
done
rm -f archives/*
