FROM tomcat:9.0.21-jdk8-adoptopenjdk-hotspot
RUN apt-get update \
    && apt-get -y install --no-install-recommends wget \
    && rm -rf /var/lib/apt/lists/*

ENV UAA_VERSION=4.30.0
RUN wget \
      http://central.maven.org/maven2/org/cloudfoundry/identity/cloudfoundry-identity-uaa/$UAA_VERSION/cloudfoundry-identity-uaa-$UAA_VERSION.war \
      -O $CATALINA_HOME/webapps/uaa.war

ENV CLOUDFOUNDRY_CONFIG_PATH=$CATALINA_HOME/temp/uaa
RUN mkdir -p $CLOUDFOUNDRY_CONFIG_PATH
COPY uaa.yml $CLOUDFOUNDRY_CONFIG_PATH
COPY tomcat-users.xml $CATALINA_HOME/conf
COPY manager.xml $CATALINA_HOME/webapps/manager/META-INF/context.xml
COPY host-manager.xml $CATALINA_HOME/webapps/host-manager/META-INF/context.xml
ENV SPRING_PROFILES_ACTIVE=default,hsqldb
CMD ["catalina.sh", "run"]
EXPOSE 8080