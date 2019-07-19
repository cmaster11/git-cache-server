FROM httpd:2.4-alpine

RUN apk add --no-cache bash git sed

ADD ./funcs.sh /root/
ADD ./setup.sh /root/

CMD ["bash", "/root/setup.sh"]