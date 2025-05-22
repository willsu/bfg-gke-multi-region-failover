FROM alpine:latest
COPY write-10G.sh /
CMD ["/write-10G.sh"]

