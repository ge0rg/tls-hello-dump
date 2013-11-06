LDFLAGS=-lpcap

# Change these according to your needs:
CFLAGS=-Wall -DLOG_ADDRESSES #-DLOG_PORTS -DLOG_SESSIONID -DLOG_COUNTER

all: tls-hello-dump

clean:
	rm -rf tls-hello-dump tls-hello-dump.o

.PHONY: clean
