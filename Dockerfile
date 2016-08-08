FROM debian:jessie

ENV JAVA_HOME="/usr"
ENV CATALINA_PID="/var/run/tomcat8.pid"
ENV CATALINA_HOME="/usr/share/tomcat8"
ENV CATALINA_BASE="/var/lib/tomcat8"
ENV JAVA_OPTS="-Xmx1024m"

RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list \
 && apt-get update -y \
 && apt-get install -y openjdk-8-jdk openssl apache2 libapache2-mod-shib2 tomcat8 tomcat8-admin supervisor wget curl vim \
 && a2enmod ssl \
 && a2enmod shib2 \
 && a2enmod proxy \
 && a2enmod proxy_http \
 && a2enmod proxy_ajp \
 && a2enmod headers \
 && a2enmod rewrite \
 && a2enmod cgi

#
# SP setup
#

COPY openssl/shibboleth-sp.cert.conf /opt/shibboleth-sp.cert.conf
RUN mkdir -p /etc/shibboleth/certs \
 && openssl req -config /opt/shibboleth-sp.cert.conf -new -x509 -days 365 -keyout /etc/shibboleth/certs/shib.key -out /etc/shibboleth/certs/shib.crt \
 && chmod 0700 /etc/shibboleth/certs/shib.crt \
 && chmod 0700 /etc/shibboleth/certs/shib.key

RUN mkdir -p mkdir -p /var/run/shibboleth
COPY sp/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
COPY sp/attribute-map.xml /etc/shibboleth/attribute-map.xml
COPY sp/attribute-policy.xml /etc/shibboleth/attribute-policy.xml

#
# Tomcat
#
RUN mkdir -p /var/lib/tomcat8/temp \
 && mkdir -p /usr/share/tomcat8/common/classes \
 && mkdir -p /usr/share/tomcat8/server/classes \
 && mkdir -p /usr/share/tomcat8/shared/classes \
 && chown -R tomcat8:tomcat8 /usr/share/tomcat8 \
 && chown -R tomcat8:tomcat8 /var/lib/tomcat8 \
 && rm -rf /var/lib/tomcat8/webapps/ROOT

COPY tomcat/server.xml /etc/tomcat8/server.xml
COPY tomcat/tomcat-users.xml /etc/tomcat8/tomcat-users.xml

#
# Apache
#
COPY openssl/apache.cert.conf /opt/apache.cert.conf
COPY apache/default.conf /etc/apache2/sites-available/default.conf
RUN mkdir -p /etc/apache2/certs \
 && openssl req -config /opt/apache.cert.conf -new -x509 -days 365 -keyout /etc/apache2/certs/apache.key -out /etc/apache2/certs/apache.crt \
 && chmod 0700 /etc/apache2/certs/apache.crt \
 && chmod 0700 /etc/apache2/certs/apache.key \
 && a2dissite 000-default \
 && a2ensite default

#
# Supervisor
#
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisord

#
# Exchange IDP and SP metadata
#
#RUN /etc/init.d/shibd start \
# && /etc/init.d/apache2 start \
# && mkdir -p /data/metadata \
# && wget --no-check-certificate -O /data/metadata/sp-metadata.xml https://localhost/Shibboleth.sso/Metadata \
# && cp /opt/shibboleth-idp/metadata/idp-metadata.xml /data/metadata/idp-metadata.xml

ADD download-idp-metadata.sh /opt/download-metadata.sh
RUN chmod u+x /opt/download-metadata.sh

COPY clarin-aai-debugger-1.1.war ${CATALINA_BASE}/webapps/debugger.war

VOLUME ["/data/metadata"]
EXPOSE 80 443 8009 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
