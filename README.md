
Docker Containers: Not Just Servers in a Box!
=============================================

Docker Day II - April 15, 2015

* Chris Collins
* <christopher.collins@duke.edu>

---

Think Outside the Box, er, Container
====================================

Majority of Docker use by sysadmins: replicate servers

---

Think Outside the Box, er, Container
====================================

Super Docker Wizards (10th Level or above) replicate *services* instead

---

Think Outside the Box, er, Container
====================================

Super Docker Wizards (10th Level or above) replicate *services* instead

(...with linked containers)


---

Think Outside the Box, er, Container
====================================

Super Docker Wizards (10th Level or above) replicate *services*

(...with linked containers)

(...and a bit of style)

---

Think Outside the Box, er, Container
====================================

Developers, I think, use Docker in a similar manner:

---

Think Outside the Box, er, Container
====================================

Developers, I think, use Docker in a similar manner

Ex: Webserver + Language packages for easy testing

---

Think Outside the Box, er, Container
====================================

Developers, I think, use Docker in a similar manner

Ex: Webserver + Language packages for easy testing

(...but it's still a server)

---

Advanced Docker Wizardry (Earn Your Docker-ate Degree)
========================

    (Abara-ka-
      -Dockera!)
            \\    ,/   * 
             \ _,'/_   |
               `(")' ,'/
            _ _,-H-./ /
            \_\_\.   /
              )" |  (
           __/   H   \__
           \    /|\    /
            `--'|||`--'
               ==^==

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Basic concept: Small, Single-purpose Docker container used to accomplish one task on linked containers

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Examples:

* Backups
* Migrations
* Monitoring
* Maintenance

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Consider this:

    FROM centos:centos7
    MAINTAINER Chris Collins <collins.christopher@gmail.com>
    
    RUN yum install -y mariadb && yum clean all
    RUN echo -e '\n\
    #!/bin/bash\n\
    set -x \n\
    USER=$(awk -F: "/USER/ {print $2}" /secret/dbcreds.yml)\n\
    PASS=$(awk -F: "/PASS/ {print $2}" /secret/dbcreds.yml)\n\
    HOST=$DATABASE_PORT_3306_TCP_ADDR\n\
    \n\
    mysqldump --all-databases -u${USER} -p{$PASS} -h${HOST}> /backup/$(date "+%Y%m%d")\n\
    ' >> /backup.sh
    
    ENTRYPOINT [ "bash", "/backup.sh" ]

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Run with: 

    docker run --link datbase:database -v /srv/backups:/backups --rm -it do_backups

* Dumps a mysql backup to /srv/backups on the host
* Can be run linked to dozens, hundreds of MySQL containers
* Removes the need for cron, backup scripts, mounted volumes, etc from MySQL container

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Consider this:

    FROM centos:centos7
    MAINTAINER Chris Collins <collins.christopher@gmail.com>
    
    RUN yum install -y logrotate
    
    RUN echo -e "\
    /var/log/*/*log {\n\
      rotate 7\n\
      daily\n\
      compress\n\
      delaycompress\n\
      copytruncate\n\
    }\n\
    " >> /logrotate.conf
    
    ENTRYPOINT ["logrotate", "-f", "/logrotate.conf"]

---

Advanced Docker Wizardry (DKRWIZ 301)
=======================

__Docker Container as a Binary__

Run with:

    docker run --volumes-from webserver --rm -it logrotate

* Connects to "webserver"; rotates all logs
* As before, is generic; can run on any linked container
* Removes the need for cron, logrotate on any linked containers

---

Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

Basic Concept: Reduce complexity of Server (or Service) containers by pre-configuring them!

---
Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

Consider this:

    FROM centos:centos7
    MAINTAINER Chris Collins <collins.christopher@gmail.com>
    
    RUN yum install -y mariadb-server && yum clean all
    EXPOSE 3306
    ENTRYPOINT ["/usr/bin/mysqld_safe"]

Question: What would happen if you ran this container?

---


Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

Answer:  Nothing.  Nada.  *Zilch.*

MySQL is not configured, no users, no initialized databases.  It runs, and dies.

---

Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

Answer:  Nothing.  Nada.  *Zilch.*

MySQL is not configured, no users, no initialized databases.  It runs, and dies.

(...like a sad little mayfly)

---

Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

But link a data container and run a helper container first (and just once!):

*<snip>*

    /usr/bin/mysql_install_db --datadir=${DATADIR} --user=mysql | tee $MYSQL_LOGFILE
    
    chown -R mysql:mysql "${DATADIR}"
    chmod 0755 "${DATADIR}"
    
    /usr/bin/mysqld_safe |tee $MYSQL_LOGFILE &
    
    sleep 5s && \
    
    mysql -u root -e "CREATE DATABASE ${DB_NAME};" \
            || f_err "Unable to create database"
    mysql -u root -e "GRANT ALL PRIVILEGES on *.* to 'backup'@'%' IDENTIFIED BY \"${BACKUP_PASS}\";" \
            || f_err "Unable to setup backup user"
    mysql -u root -e "GRANT ALL PRIVILEGES on ${DB_NAME}.* to 'root'@'%' IDENTIFIED BY \"${ROOT_PASS}\";" \
            || f_err "Unable to setup root user"
    # MAKE SURE THIS ONE IS LAST, OR WE'LL HAVE TO PASS THE ROOT PW EVERY TIME
    mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD(\"${ROOT_PASS}\") WHERE User='root'; FLUSH PRIVILEGES" \
            || f_err "Unable to set root user password"

*<snip>*

---

Advanced Docker Wizardry (DKRWIZ 302)
========================

__Helper Containers__

__NEW ANSWER:__ Fully functioning MySQL database container - 

* lightweight
* easy to maintain
* instant startup
* no extra files or pre-configuration
* no need for "has this been done yet" checks
* no complicated bash startup scripts, etc.
* can be started, restarted, built, rebuilt

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

Basic Concept:  Build an image twice - once to configure, and once to finalize

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

Real World (gasp!) example:  Failover authoratitive DNS server in a Docker container

* Requires up-to-date named.conf
* named.conf generated by ruby script that queries DNS servers
* Updates take 15+ minutes, so use as a "failover" not so helpful

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

Solution:  Build the Docker image every 4 hours

New Problem:  Build server doesn't have Ruby version/gems required to run named gen. script 

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

Solution:  Build the Docker image every 4 hours

New Problem:  Build server doesn't have Ruby version/gems required to run script 

(...and I don't want it to)

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

New Solution:  Build the Docker image every 4 hours & let if configure ITSELF

Consider this:

    FROM centos:7
    MAINTAINER Drew Stinnett <drews@duke.edu>
    
    ENV BINDPKGS bind bind-utils
    ENV DEBUGPKGS net-tools
    ENV RUBYPKGS rubygems ruby-devel gcc zlib-devel libxml2-devel tar patch
    ENV GEMS netaddr cog-dukereg bundler
    
    RUN yum -y install $BINDPKGS $DEBUGPKGS $RUBYPKGS
    RUN yum -y groupinstall "Development Tools" ; yum clean all
    
    RUN gem sources -a https://gems-internal.oit.duke.edu/
    RUN gem install $GEMS
    
    ADD named.conf /etc/named.conf  ### DUMMY NAMED FILE ###
    RUN chown named /etc/named.conf
    RUN mkdir -p /zones/data/{internal,external}
    RUN mkdir -p /var/log/named
    RUN chown -R named /var/named /zones /var/log/named
    
    EXPOSE 53
    
    CMD ["/usr/sbin/named","-u", "named", "-g"]

---

Advanced Docker Wizardry (DKRWIZ 401)
========================

__Multi-run Images__

Build the image then run with:

    docker run -v $(pwd):/srv -it dns-auth /srv/generate_named.rb > /srv/named.conf

* $pwd has the generate\_named.rb script
* generate\_named.rb script generates real named.conf file and dumps it back out to $pwd

Then, build the image again.

This time the real named.conf is copied into the image, and it can be launched wherever with the latest version.

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Basic Concept: Docker as a build environment

You're already doing this - esp. Developers.

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Docker is wonderful for building code and testing in a self-contained environment.

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Docker is wonderful for building code and testing in a self-contained environment.  But...

*What if it isn't self-contained?*

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Consider this:

    FROM ubuntu:14.10
    MAINTAINER Chris Collins <collins.christopher@gmail.com>
    ENV DT https://github.com/splintermind/Dwarf-Therapist/archive/v31.0.0.tar.gz
    
    RUN apt-get update && apt-get install -y curl tar gzip \
    make g++ qt5-qmake qtbase5-dev qtbase5-dev-tools qtdeclarative5-dev \
    texlive-full
    
    RUN mkdir /dt
    WORKDIR /dt
    RUN curl -L -O $DT
    RUN tar -xzf v31.0.0.tar.gz --strip-components=1
    RUN qmake -qt=5
    RUN make -j1
    
    VOLUME ['/mnt']
    
    ["/bin/cp", "-r", "/dt", "/mnt"]

Run with:

    docker run -v /usr/sbin:/mnt -it dwarf_therapist

Question:  What did that do?
 
---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Answer: Scary right?

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Answer: But cool!

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Question: Guess who does this?

---

Advanced Docker Wizardry (DKRWIZ 402)
========================

__Build and Install__

Answer: DOCKER!

https://docs.docker.com/v1.5/contributing/devenvironment/

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

Basic Concept:  Build a Docker image inside a Docker container

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

Question: OH DEAR GOD WHY!?

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

Answer: Because I could.

(Non, Je ne regrette rien)

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

The long Answer:

Working with a Developer: 

* had static code that would live inside the image, from Github
* had dynamic content that would live in mounted volumes, from users
* Dev needed to rapidy build and deploy when needed
* I wanted this to work on any server; did not want a registry involved

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

Docker In Docker (by Jerome Petazzoni, surprise): https://github.com/jpetazzo/dind

Modified like so:

    FROM ubuntu:14.10
    MAINTAINER Chris Collins <christopher.collins@duke.edu>
    
    ENV TERM=xterm
    ENV DEBIAN_FRONTEND noninteractive
    ENV PKGS docker curl apt-transport-https ca-certificates curl lxc iptables
    
    ADD . /srv
    RUN apt-get update -qq && apt-get install -qqy $PKGS \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
    
    RUN curl -sSL -o /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-latest
    ADD ./wrapdocker /usr/local/bin/wrapdocker
    RUN chmod +x /usr/bin/docker
    RUN chmod +x /usr/local/bin/wrapdocker
    
    VOLUME /var/lib/docker
    VOLUME /tmp
    WORKDIR /srv
    
    RUN echo -e '\n\
    #!/bin/bash\n\
    docker build -t my_image .\n\
    docker save myimage > /tmp/myimage.tar\n\
    ' >> /build_it.sh
    
    ENTRYPOINT ["/usr/local/bin/wrapdocker"]

---

Advanced Docker Wizardry (DKRWIZ 501)
========================

__Docker-ception!__

And run: 

    docker run --privileged -v ~/images:/tmp --rm -it docker_build
    
    root@885ad1955fbf:/build_it.sh

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Basic Concept: Provide a container mountpoints and/or privileged access to manage its host

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Consider this:

    docker run -it centos:centos7 sh -c "cat /proc/sys/vm/swappiness"
    60
    docker run --privileged -it centos:centos7 sysctl -w vm.swappiness=65

Swappiness of the host is adjusted inside a container.

Question:  But why?

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Answer: AUTOMATION! CLOUD, er STUFF!

You don't have to have direct access to the host to manage it.

* Cloud hosts w/Remote Docker API (--tlsverify, etc)
* Hosts are throwaway, ephemeral
* Need to make a change?  Fire up your Docker management tool (docker-compose, fig, etc) and do it!

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Consider this:

    docker run --privileged -v /proc/mounts:/srv/mounts:ro -it centos:centos7 sh -c "cat /srv/mounts"

The host's mount points are exposed to the container.

Question: But why?

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Answer: Remote monitoring!

* Nagios
* Cacti
* Logstash Forwarder
* Your own scripts
* etc..

Attach one to every host for instant monitoring/trending.

---

Advanced Docker Wizardry (DKRWIZ 502)
========================

__Using Containers to Manage their Hosts__

Example of this in the wild: Google CAdvisor (https://github.com/google/cadvisor)

Monitors the host and container usage, and provides a web UI and API for extracting the data.

    sudo docker run \
      --volume=/:/rootfs:ro \
      --volume=/var/run:/var/run:rw \
      --volume=/sys:/sys:ro \
      --volume=/var/lib/docker/:/var/lib/docker:ro \
      --publish=8080:8080 \
      --detach=true \
      --name=cadvisor \
      google/cadvisor:latest



---

Further Reading
===============

Containers as a Binary:

* http://blog.xebia.com/2014/07/04/create-the-smallest-possible-docker-container/

Docker In Docker:

* https://github.com/jpetazzo/dind

More with Privileged Containers:

* https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
* https://developerblog.redhat.com/2014/11/06/introducing-a-super-privileged-container-concept/

---

    ( Docker, Docker,            
        No toil, no trouble. ) 
               \
                \       ( Man Chris is bad at rhyming...sheesh.) 
                 \         /
                  \       /             .  
                   \         /^\     .
                    \   /\   "V"
                       /__\   I      O  o
                      //..\\  I     .
                      \].`[/  I
                      /l\/j\  (]    .  O
                     /. ~~ ,\/I          .
                     \\L__j^\/I       o
                      \/--v}  I     o   .
                      |    |  I   _________
                      |    |  I c(`       ')o
                      |    l  I   \.     ,/      
                    _/j  L l\_!  _//^---^\\_
                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
