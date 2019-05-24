#!/bin/bash
set -e

# This converts a docker file to a shell file
# Almost guaranteed to not work with many Docker files, but hey, it works for us

HOME_DIRECTORY=/home/dev
CONVERT_HOME_DIRECTORY=1

INPUT=Dockerfile
OUTPUT=Dockerfile.sh

echo "#!/bin/bash" > $OUTPUT
echo "set -e" >> $OUTPUT
echo 'DOCKERFILEPATH="$( cd "$(dirname "$0")" ; pwd -P )"' >> $OUTPUT
cat $INPUT > $OUTPUT

# Convert FROM, MAINTAINER, VOLUME, CMD to comments
sed -i "s/^FROM\s/# FROM /g" $OUTPUT
sed -i "s/^MAINTAINER\s/# MAINTAINER /g" $OUTPUT
sed -i "s/^VOLUME\s/# VOLUME /g" $OUTPUT
sed -i "s/^CMD\s/# CMD /g" $OUTPUT

# Get rid of RUNs
sed -i "s/^RUN\s//g" $OUTPUT

# Convert WORKDIR into cd
sed -i "s/^WORKDIR\s/cd /g" $OUTPUT

# Convert home directory into squiggles (tildes)
sed -i "s|$HOME_DIRECTORY|~|g" $OUTPUT

# Convert ENVs into EXPORTs
sed -r 's/^ENV\s([a-zA-Z0-9_-]*)[= \t]+(\w*)/export \1=\2/g' -i $OUTPUT

# Get rid of EXPOSE todo: open up ports based on these?
sed -i "s/^EXPOSE\s/# EXPOSE /g" $OUTPUT


# Convert ADD, COPY into cp
# special case: ADD . -> refers to Dockerfile directory, which is no longer the same as the working directory if WORKDIR was used!
sed -r -i 's/^(ADD|COPY)\s\./cp -r "$DOCKERFILEPATH"/g' $OUTPUT
sed -r -i "s/^(ADD|COPY)\s/cp -r /g" $OUTPUT

# Timestamp
sed -i '1s/^/# Generated by docker_to_sh, for all your shoddy bash script from Dockerfile generation needs. \n/' $OUTPUT

chmod +x $OUTPUT
