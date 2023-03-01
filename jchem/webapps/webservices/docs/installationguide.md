# ::gears lg:: **JChem Web Services** installation and administration guide

### ::list-ol:: Table of Contents
 1. [::gear:: Prerequisites](#prerequisites)
 2. [::globe:: Deploying web application](#deploy)
 3. [::database:: Database handling](#database)
 4. [::lock:: Security configuration](#security)
 5. [::flask:: Reaction library configuration](#reaction-library)
 6. [::wrench:: Advanced configuration](#advanced)

<a name="prerequisites"></a>
## ::gear:: 1. Prerequisites

### _1.1 Install Java Runtime Environment_

::warning lg:: Since version `16.2.29.0` only __Java 8__ is supported!
<https://java.com/en/download/help/index_installing.xml>

<a name="chemaxon_home"></a>
### _1.2 Prepare ChemAxon home directory_ `$CHEMAXON_HOME`

As other ChemAxon products, __JChem Web Services__ is also using the so called "ChemAxon home directory", which is by default located at:

* _Windows:_ `%UserProfile%\chemaxon`
* _Linux/Mac:_ `~/.chemaxon`

::info-circle lg:: Exact location can be determined by typing `echo %UserProfile%` or `echo ~` correspondingly into a console.

It should be inside the user's home directory who is running the server application:

* _Windows:_ `C:\Users\username\` or `C:\Windows\System32\config\systemprofile\`
* _Linux/Mac:_ `/home/username/`

It can be overridden with environment variable called `CHEMAXON_HOME`<br/>
Later in this guide we will refer to this directory as `$CHEMAXON_HOME`([?](#chemaxon_home)).

__JChem Web Services__ is using this directory for multiple purposes:

 * Reading database configuration ([3.1](#dbconfig))
 * Creating sample configuration and database if no configuration available
 * Storing application related data (`app_db`), it is a disk based [Apache Derby](https://db.apache.org/derby) database. ([6.2](#appdb))

::warning lg:: __Please make sure the user who is running the application has write premission on that directory and there is enough space available (at least 300Mb) on the disk!__


### _1.3 Installation of license(s)_

All of your license files (`*.cxl`) must be copied to path `$CHEMAXON_HOME/licenses/`([?](#chemaxon_home)), by default:

* _Windows:_ `%UserProfile%\chemaxon\licenses\`
* _Linux/Mac:_ `~/.chemaxon/licenses/`

<a name="deploy"></a>
## ::globe:: 2. Deploying web application

__JChem Web Services__ is shipped in the form of a [WAR file](https://www.chemaxon.com/download/jchem-suite/#jcws) (Choose Platform Independent (.zip) and extract the WAR file from it).

You can install it into an Apache Tomcat or Eclipse Jetty container.

* [Apache Tomcat](https://tomcat.apache.org/tomcat-7.0-doc/appdev/installation.html)
* [Eclipse Jetty](http://www.eclipse.org/jetty/documentation)

The JVM parameters which we recommend: `-Xmx1500m -Djava.awt.headless=true`
These should be added into `JAVA_OPTS` environment variable (`CATALINA_OPTS` in case of Apache Tomcat)

::warning lg:: Of course recommendation for maximum memory setting highly depends on the size of the used database(s). See [JChem Structure Cache](https://docs.chemaxon.com/display/jchembase/JChem+Chemical+Database+Concepts#JChemChemicalDatabaseConcepts-structurecache) for further information.

### _2.1. Log files_

The logger configuration is inside the war on path `WEB-INF/classes/logback.xml`. The used logger framework is an implementation of [slf4j](http://www.slf4j.org) called [Logback](http://logback.qos.ch).
Modification of logger configuration is possible yet __not recommended__. It can be done by copying existing configuration as a temaplate, modify it and supply it back with a system property:
`-Dlogback.configurationFile=/path/to/config.xml`

All log files are configured on daily rolling basis with maximum history of 10 days.

More details:

* `chemaxon_measure.log` - Web Service requests: timestamp,thread,ip,username,duration,requestpath 
* `chemaxon_cfgstore.log` - Database actions performed on metadatastore which stores information on the tables and columns in databases. (Label, state, etc.)
* `chemaxon_client.log` - Log messages sent to the logger service by thirdparty applications, usually used only by ChemAxon own client applications (like Plexus Suite).
* `chemaxon.log` - Application business logic info and debug logging, configured to only log relevant informations for bug investigation.

##### Log files location

* _Tomcat:_ `$CATALINA_HOME/logs/`
* _Jetty:_ in `logs/` dir relative to the path from which the server application was started from (`WORKDIR`)

::warning lg:: __Make sure the application server process owner has write permission in the log directory!__

### _2.2. Reverse proxy_

Many times the application server itself is not accessible publicly on the network, but can be reached throug a proxy server.
For these cases proper configuration of __X-Forwarded-*__ http headers is needed.

<https://en.wikipedia.org/wiki/X-Forwarded-For>

* _Tomcat:_ 
  <https://tomcat.apache.org/connectors-doc/common_howto/proxy.html>
  <https://tomcat.apache.org/tomcat-7.0-doc/api/org/apache/catalina/valves/RemoteIpValve.html>
  
* _Jetty:_ 
  <https://www.eclipse.org/jetty/documentation/9.3.x/configuring-connectors.html#_proxy_load_balancer_connection_configuration>
  <http://download.eclipse.org/jetty/9.3.11.v20160721/apidocs/org/eclipse/jetty/server/ForwardedRequestCustomizer.html>

| Header name         | Value                                          |
|---------------------|------------------------------------------------|
| X-Forwarded-For     | Host of the original request                   |
| X-Forwarded-Port    | Port of the original request                   |
| X-Forwarded-Proto   | Protocol of the original request (http/https)  |

<a name="database"></a>
## ::database:: 3. Database handling

Supported relational databases:

 * Apache Derby
 * MySQL
 * PostgreSQL
 * Oracle Database
 * Microsoft SQL Server

<a name="dbconfig"></a>
### _3.1. Setting up your databases_

__JChem Web Services__ is shipped with a preconfigured sample database. This database is extracted to the user home directory on first start. The created resources are:

 * on Windows `%UserProfile%\chemaxon\ws-config.xml` (`c:\Windows\config\systemprofile\chemaxon` on 64-Bit Windows) and `%UserProfile%\chemaxon\ws-db\`
 * on Linux/Mac `~/.chemaxon/ws-config.xml` and `~/.chemaxon/ws-db/`

::info-circle lg:: If the `ws-config.xml` file exists during start, the sample database won't be extracted.

This `ws-config.xml` holds the database configurations available for the application. By default its content is:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ch:configs xmlns:ch="http://generated.ws2common.jchem.chemaxon">
    <config name="sample" type="JCHEM">
        <url>jdbc:derby:$chemaxon_db_dir$</url>
        <driver>org.apache.derby.jdbc.EmbeddedDriver</driver>
        <userName></userName>
        <password></password>
        <propertyTable>JChemProperties</propertyTable>
        <metaDataTable>JCHEMMETADATATABLE</metaDataTable>
    </config>
</ch:configs>
```
To add additional database configurations, simple add new <config> nodes matching this template:

```xml
<config name="" type="JCHEM">
    <url></url>
    <driver></driver>
    <userName></userName>
    <password></password>
    <propertyTable>JChemProperties</propertyTable>
    <metaDataTable>JCHEMMETADATATABLE</metaDataTable>
</config>
```

| Name          | Description                                                                     |
| ------------- |---------------------------------------------------------------------------------|
| name          | An identifier for this database configuration, used throughout the application  |
| url           | JDBC url for the database                                                       |
| driver        | JDBC driver for the database. [Common driver classnames][dburl]                 |
| userName      | database username                                                               |
| password      | database password                                                               |
| propertyTable | JChem structure tables' metadata storage. [Further material][jchemprop]         |
| metaDataTable | JChem Web Services metadata table name. Read below in Database maintenance      |

[dburl]: https://docs.chemaxon.com/display/jchembase/JChem+Base+FAQ#JChemBaseFAQ-dburl
[jchemprop]: https://docs.chemaxon.com/display/jchembase/JChem+Chemical+Database+Concepts#JChemChemicalDatabaseConcepts-JChemProperties

::info-circle lg:: Note: As the speed and latency of the connection between the database and web service havily affect performance, please consider to locate the database server close to the web service server.

### _3.2. Database maintenance_

__JChem Web Services__ requires metadata tables to store installation specific details for each database configuration. In case of an empty database, you have to create the metadata table before using the database through the REST API. This is accomplished by an empty POST request to the init service.

In case of upgrading your __JChem Web Services__ version, the regenerate service must be called, as new version may require schema changes and recalculation of fingerprints, hashes. You can upgrade your table by sending an a POST request to the regenerate service.

|Description              |HTTP Request                                                                            |Content-Type    |Response-Type   |
|-------------------------|----------------------------------------------------------------------------------------|----------------|----------------|
|~~initialize~~           |POST /rest-v0/data/{db config name}/init                                                |application/json|application/json|
|regenerate               |POST /rest-v0/data/{db config name}/table/{table name}/regenerate                       |application/json|application/json|

regenerate request:
```json
{
    "monitorId": "...";
}
```
(How to use monitors is described in the api docs, `monitorId` is optional)

::info-circle lg:: Initialization happens automatically since version `15.2.2.0`

<a name="security"></a>
## ::lock:: 4. Security configuration

For enabling authentication some system properties must be provided for the servlet container (they can be added at the same place where the [memory releated settings](#deploy) were done).
The configuration contains the setting of two profiles

 * _authentication type:_ By specifing the type you can select one of the pre-configured templates or reference to an external one.
 * _authentication source:_. Source configures the location of credentials (typically username and password pairs). The included credential templates can be only used for testing! (as they contain default passwords)
   ::warning:: __Please, always specify an external configuration file to prevent accidental overwriting of the file during updates!__

`-Dspring.profiles.active={comma separated list of active profiles}`

`-Dsecurity.source.location=file:~user/spring-security-source.xml`

`-Dsecurity.http.location=file:~user/spring-security-http.xml`

### _4.1. Choosing HTTP authentication type_

The REST api currently supports 3 types of http authentication. Authentication details are stored in the user session on the server and session tracking is done with cookies so the client must support handling of cookies.

|Type                                                                                                                |Profile name                   |
|--------------------------------------------------------------------------------------------------------------------|-------------------------------|
|[HTTP Basic][basic]                                                                                                 |`security-http-basic`          |
|[HTTP Digest][digest]                                                                                               |`security-http-basic-digest`   |
|Login service                                                                                                       |`security-http-loginservice`   |
|Read only access for all table without authentication, basic authentication for other services                      |`security-http-basic-ro`       |
|Utility services needed by Marvin4JS can be accessed without authentication, basic authentication for other services|`security-http-basic-marvin4js`|

[basic]: https://en.wikipedia.org/wiki/Basic_access_authentication
[digest]: https://en.wikipedia.org/wiki/Digest_access_authentication

#### 4.1.1 Usage of Login service

<pre>
<b>POST</b> <i>/rest-v0/login</i>
Content-Type: application/json
</pre>

Sample request:

```json
{
    "username": "username",
    "password": "password"
}
```
::warning lg:: The client must support cookies for session tracking!

### _4.2. Setting up authentication source_

The source of the authentication can be configured by activating `security-source-external` profile and providing system property:

`-Dsecurity.source.location=file:{path to the xml file, containing authentication source details}`

#### 4.2.1 Sample xml for plain text user details

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
    xmlns:p="http://www.springframework.org/schema/p" xmlns:util="http://www.springframework.org/schema/util"
    xmlns:aop="http://www.springframework.org/schema/aop" xmlns:security="http://www.springframework.org/schema/security"
    xsi:schemaLocation="
    http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context.xsd
    http://www.springframework.org/schema/util
    http://www.springframework.org/schema/util/spring-util.xsd
    http://www.springframework.org/schema/aop
    http://www.springframework.org/schema/aop/spring-aop.xsd
    http://www.springframework.org/schema/security
    http://www.springframework.org/schema/security/spring-security-3.2.xsd">

    <security:authentication-manager alias="authenticationManager">
        <security:authentication-provider user-service-ref="userService" />
    </security:authentication-manager>

    <security:user-service id="userService">
            <security:user name="admin" password="admin" authorities="ROLE_USER,ROLE_ADMIN" />
            <security:user name="user" password="user" authorities="ROLE_USER" />
    </security:user-service>

    <bean id="rememberMeUserDetailsService" class="chemaxon.jchem.webservice2.security.DelegatingUserDetailsService">
        <constructor-arg>
            <list>
                <ref bean="userService"/>
            </list>
        </constructor-arg>
    </bean>

    <bean id="authenticationMessage" class="java.lang.String">
      <constructor-arg value="Embedded authentication profile is active. Please contact your administartor for credentials!"/>
    </bean>

</beans>
```

#### 4.2.2 Sample xml for plain text user details with hashed password

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
    xmlns:p="http://www.springframework.org/schema/p" xmlns:util="http://www.springframework.org/schema/util"
    xmlns:aop="http://www.springframework.org/schema/aop" xmlns:security="http://www.springframework.org/schema/security"
    xsi:schemaLocation="
    http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context.xsd
    http://www.springframework.org/schema/util
    http://www.springframework.org/schema/util/spring-util.xsd
    http://www.springframework.org/schema/aop
    http://www.springframework.org/schema/aop/spring-aop.xsd
    http://www.springframework.org/schema/security
    http://www.springframework.org/schema/security/spring-security-3.2.xsd">

    <security:authentication-manager alias="authenticationManager">
        <security:authentication-provider user-service-ref="userServiceHashed" >
            <security:password-encoder hash="sha-256" base64="false" />
        </security:authentication-provider>
    </security:authentication-manager>

    <security:user-service id="userServiceHashed">
            <security:user name="admin2" password="2257fff554f4090e9a407ac4f7059d52f50895be9adf43487ba0ba29b77d165b" authorities="ROLE_USER,ROLE_ADMIN" />
            <security:user name="user2" password="2257fff554f4090e9a407ac4f7059d52f50895be9adf43487ba0ba29b77d165b" authorities="ROLE_USER" />
    </security:user-service>

    <bean id="rememberMeUserDetailsService" class="chemaxon.jchem.webservice2.security.DelegatingUserDetailsService">
        <constructor-arg>
            <list>
                <ref bean="userServiceHashed"/>
            </list>
        </constructor-arg>
    </bean>

    <bean id="authenticationMessage" class="java.lang.String">
      <constructor-arg value="Embedded authentication profile is active. Please contact your administartor for credentials!"/>
    </bean>

</beans>
```

::info-circle lg:: More details of setting up hashed passwords can be found [here](http://docs.spring.io/autorepo/docs/spring-security/3.1.x/reference/springsecurity-single.html#nsa-password-encoder).

#### 4.2.3 Sample xml for JDBC based user details

For using a JDBC authentication the database must be prepared as described [here](http://docs.spring.io/autorepo/docs/spring-security/3.1.x/reference/springsecurity-single.html#appendix-schema).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:security="http://www.springframework.org/schema/security"
    xsi:schemaLocation="
    http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/security
    http://www.springframework.org/schema/security/spring-security-3.2.xsd">

    <security:authentication-manager alias="authenticationManager">
        <security:authentication-provider user-service-ref="userService">
            <security:password-encoder ref="passwordEncoder" />
        </security:authentication-provider>
    </security:authentication-manager>

    <bean id="passwordEncoder" class="org.springframework.security.authentication.encoding.Md5PasswordEncoder">
        <property name="iterations" value="100000" />
        <property name="encodeHashAsBase64" value="false" />
    </bean>

    <bean id="authDataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource" destroy-method="close">
        <property name="driverClass" value="com.mysql.jdbc.Driver" />
        <property name="jdbcUrl" value="jdbc:database://host/schema" />
        <property name="user" value="user" />
        <property name="password" value="password" />
    </bean>

    <security:jdbc-user-service id="userService" data-source-ref="authDataSource" role-prefix="ROLE_" />

    <bean id="authenticationMessage" class="java.lang.String">
      <constructor-arg value="Embedded authentication profile is active. Please contact your administartor for credentials!"/>
    </bean>

</beans>
```

::info-circle lg:: More details of setting up JDBC authentication source can be find [here](http://docs.spring.io/autorepo/docs/spring-security/3.1.x/reference/springsecurity-single.html#core-services-jdbc-user-service).

<a name="securitysample"></a>
### _4.3. Sample VM arguments_

activating external source xml with HTTP Basic:

`-Dspring.profiles.active=security-source-external,security-http-basic`

configure location of the external security source definition file:

`-Dsecurity.source.location=file:~user/spring-security-source.xml`

<a name="reaction-library"></a>
## ::flask:: 5. Reaction library configuration

The reaction based enumeration already contains reaction schemas designed by ChemAxon. To hide these schemas add `cxn-reaction-library-excluded` to the active profiles system property.

e.g. `-Dspring.profiles.active=security-http-basic,cxn-reaction-library-excluded`

<a name="advanced"></a>
## ::wrench:: 6. Advanced configuration

__JChem Web Services__ is using [Spring Framework](https://projects.spring.io/spring-framework) for internal configuration, for making it possible to tweak certain parts of the application, we have introduced a mechanism for providing some external [Spring configuration](http://docs.spring.io/spring/docs/3.0.x/spring-framework-reference/html/xsd-config.html).

>::info-circle:: There is no requirement on any knowledge about Spring framework for doing this configuration.

It can be achieved by activating a [Spring profile](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-profiles.html): `ext.config`, by providing (or modifying) a system property:
`-Dspring.profiles.active=ext.config`
>::info-circle:: Multiple spring profiles can be activated by this property, they can be simply listed separated with a comma. (like at [4.3](#securitysample))

Also there is need for another property for telling the application where to look for the external configurations:
`-Dext.config.dir=path/to/config/dir`

With these settings we are telling the application to search for external config files on the above configured path. It will try to load all resources matching pattern: `*Config.xml`.

Sample:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"
    xmlns:p="http://www.springframework.org/schema/p" xmlns:util="http://www.springframework.org/schema/util"
    xsi:schemaLocation="
    http://www.springframework.org/schema/beans
    http://www.springframework.org/schema/beans/spring-beans.xsd
    http://www.springframework.org/schema/context
    http://www.springframework.org/schema/context/spring-context.xsd
    http://www.springframework.org/schema/util
    http://www.springframework.org/schema/util/spring-util.xsd">

    <bean parent="clog.info" p:arguments="-- [ JCWS external configuration loaded successfully! ] --" />
</beans>
```
This configuration file overrides nothing, only logs the message _"JCWS external configuration loaded successfully!"_ if loaded successfully.

### _6.1. Caching_

Fine tuning of application caches. Sample configuration to include:
```xml
<beans ... >
    ...
    <bean id="globalImageCacheConfig" class="chemaxon.jchem.ws2base.util.CacheConfiguration">
        <property name="expireAfterAccessMinutes" value="30" />
        <property name="maximumSize" value="300" />
    </bean>
    <bean id="globalMoleculeCacheConfig" class="chemaxon.jchem.ws2base.util.CacheConfiguration">
        <property name="expireAfterAccessMinutes" value="30" />
        <property name="maximumSize" value="300" />
    </bean>
    <bean id="fieldCalculatorCacheConfig" class="chemaxon.jchem.ws2base.util.CacheConfiguration">
        <property name="expireAfterAccessMinutes" value="30" />
        <property name="maximumSize" value="300" />
    </bean>
    ...
</beans>
```
| Cache id                       | Description                                   |
|--------------------------------|-----------------------------------------------|
| globalImageCacheConfig         | Cache for all the generated images            |
| globalMoleculeCacheConfig      | Cache for all the input/output structures.    |
| fieldCalculatorCacheConfig     | Cache for all the calculator results          |

::info-circle lg:: We are caching values by a generated hash for the structure which is only matching for the __exact__ same structure.

<a name="appdb"></a>
### _6.2. Application database_

Enable/disable application database. Sample configuration to include:
```xml
<beans ... >
    ...
    <bean class="chemaxon.jchem.webservice2.ApplicationDatabaseConfig">
        <property name="disabled" value="false" />
    </bean>
    ...
</beans>
```
### _6.3. Disable interactive documentation page_

The application starter page is the interactive api documentation by default. For disabling it, just add system property for the server:
`-DdisableApidocs`