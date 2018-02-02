module myip.private_;

import std.string : fromStringz;

nothrow string[] privateAddresses() {

	string[] addresses;

	version(Windows) {

		import core.sys.windows.windef;
		import core.sys.windows.winsock2;

		WORD versionRequested = MAKEWORD(1, 0);
		WSADATA wsaData;
		char[255] name;
		
		if(WSAStartup(versionRequested, &wsaData) == 0 && gethostname(name.ptr, 255) == 0) {

			addrinfo* result, ptr;

			addrinfo hints;
			hints.ai_family = AF_UNSPEC;
			hints.ai_socktype = SOCK_STREAM;
			hints.ai_protocol = IPPROTO_TCP;

			if(getaddrinfo(name.ptr, NULL, &hints, &result) == 0) {
				
				char[255] host;
				
				void add(const(sockaddr)* sa, socklen_t salen) {
					if(getnameinfo(sa, salen, host.ptr, 255, NULL, 0, NI_NUMERICHOST) == 0) {
						addresses ~= fromStringz(host.ptr).idup;
					}
				}

				for(ptr=result; ptr != NULL; ptr=ptr.ai_next) {
					switch(ptr.ai_family) {
						case AF_INET:
							add(ptr.ai_addr, sockaddr_in.sizeof);
							break;
						case AF_INET6:
							add(ptr.ai_addr, sockaddr_in6.sizeof);
							break;
						default:
							break;
					}
				}

				freeaddrinfo(result);

			}

		}

	} else version(Posix) {

		import core.sys.posix.netdb;
		import core.sys.posix.netinet.in_;

		ifaddrs* result, ptr;
		void* in_addr;

		if(getifaddrs(&result) == 0) {

			char[255] host;

			void add(const(sockaddr)* sa, socklen_t salen) {
				if(getnameinfo(sa, salen, host.ptr, 255, null, 0, NI_NUMERICHOST) == 0) {
					addresses ~= fromStringz(host.ptr).idup;
				}
			}
			
			for(ptr=result; ptr !is null; ptr=ptr.ifa_next) {
				if(ptr.ifa_addr) {
					switch(ptr.ifa_addr.sa_family) {
						case AF_INET:
							add(ptr.ifa_addr, sockaddr_in.sizeof);
							break;
						case AF_INET6:
							add(ptr.ifa_addr, sockaddr_in6.sizeof);
							break;
						default:
							continue;
					}
				}
			}

			freeifaddrs(result);
			
		}
	
	}
	
	return addresses;

}

version(Posix) {

	// https://github.com/dlang/druntime/blob/master/src/core/sys/linux/ifaddrs.d

	import core.sys.posix.sys.socket;

	extern (C):
	nothrow:
	@nogc:

	int getnameinfo(const(sockaddr)*, socklen_t, char*, socklen_t, char*, socklen_t, int);

	struct ifaddrs
	{
		/// Next item in the list
		ifaddrs*         ifa_next;
		/// Name of the interface
		char*            ifa_name;
		/// Flags from SIOCGIFFLAGS
		uint      ifa_flags;
		/// Address of interface
		sockaddr* ifa_addr;
		/// Netmask of interface
		sockaddr* ifa_netmask;
		
		union
		{
			/// Broadcast address of the interface
			sockaddr* ifu_broadaddr;
			/// Point-to-point destination addresss
			sockaddr* if_dstaddr;
		}
		
		/// Address specific data
		void* ifa_data;
	};

	/// Returns: linked list of ifaddrs structures describing interfaces
	int getifaddrs(ifaddrs** );
	/// Frees the linked list returned by getifaddrs
	void freeifaddrs(ifaddrs* );

}
