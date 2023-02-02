FROM tomcat:7.0-jre8

COPY jchem/webapps /usr/local/tomcat/webapps/

# Creates "tomcat" user, makes them owner of tomcat app dir
RUN useradd --create-home --shell /bin/bash tomcat && \
	mkdir -p /home/tomcat/.chemaxon/licenses && \
	chmod 764 /home/tomcat/.chemaxon/licenses && \
	chown -R tomcat:tomcat /usr/local/tomcat /home/tomcat/.chemaxon

# Sets work directory to "tomcat" folder
WORKDIR /home/tomcat

# Sets default user as "tomcat"
USER tomcat

CMD ["catalina.sh", "run"]