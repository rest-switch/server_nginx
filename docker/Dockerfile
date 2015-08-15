# "ported" by Adam Miller <maxamillion@fedoraproject.org> from
#   https://github.com/fedora-cloud/Fedora-Dockerfiles
#
# Originally written for Fedora-Dockerfiles by
#   scollier <scollier@redhat.com>

FROM centos:centos7
MAINTAINER The CentOS Project <cloud-ops@centos.org>

RUN yum -y update && yum -y install epel-release tar wget ; yum clean all
RUN yum -y update && yum -y install gcc make google-perftools-devel openssl-devel pcre-devel nginx ; yum clean all
ADD nginx.conf /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir -p /tmp/docker
ADD Makefile /tmp/docker/Makefile
RUN curl https://git.centos.org/sources/httpd/c7/acf5cccf4afaecf3afeb18c50ae59fd5c6504910 \
    | tar -xz -C /usr/share/nginx/html --strip-components=1
RUN sed -i -e 's/Apache/nginx/g' -e '/apache_pb.gif/d' /usr/share/nginx/html/index.html
RUN make -C /tmp/docker ; rm -rf /tmp/docker

EXPOSE 80

CMD [ "/usr/sbin/nginx" ]
