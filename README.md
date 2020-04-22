### changes for java 11

additions to pom dependencies

### /health url moved /actuator/health

```
http://localhost:8030/actuator/health
{"status":"UP"}
```

as of springboot 2.0.5.RELEASE the health check endpoint is http://hostname:portnumber/applicationroot/actuator/health
see stockmanager-service.yaml below

also check if you have added the dependency

```
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

### update dockerhub repo names used

build_all_and_publish_dockerhub.sh
```
 cd shopfront
 mvn clean install
-if docker build -t danielbryantuk/djshopfront . ; then
-  docker push danielbryantuk/djshopfront
+if docker build -t robinjohnhopkins/djshopfront . ; then
+  docker push robinjohnhopkins/djshopfront
 fi
 cd ..
```

kubernetes/productcatalogue-service.yaml
```
     spec:
       containers:
       - name: productcatalogue
-        image: danielbryantuk/djproductcatalogue:1.0
+        image: robinjohnhopkins/djproductcatalogue:1.0
```

similarly for

kubernetes/shopfront-service.yaml

stockmanager-service.yaml
```
     spec:
       containers:
-      - name: stockmanager
-        image: danielbryantuk/djstockmanager:1.0
-        ports:
-        - containerPort: 8030
-        livenessProbe:
-          httpGet:
-            path: /health
-            port: 8030
-          initialDelaySeconds: 30
-          timeoutSeconds: 1
+        - name: stockmanager
+          image: robinjohnhopkins/djstockmanager:1.0
+          ports:
+            - containerPort: 8030
+          livenessProbe:
+            httpGet:
+              path: /actuator/health
+              port: 8030
+            initialDelaySeconds: 30
+            timeoutSeconds: 1
```

### use adoptopenjdk/openjdk11 docker image
```
shopfront/Dockerfile
@@ -1,4 +1,4 @@
-FROM openjdk:8-jre
+FROM adoptopenjdk/openjdk11
 ADD target/shopfront-0.0.1-SNAPSHOT.jar app.jar
 EXPOSE 8010
 ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```

### spring config

stockmanager/src/main/resources/application.properties

```
+server.port = 8030
+logging.level.org.springframework=DEBUG
+logging.level.com.zaxxer=DEBUG
+logging.level.org.hibernate=DEBUG
+
+# default path is jdbc:h2:mem:testdb
+# adding ;DB_CLOSE_ON_EXIT=FALSE
+# causes db to stay open
+#spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_ON_EXIT=FALSE
+spring.datasource.url=jdbc:h2:mem:testdb
+spring.datasource.driverClassName=org.h2.Driver
+spring.datasource.username=sa
+spring.datasource.password=
+
+spring.h2.console.enabled=true
+
+# very cool - spring.h2.console.enabled=true
+# causes h2 memory to accept connection on same port as listening, path h2-console gui
+# http://localhost:8030/h2-console
```

## FOLLOWS is original README

# oreilly-docker-java-shopping
This repo contains code samples from my O'Reilly minibook ["Containerizing Continuous Delivery in Java: Docker Integration for Build Pipelines and Application Architecture"](https://www.nginx.com/resources/library/containerizing-continuous-delivery-java/).

This README is intended to provide high-level guidance of the project, and detailed instructions can be found in the accompanying book.

## Project Structure

* ci-vagrant
 * Installation files that build a Jenkins instance that is ready for experimenting with the examples contained within the book.
 * Currently the installation is undertaken using [Vagrant](https://www.vagrantup.com/) and Oracle's [VirtualBox](https://www.virtualbox.org/)
 * Once Vagrant and VirtualBox are installed locally, the Jenkins box can be built from this directory using the `vagrant up` command
* functional-e2e-tests
 * Simple examples of functional end-to-end tests that use JUnit and [REST-assured](http://rest-assured.io/) to test the DJShopping application
* performance-e2e-tests
 * Simple examples of performance/load end-to-end tests that use [Gatling](http://gatling.io/#/) with SBT and Scala
* shopfront
 * The 'shopfront' microservice of the DJShopping example application that provides the primary entry point for the end-user (both Web UI and API-driven)
* productcatalogue
  * The 'product catalogue' microservice of the DJShopping example application, which provides product details like name and price
* stockmanager
  * The 'stock manager' microservice of the DJShopping example application, which provides stock information, such as SKU and quantity
* build_all.sh
  * Convenience shell script for triggering Maven builds of all of the application microservices. This script does not build the associated Docker images, but the minibook contains instructions for doing so, alongside the suggestion that the resulting Docker images are pushed to your own DockerHub account
* build_all_and_publish_dockerhub.yml
  * Convenience build and publish shell script for triggering Maven builds of all of the application microservices, building an associated Docker image, and (if successful) a push of the image to DockerHub. If you wish to use this script you will have to create a DockerHub account and substitute the existing account details ('danielbryantuk') with your own.
* docker-compose.yml
 * [Docker Compose](https://docs.docker.com/compose/) file that starts all of the DJShopping application microservice containers. Note that if you push your own version of the Docker images to your DockerHub account you will have to change the image names details within this file to run these (i.e. remove the 'danielbryantuk' account name)
 * Run the file via the command `docker-compose up`
* docker-compose-build.yml
  * [Docker Compose](https://docs.docker.com/compose/) file that contains the build configuration of the DJShopping application microservices.
  * Build the Docker images via the command `docker-compose -f docker-compose-build.yml build`
  * Build and run the Docker images via the command `docker-compose -f docker-compose-build.yml up --build`

## Example Jenkins Pipelines

Once the Jenkins instance has been built and configured as specified in the accompanying minibook, and the DJShopping build items have been configured and run, it will be possible to create Jenkins Pipeline examples for running end-to-end tests. The examples contained within the book are included here for reference:

### Single Service Initialisation Test

```
node {
    stage ('Successful startup check') {
        docker.image('danielbryantuk/djshopfront').withRun('-p 8010:8010') {
            timeout(time: 30, unit: 'SECONDS') {
                waitUntil {
                    def r = sh script: 'curl -s http://localhost:8010/health | grep "UP"', returnStatus: true
                    return (r == 0);
                }
            }
        }
    }
}
```

### End-to-end Initialisation Test

```
node {
    stage ('build') {
        git url: 'https://github.com/danielbryantuk/oreilly-docker-java-shopping.git'
        // conduct other build tasks
    }

    stage ('end-to-end tests') {
        timeout(time: 60, unit: 'SECONDS') {
            try {
                sh 'docker-compose up -d'
                waitUntil { // application is up
                    def r = sh script: 'curl -s http://localhost:8010/health | grep "UP"', returnStatus: true
                    return (r == 0);
                }

                // conduct main test here
                sh 'curl http://localhost:8010 | grep "Docker Java"'

            } finally {
                sh 'docker-compose stop'
            }
        }
    }

    stage ('deploy') {
        // deploy the containers/application here
    }
}
```

### End-to-end Functional Tests
```
node {
    stage ('build') {
        git url: 'https://github.com/danielbryantuk/oreilly-docker-java-shopping.git'
        // conduct other build tasks
    }

    stage ('end-to-end tests') {
        timeout(time: 60, unit: 'SECONDS') {
            try {
                sh 'docker-compose up -d'
                waitUntil { // application is up
                    def r = sh script: 'curl -s http://localhost:8010/health | grep "UP"', returnStatus: true
                    return (r == 0);
                }

                // conduct main test here
                sh 'cd functional-e2e-tests && mvn clean verify'

            } finally {
                sh 'docker-compose stop'
            }
        }
    }

    stage ('deploy') {
        // deploy the containers/application here
    }
}
```
