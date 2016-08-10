# Start with CentOS 7 as it has reliable package manager
FROM centos:7
MAINTAINER Matyas Markovics <markovics.matyas@gmail.com>
# Install pip and virtualenv
RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
RUN yum -y update
RUN yum -y install python-pip
RUN yum -y install python-virtualenv
# Install mysql
RUN yum -y install http://repo.mysql.com/yum/mysql-5.6-community/docker/x86_64/mysql-community-server-minimal-5.6.32-2.el7.x86_64.rpm
# Install development tools to build and start the service
RUN yum -y install git make which
# Create a user to run the service, required by MySQL (mysqld cannot be ran by root) 
RUN adduser lastfm
RUN su - lastfm -c 'git clone https://github.com/matyasmarkovics/lastfm-log-analysis.git'
RUN su - lastfm -c 'make -C lastfm-log-analysis start test'
# Make sure the service starts up with the docker image
RUN echo "su - lastfm -c 'pushd lastfm-log-analysis; git pull; popd'" >> /root/.bash_profile
RUN echo "su - lastfm -c 'make -C lastfm-log-analysis start'" >> /root/.bash_profile
RUN echo "su - lastfm -c 'make -C lastfm-log-analysis stop'" >> /root/.bash_logout
