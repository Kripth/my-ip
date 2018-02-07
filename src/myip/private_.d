module myip.private_;

import std.string : fromStringz;

version(Windows) {
	
	import core.sys.windows.windef;
	import core.sys.windows.winsock2;

} else version(Posix) {

	import core.sys.posix.netdb;
	import core.sys.posix.netinet.in_;
	import core.sys.posix.sys.socket;

}

/**
 * Gets the private ip address of the machine.
 */
nothrow string[] privateAddresses() {

	string[] addresses;

	char[64] ip;

	nothrow string add(const(sockaddr)* sa, socklen_t salen) {
		getnameinfo(sa, salen, ip.ptr, 64, null, 0, NI_NUMERICHOST);
		return fromStringz(ip.ptr).idup;
	}

	nothrow void add4(const(sockaddr)* sa) {
		addresses ~= add(sa, sockaddr_in.sizeof);
	}

	nothrow void add6(const(sockaddr)* sa) {
		addresses ~= add(sa, sockaddr_in6.sizeof);
	}

	version(Windows) {

		WORD versionRequested = MAKEWORD(1, 0);
		WSADATA wsaData;
		char[255] name;
		
		if(WSAStartup(versionRequested, &wsaData) == 0 && gethostname(name.ptr, 255) == 0) {

			addrinfo* result, ptr;

			addrinfo hints;
			hints.ai_family = AF_UNSPEC;
			hints.ai_socktype = SOCK_STREAM;
			hints.ai_protocol = IPPROTO_TCP;

			if(getaddrinfo(name.ptr, null, &hints, &result) == 0) {

				for(ptr=result; ptr !is null; ptr=ptr.ai_next) {
					switch(ptr.ai_family) {
						case AF_INET:
							add4(ptr.ai_addr);
							break;
						case AF_INET6:
							add6(ptr.ai_addr);
							break;
						default:
							break;
					}
				}

				freeaddrinfo(result);

			}

		}

	} else version(Posix) {

		ifaddrs* ifap, ifa;
		void* in_addr;

		if(getifaddrs(&ifap) == 0) {

			for(ifa=ifap; ifa; ifa=ifa.ifa_next) {
				if(ifa.ifa_addr && (ifa.ifa_flags & 2)) {
					switch(ifa.ifa_addr.sa_family) {
						case AF_INET:
							add4(ifa.ifa_addr);
							break;
						case AF_INET6:
							add6(ifa.ifa_addr);
							break;
						default:
							continue;
					}
				}
			}

			freeifaddrs(ifap);
			
		}
	
	}
	
	return addresses;

}

version(Posix) {

	extern (C):
	nothrow:
	@nogc:

	struct ifaddrs {

		ifaddrs* ifa_next;
		char* ifa_name;
		uint ifa_flags;
		sockaddr* ifa_addr;
		sockaddr* ifa_netmask;
		
		union {

			sockaddr* ifu_broadaddr;
			sockaddr* ifu_dstaddr;

		}

		void* ifa_data;

	}

	int getifaddrs(ifaddrs**);
	void freeifaddrs(ifaddrs*);
	
	int getnameinfo(const(sockaddr)*, socklen_t, char*, socklen_t, char*, socklen_t, int);

}

unittest {

	import std.stdio : writeln;
	writeln(privateAddresses);

}
