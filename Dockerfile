FROM node:14.16.1-slim

RUN  apt-get update \
     && apt-get install -y wget gnupg ca-certificates locales

RUN apt-get update \
&& apt-get -y install cabextract xfonts-utils \
&& wget http://ftp.de.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb \
&& dpkg -i ttf-mscorefonts-installer_3.6_all.deb \
&& apt-get install -f -y

RUN  sed -ie 's/# zh_TW.UTF-8 UTF-8/zh_TW.UTF-8 UTF-8/g' /etc/locale.gen
RUN  locale-gen
ENV  LANG zh_TW.UTF-8

RUN  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'\
     # We install Chrome to get all the OS level dependencies, but Chrome itself
     # is not actually used as it's packaged in the node puppeteer library.
     # Alternatively, we could could include the entire dep list ourselves
     # (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix)
     # but that seems too easy to get out of date.
     && apt-get update \
     && apt-get install -y google-chrome-stable libxss1 python3 python3-dev fonts-cantarell ttf-freefont git fonts-wqy-zenhei fonts-noto-cjk fontconfig

COPY ./fonts-master ./fonts-master

RUN cd fonts-master \
    && mkdir -p /usr/share/fonts/opentype/noto \
    && cp *otf /usr/share/fonts/opentype/noto \
    && mkdir -p /usr/share/fonts/truetype/google-fonts \
    && cp *ttf /usr/share/fonts/truetype/google-fonts \
    && find $PWD -name "*.ttf" -exec install -m644 {} /usr/share/fonts/truetype/google-fonts/ \; || return 1 \
    && mkfontscale \
    && mkfontdir \
    && fc-cache -f -v

RUN  rm -rf /var/lib/apt/lists/* \
     && wget --quiet https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -O /usr/sbin/wait-for-it.sh \
     && chmod +x /usr/sbin/wait-for-it.sh
