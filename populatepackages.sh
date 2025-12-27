#!/bin/sh

if [ -z "$1" ]; then
  path="/repo"
else
  path="$1"
fi

printf "populatepackages.sh\nretrieving package files from %s\n" "$path"

repos="core extra multilib core-testing extra-testing multilib-testing core-staging extra-staging multilib-staging"

for repo in $repos
do
    ./manage.py reporead x86_64 "$path/$repo/os/x86_64/$repo.db.tar.gz"

    ./manage.py reporead --filesonly x86_64 "$path/$repo/os/x86_64/$repo.files.tar.gz"

    ./manage.py readlinks "$path/$repo/os/x86_64/$repo.links.tar.gz"
done
