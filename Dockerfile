ARG NODE_VERSION=12

FROM node:${NODE_VERSION}-slim AS builder

RUN  apt-get update \
     && apt-get install -y wget gnupg ca-certificates locales \
     && sed -ie 's/# zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/g' /etc/locale.gen \
     && locale-gen

ENV LANG zh_TW.UTF-8

RUN  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'\
     # We install Chrome to get all the OS level dependencies, but Chrome itself
     # is not actually used as it's packaged in the node puppeteer library.
     # Alternatively, we could could include the entire dep list ourselves
     # (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix)
     # but that seems too easy to get out of date.
     && apt-get update \
     && apt-get install -y google-chrome-stable libxss1 python3 python3-dev fonts-cantarell ttf-freefont git

RUN  _wgeturl="https://github.com/google/fonts/archive/master.tar.gz" \
     && _gf="google-fonts" \
     # install wget
     && apt-get install wget \
     # make sure a file with the same name doesn't already exist
     && rm -f $_gf.tar.gz \
     && echo "Connecting to Github server..." \
     && wget $_wgeturl -O $_gf.tar.gz \
     && echo "Extracting the downloaded archive..." \
     tar -xf $_gf.tar.gz \
     && echo "Creating the /usr/share/fonts/truetype/$_gf folder" \
     && mkdir -p /usr/share/fonts/truetype/$_gf \
     && echo "Installing all .ttf fonts in /usr/share/fonts/truetype/$_gf" \
     find $PWD/fonts-master/ -name "*.ttf" -exec install -m644 {} /usr/share/fonts/truetype/google-fonts/ \; || return 1 \
     && echo "Updating the font cache" \
     && fc-cache -f > /dev/null \
     # clean up, but only the .tar.gz, the user may need the folder
     && rm -f $_gf.tar.gz \
     echo "Done."

RUN  rm -rf /var/lib/apt/lists/* \
     && wget --quiet https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -O /usr/sbin/wait-for-it.sh \
     && chmod +x /usr/sbin/wait-for-it.sh