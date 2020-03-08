FROM python:3.6.8-stretch
MAINTAINER James Sh, day0x0000@protonmail.com
LABEL maintainer="day0x0000@protonmail.com"

ARG APP_UID=1111
ARG APP_GID=1111
ARG COMPOSE=0
ARG APP_PORT=8008
ARG TOR_DIST_URL=https://www.torproject.org/dist/torbrowser/9.0.5/tor-browser-linux64-9.0.5_en-US.tar.xz
ARG GECKODRIVER_DIST_URL=https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz

# Environments
ENV LANG=C.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    APP_USER=app \
    APP_HOME=/app \
    SHELL=/bin/bash \
    APP_ENV=$APP_ENV \
    APP_PORT=$APP_PORT \
    REBUILD_DATE=20200308

# Install base packages.
RUN DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt upgrade -y && \
    DEBIAN_FRONTEND=noninteractive LC_ALL=C apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      less vim \
      locales \
      netcat \
      traceroute \
      build-essential \
      sudo \
      wget \
      libgtk-3-0 libdbus-glib-1-2 xvfb x11-utils && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen $LANG && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -U pip
    # tor

RUN ( GROUP_ENT=$(getent group ${APP_GID}); \
      [ -z "$GROUP_ENT" ] \
        && addgroup --gid $APP_GID $APP_USER \
        || groupmod -n $APP_USER $(echo ${GROUP_ENT} | cut -d: -f1) \
    ) && \
    ( USER_ENT=$(getent passwd ${APP_UID}); \
      [ -z "$USER_ENT" ] \
        && adduser --system --uid $APP_UID --gid $APP_GID --shell=$SHELL $APP_USER \
        || ( OLD_USER=$(echo ${USER_ENT} | cut -d: -f1); mv /home/$OLD_USER /home/$APP_USER && \
            usermod -d /home/$APP_USER -s $SHELL -l $APP_USER $OLD_USER ) \
    ) && \
    usermod -a -G root $APP_USER && \
    usermod -a -G sudo $APP_USER && \
    mkdir -p $APP_HOME && \
    chown -R $APP_USER.$APP_USER $APP_HOME && \
    cd /home/$APP_USER && git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1 && \
    echo "GIT_PROMPT_ONLY_IN_REPO=1" >>/home/$APP_USER/.bashrc && \
    echo "source ~/.bash-git-prompt/gitprompt.sh" >>/home/$APP_USER/.bashrc && \
    echo 'eval `ssh-agent`' >>/home/$APP_USER/.bash_profile && \
    echo "cd /app" >>/home/$APP_USER/.bash_profile \
    echo "Adding $APP_USER to sudoers..." && \
    echo "$APP_USER ALL=NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p ${APP_HOME}

# setup geckodriver
RUN cd /tmp && \
    wget -q -c ${GECKODRIVER_DIST_URL} && \
    tar -C /usr/bin -xf /tmp/`basename ${GECKODRIVER_DIST_URL}` && \
    chmod 755 /usr/bin/geckodriver && \
    rm -f /tmp/`basename ${GECKODRIVER_DIST_URL}`

# setup APP_USER user
RUN chown -R $APP_USER:$APP_USER ${APP_HOME} && \
    echo "cd ${APP_HOME}" >>/home/$APP_USER/.bash_profile && \
    chown -R $APP_USER:$APP_USER /home/$APP_USER

ADD xvfb.init /etc/init.d/xvfb
RUN chmod +x /etc/init.d/xvfb && \
	update-rc.d xvfb defaults

RUN cd $APP_HOME && \
    wget -q -c "${TOR_DIST_URL}" && \
    tar xf `basename "${TOR_DIST_URL}"` && \
    rm -f `basename "${TOR_DIST_URL}"` && \
    chown -R $APP_USER:$APP_USER $APP_HOME/tor-browser_en-US*

# /home/app/.local/bin
USER $APP_USER
WORKDIR $APP_HOME

COPY --chown=$APP_USER:$APP_USER requirements.txt $APP_HOME/requirements.txt

RUN pip install -r requirements.txt

COPY --chown=$APP_USER:$APP_USER . $APP_HOME/

EXPOSE 8118 9050 9051 9053

CMD ["/app/run.sh"]
