FROM tutum/curl:trusty
MAINTAINER Feng Honglin <hfeng@tutum.co>

RUN apt-get update && apt-get install -y sysstat bc

ADD metrics.template /metrics.template
ADD *.sh /
RUN chmod +x /*.sh

ENV DB_NAME nodemetrics
ENV DB_USER root
ENV DB_PASS root
ENV COLLECT_PERIOD 60
ENV SERIES_NAME stats

CMD ["/run.sh"]
