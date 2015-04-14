
Docker Containers: Not Just Servers in a Box!
=============================================

Docker Day II - April 15, 2015

* Chris Collins
* <christopher.collins@duke.edu>

https://github.com/clcollins/DockerDay2

---

## Think Outside the Box, er, Container

Majority of Docker use by sysadmins (at least at first): 

Replicating Servers inside of a Container

---

## Think Outside the Box, er, Container

Super Docker Wizards (10th Level or above) replicate *services* instead

---

## Think Outside the Box, er, Container

Super Docker Wizards (10th Level or above) replicate *services* instead

(...with linked containers)


---

## Think Outside the Box, er, Container

Super Docker Wizards (10th Level or above) replicate *services* instead

(...with linked containers)

(...and a bit of style)

---

## Think Outside the Box, er, Container

Developers, I think, use Docker in a similar manner:

---

## Think Outside the Box, er, Container

Developers, I think, use Docker in a similar manner

*Example:*

Web server + Language packages for easy testing

---

## Think Outside the Box, er, Container

Developers, I think, use Docker in a similar manner

*Example:*

Web server + Language packages for easy testing

(...but it's still a server)

---

## Advanced Docker Wizardry

(Earn Your Docker-ate Degree)

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

## Advanced Docker Wizardry

(Earn Your Docker-ate Degree)

Docker containers can be used in other ways.

---

## Advanced Docker Wizardry

(Earn Your Docker-ate Degree)

Docker containers can be used in other ways.

*Tangential to, or even unrelated to Servers and Services*


---

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Basic concept:*

Small, Single-purpose Docker container used to accomplish one task on linked containers

---

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Examples:*

1. Backups
2. Migrations
3. Monitoring
4. Maintenance

---

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Consider this:

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

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Run with:* 

    docker run --link datbase:database -v /srv/backups:/backups --rm -it do_backups

1. dumps a mysql backup to /srv/backups on the host
2. can be run linked to dozens, hundreds of MySQL containers
3. removes the need for cron, backup scripts, mounted volumes, etc from MySQL container

---

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Consider this:*

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

## Advanced Docker Wizardry (DKRWIZ 301)

__Docker Container as a Binary__

*Run with:*

    docker run --volumes-from web --rm -it logrotate

1. connects to "web"; rotates all logs
2. as before, is generic; can run on any linked container
3. removes the need for cron, logrotate on any linked containers


---

## Advanced Docker Wizardry (DKRWIZ 302)

__Helper Containers__

*Basic concept:*

Reduce complexity of Server (or Service) containers by pre-configuring them!

---
## Advanced Docker Wizardry (DKRWIZ 302)

__Helper Containers__

*Consider this:*

    FROM centos:centos7
    MAINTAINER Chris Collins <collins.christopher@gmail.com>
    
    RUN yum install -y mariadb-server && yum clean all
    EXPOSE 3306
    ENTRYPOINT ["/usr/bin/mysqld_safe"]

A super-simple MySQL container.  Easy to maintain.  Single job.

*Question:*

What would happen if you ran this container?

---


## Advanced Docker Wizardry (DKRWIZ 302)

__Helper Containers__

*Answer:*

Nothing.  Nada.  *Zilch.*

MySQL is not configured, no users, no initialized databases.  It runs, and dies.

---

## Advanced Docker Wizardry (DKRWIZ 302)

__Helper Containers__

*Answer:*

Nothing.  Nada.  *Zilch.*

MySQL is not configured, no users, no initialized databases.  It runs, and dies.

(...like a sad little mayfly)

---

## Advanced Docker Wizardry (DKRWIZ 302)

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

## Advanced Docker Wizardry (DKRWIZ 302)

__Helper Containers__

*New answer:*

Fully functioning MySQL database container 

1. lightweight
2. easy to maintain
3. instant startup
4. no extra files or pre-configuration
5. no need for "has this been done yet" checks
6. no complicated bash startup scripts, etc.
7. can be started, restarted, built, rebuilt

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Basic concept:*

Build an image twice - once to configure, and once to finalize

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Real World (gasp!) example:*

Fail-over DNS server in a Docker container

1. requires up-to-date named.conf
2. named.conf generated by ruby script that queries DNS servers
3. updates take 15+ minutes, so use as a rapid fail-over not so helpful

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Solution:*

Build the Docker image every 4 hours

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Solution:*

Build the Docker image every 4 hours

*New Problem:*

Build server doesn't have Ruby version/gems required to run named.conf gen. script 

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Solution:*

Build the Docker image every 4 hours

*New Problem:*

Build server doesn't have Ruby version/gems required to run named.conf gen. script 

(...and I don't want it to)

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*New Solution:*

Build the Docker image every 4 hours & let if configure *ITSELF*

---

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Consider this:*

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

## Advanced Docker Wizardry (DKRWIZ 401)

__Multi-run Images__

*Build the image then run with:*

    docker run -v $(pwd):/srv -it dns-auth /srv/generate_named.rb > /srv/named.conf

1. $pwd has the generate\_named.rb script
2. generate\_named.rb script generates real named.conf file and dumps it back out to $pwd

Then, build the image again.

This time the real named.conf is copied into the image, and it can be launched wherever with the latest version.

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Basic concept:*

Docker as a build environment

(You're already doing this - esp. Developers.)

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Basic concept:*

Docker as a build environment

(You're already doing this - esp. Developers.)

Docker is wonderful for building code and testing in a self-contained environment.

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Basic concept:*

Docker as a build environment

You're already doing this - esp. Developers.

Docker is wonderful for building code and testing in a self-contained environment.

But...

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*What if it isn't self-contained?*

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Consider this:*

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

*Run with:*

    docker run -v /usr/sbin:/mnt -it dwarf_therapist

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Question:*

What did that do?
 
---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Answer:*

Scary right?

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Answer:*

But cool!

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Question:*

Guess who does this?

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Answer:*

DOCKER!

---

## Advanced Docker Wizardry (DKRWIZ 402)

__Build and Install__

*Answer:*

DOCKER!

The Docker folks have a pre-made development environment inside of a Docker image.

The resulting Docker binary is dropped into a directory on the host system for use.

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*Basic concept:*

Build a Docker image inside a Docker container

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*Question:*

OH DEAR GOD WHY!?

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*Answer:*

Because I could.

(Non, Je ne regrette rien)

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*The long Answer:*

Working with a Developer - 

1. had static code that would live inside the image, from Github
2. had dynamic content that would live in mounted volumes, from users
3. Dev needed to rapidly build and deploy when needed
4. I wanted this to work on any server; did not want a registry involved

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*How:*

Docker *Inside* Docker (DIND)

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__ (DIND)

Docker *Inside* Docker

...by, SURPRISE!, Jerome Petazzoni ('nsenter' fame, among other stuff)

---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__ (DIND)

Docker *Inside* Docker

...by, SURPRISE!, Jerome Petazzoni (nsenter fame, among other stuff)

*Taken and modified like so:*

    FROM ubuntu:14.10
    MAINTAINER Chris Collins <christopher.collins@duke.edu>
    
    ENV TERM=xterm
    ENV DEBIAN_FRONTEND noninteractive
    ENV PKGS git docker curl apt-transport-https ca-certificates curl lxc iptables
    
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

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

*And run:*

    docker run --privileged -v ~/images:/tmp --rm -it docker_build
    
    root@885ad1955fbf:/build_it.sh


---

## Advanced Docker Wizardry (DKRWIZ 501)

__Docker-ception!__

1. runs Docker inside a container configured with build tools and Dev's code
2. builds another image (the real image)
3. `Docker save`'s it to the host disk for load

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Basic concept:*

Provide a container mount points and/or privileged access to manage its host

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Consider this:*

    docker run -it centos:centos7 sh -c "cat /proc/sys/vm/swappiness"
    60
    docker run --privileged -it centos:centos7 sysctl -w vm.swappiness=65

Swappiness of the host is adjusted inside a container.

*Question:*

But why?

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Answer:*

AUTOMATION! THE CLOUD! And, ...stuff!

You don't need to have direct access to the host to manage it.

1. cloud hosts w/remote Docker API (--tlsverify, etc)
2. hosts are throwaway, ephemeral
3. need to make a change?  Fire up your Docker management tool (docker-compose, fig, etc) and do it!

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Consider this:*

    docker run --privileged -v /proc/mounts:/srv/mounts:ro -it centos:centos7 sh -c "cat /srv/mounts"

The host's mount points are exposed to the container.

*Question:*

But why?

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Answer:*

Remote monitoring!

1. Nagios
2. Cacti
3. Logstash Forwarder
4. Your own scripts
5. etc..

Attach one to every host for instant monitoring/trending - no need to install or configure any packages on the host.

---

## Advanced Docker Wizardry (DKRWIZ 502)

__Using Containers to Manage their Hosts__

*Example of this in the wild:*

Google CAdvisor (https://github.com/google/cadvisor)

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

## Further Reading

Containers as a Binary:

* http://blog.xebia.com/2014/07/04/create-the-smallest-possible-docker-container/

Docker Development Environment:

* https://docs.docker.com/v1.5/contributing/devenvironment/

Docker In Docker:

* https://github.com/jpetazzo/dind

More with Privileged Containers:

* https://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/
* https://developerblog.redhat.com/2014/11/06/introducing-a-super-privileged-container-concept/

Awesome Wizard Ascii Art:

* http://ascii.co.uk/art/wizard

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
