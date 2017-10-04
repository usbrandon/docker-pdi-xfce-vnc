# This Dockerfile is used to build an headles vnc image based on Ubuntu

FROM phusion/baseimage:0.9.22

MAINTAINER Brandon Jackson "usbrandon@gmail.com"
ENV REFRESHED_AT 2017-10-03

LABEL io.k8s.description="Headless VNC Container with Xfce window manager, Pentaho Data Integration and chromium" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="pdi, vnc, ubuntu, xfce" \
      io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

### JDBC Driver Versions
ENV POSTGRESQL_DRIVER_VERSION=9.4.1212 \
    MYSQL_DRIVER_VERSION=5.1.44 \
    JTDS_VERSION=1.3.1 \
    H2DB_VERSION=1.4.193 \
    HSQLDB_VERSION=2.3.4

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=$HOME/install \
    NO_VNC_HOME=$HOME/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=pentaho \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

# Set environment variables
ENV LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8" LC_ALL="en_US.UTF-8" TERM=xterm JAVA_VERSION=8 JAVA_HOME=/usr/lib/jvm/java-8-oracle \
   JMX_EXPORTER_VERSION=0.9 JMX_EXPORTER_FILE=/usr/local/jmx_prometheus_javaagent.jar

# Set label
LABEL java_version="Oracle Java $JAVA_VERSION"

# Configure system(charset and timezone) and install JDK
RUN locale-gen en_US.UTF-8 \
      && echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
      && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
      && echo '#!/bin/bash' > /usr/bin/oom_killer \
         && echo 'set -e' >> /usr/bin/oom_killer \
         && echo 'echo "`date +"%Y-%m-%d %H:%M:%S.%N"` OOM Killer activated! PID=$PID, PPID=$PPID"' >> /usr/bin/oom_killer \
         && echo 'ps -auxef' >> /usr/bin/oom_killer \
         && echo 'for pid in $(jps | grep -v Jps | awk "{print $1}"); do kill -9 $pid; done' >> /usr/bin/oom_killer \
         && chmod +x /usr/bin/oom_killer \
      && add-apt-repository -y ppa:webupd8team/java \
      && apt-get update \
      && echo oracle-java${JAVA_VERSION}-installer shared/accepted-oracle-license-v1-1 select true \
            | /usr/bin/debconf-set-selections \
      && apt-get install -y --allow-unauthenticated software-properties-common \
         wget tzdata net-tools curl iputils-ping iotop iftop tcpdump lsof htop iptraf xauth \
         oracle-java${JAVA_VERSION}-installer oracle-java${JAVA_VERSION}-unlimited-jce-policy \
                && printf '2\n37\n' | dpkg-reconfigure -f noninteractive tzdata \
      && wget -O ${JMX_EXPORTER_FILE} http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /var/cache/oracle-jdk8-installer $JAVA_HOME/*.zip

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/ubuntu/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install chrome browser
RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### Install Pentaho Data Integration
### using a tar.gz which auto extracts saved two layers and 1gb
ADD pdi-ce-7.1.0.4-66.tar.gz $HOME/

# Add latest JDBC drivers and XMLA connector
# Patch Pentaho Data Integration to use lib/jdbc instead only lib
RUN ln -s ${HOME}/jdbc ${HOME}/data-integration/lib \
  && cd ${HOME}/data-integration/lib \
  && echo "=== Removing outdated JDBC Drivers ===" \
  && rm monetdb-jdbc-2.8.jar \
  && rm jt400-6.1.jar \
  && rm sqlite-jdbc-3.7.2.jar \
  && echo "Download and install JDBC drivers..." \
      && cd ${HOME}/jdbc \
	&& wget --progress=dot:giga https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/net/sourceforge/jtds/jtds/${JTDS_VERSION}/jtds-${JTDS_VERSION}.jar \
			http://central.maven.org/maven2/com/h2database/h2/${H2DB_VERSION}/h2-${H2DB_VERSION}.jar \
			http://central.maven.org/maven2/org/hsqldb/hsqldb/${HSQLDB_VERSION}/hsqldb-${HSQLDB_VERSION}.jar \
	&& sed -i -e 's|libraries=../test:../lib:../libswt|libraries=../test:../lib:../lib/jdbc:../libswt|' ${HOME}/data-integration/launcher/launcher.properties



### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
## TODO: This alteration ends up creating a 1gb layer
## docker-squash'ing the image eliminates it, but there must be a better way
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

USER 1984

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--tail-log"]
