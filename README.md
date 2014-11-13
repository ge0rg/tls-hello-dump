# TLS Hello Dumper

This is a tool to count the TLS protocol versions and ciphers encountered by
your server (or client). It is written (read: shamelessly copied) in C for
maximum efficiency on a high-traffic servers.

This program is inspired by xnyhps' great
[series](https://blog.thijsalkema.de/blog/2013/08/26/the-state-of-tls-on-xmpp-1/)
[of](https://blog.thijsalkema.de/blog/2013/08/28/the-state-of-tls-on-xmpp-2/)
[posts](https://blog.thijsalkema.de/blog/2013/09/02/the-state-of-tls-on-xmpp-3/)
about the state of TLS on XMPP. It is based on example code by the Tcpdump
Group.

## Restrictions

This tool so far only supports IPv4, has a hacked-together TCP packet parser
and its configuration options are severely limited.

If you feed it bad packets, it will die a horrible death, open a reverse shell
or eat your babies.

Currently, the tool is creating two log entries for each new SSL/TLS
connection. This will bias your statistics towards clients with bad
connectivity, and against long-living connections. *This is not a replacement
for dumping the SSL/TLS ciphers from all open connections to your server.*

If you specify a network device, it will enter PROMISC mode. Use only
if you are authorized to sniff the network.

## Compilation

To compile, simply run `make`. Have a look at the Makefile to tune the output
parameters (`#define`s). Possible compile-time options:

 * `LOG_COUNTER` display a linear packet counter
 * `LOG_ADDRESSES` display IPs
 * `LOG_PORTS` display TCP ports
 * `LOG_SESSIONID` show if packets contain a session ID (it is not actually dumped)

## Usage

Run the tool as root, supply at least the network interface as a parameter:

	./tls-hello-dump eth0

You can add a filter as well:

	./tls-hello-dump eth0 xmpp
	./tls-hello-dump eth0 https
	./tls-hello-dump eth0 'tcp port 995 and tcp[32]=22 and (tcp[37]=1 or tcp[37]=2)'

(The cryptic filter part starting with `and` is needed to filter out TLS Hello
packets. Never forget to add it!)

## Parsing the output

This is an example of the program output:

	tls-hello-dumper - TLS ClientHello/ServerHello Dumper
	Copyright (c) 2013 Georg Lukas, based on Tcpdump code.
	THERE IS ABSOLUTELY NO WARRANTY FOR THIS PROGRAM.

	Device: wlan0
	Filter expression: tcp port 443 and tcp[32]=22 and (tcp[37]=1 or tcp[37]=2)

	Source          Destination     Packet content
	192.168.23.42   83.223.75.24    TLSv1 ClientHello TLSv1.2 :C030:C02C:C028:C024:C014:C00A:C022:C021:00A3:009F:006B:006A:0039:0038:0088:0087:C032:C02E:C02A:C026:C00F:C005:009D:003D:0035:0084:C012:C008:C01C:C01B:0016:0013:C00D:C003:000A:C02F:C02B:C027:C023:C013:C009:C01F:C01E:00A2:009E:0067:0040:0033:0032:009A:0099:0045:0044:C031:C02D:C029:C025:C00E:C004:009C:003C:002F:0096:0041:C011:C007:C00C:C002:0005:0004:0015:0012:0009:0014:0011:0008:0006:0003:00FF:
	83.223.75.24    192.168.23.42   TLSv1 ServerHello TLSv1 cipher 0039

Depending on your compile-time options, you might see more or less columns.
The most interesting one is the last one, "Packet content". It starts with the
SSL/TLS protocol version of the packet, followed by either `ClientHello` or
`ServerHello`. Then comes the maximum SSL/TLS version supported by the sender.

A ClientHello contains the list of supported ciphers, in hexadecimal format.

A ServerHello contains the chosen cipher suite, in hex. This is what matters
for the connection.

Because hex is not very readable, you can convert the codes into their
Wireshark-equivalent names, by filtering the output with the following `sed`
command:

	./tls-hello-dump eth0 | sed -f ./readable.sed
	...
	83.223.75.24    192.168.23.42   TLSv1 ServerHello TLSv1 cipher TLS_DHE_RSA_WITH_AES_256_CBC_SHA
	...

**Beware:** The script will convert any uppercase two-byte hex numbers it
encounters into their equivalent cipher names.

## Obtaining Stats

The distribution comes with a helper script written in GAWK that counts the
used protocols and ciphers and outputs friendly stats:

	./tls-hello-dump stored-log.pcap | ./count-negotiated.awk
	Protocols:
	18	TLSv1.2
	4	TLSv1

	Ciphers:
	20	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	1	TLS_RSA_WITH_AES_256_CBC_SHA256
	1	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384

	Protocols+Ciphers:
	16	TLSv1.2	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	4	TLSv1	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	1	TLSv1.2	TLS_RSA_WITH_AES_256_CBC_SHA256
	1	TLSv1.2	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384

Please consider that if you generate statistics from `tls-hello-dump`, these
are skewed towards clients making more connections. You can reduce the effect
by only counting each individual IP+protocol+cipher combination once:

	./tls-hello-dump stored-log.pcap | sort | uniq | ./count-negotiated.awk
	Protocols:
	6	TLSv1.2
	4	TLSv1

	Ciphers:
	8	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	1	TLS_RSA_WITH_AES_256_CBC_SHA256
	1	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384

	Protocols+Ciphers:
	4	TLSv1	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	4	TLSv1.2	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	1	TLSv1.2	TLS_RSA_WITH_AES_256_CBC_SHA256
	1	TLSv1.2	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384


## License


This software is a modification of:

sniffex.c

Sniffer example of TCP/IP packet capture using libpcap.

Version 0.1.1 (2005-07-05)
Copyright (c) 2005 The Tcpdump Group

This software is intended to be used as a practical example and 
demonstration of the libpcap library; available at:
http://www.tcpdump.org/

<hr/>

This software is a modification of Tim Carstens' "sniffer.c"
demonstration source code, released as follows:

sniffer.c
Copyright (c) 2002 Tim Carstens
2002-01-07
Demonstration of using libpcap
timcarst -at- yahoo -dot- com

"sniffer.c" is distributed under these terms:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
4. The name "Tim Carstens" may not be used to endorse or promote
   products derived from this software without prior written permission

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
\<end of "sniffer.c" terms>

This software, "sniffex.c", is a derivative work of "sniffer.c" and is
covered by the following terms:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Because this is a derivative work, you must comply with the "sniffer.c"
   terms reproduced above.
2. Redistributions of source code must retain the Tcpdump Group copyright
   notice at the top of this source file, this list of conditions and the
   following disclaimer.
3. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
4. The names "tcpdump" or "libpcap" may not be used to endorse or promote
   products derived from this software without prior written permission.

THERE IS ABSOLUTELY NO WARRANTY FOR THIS PROGRAM.
BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.
\<end of "sniffex.c" terms>
<hr/>
