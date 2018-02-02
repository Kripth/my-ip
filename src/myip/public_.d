module myip.public_;

import std.datetime : dur;
import std.socket : Socket, SocketException, TcpSocket, Address, InternetAddress, Internet6Address, AddressFamily, SocketOption, SocketOptionLevel;
import std.string : indexOf;

struct Service {

	enum ipify = Service("api.ipify.org", "/");

	string host;
	string path;

}

@safe string publicAddress(Service service=Service.ipify, AddressFamily addressFamily=AddressFamily.INET) {

	Address address;
	try {
		switch(addressFamily) {
			case AddressFamily.INET:
				address = new InternetAddress(service.host, 80);
				break;
			case AddressFamily.INET6:
				address = new Internet6Address(service.host, 80);
				break;
			default:
				// unsupported address family
				return "";
		}
	} catch(SocketException) {
		// failed to resolve hostname
		return "";
	}

	Socket socket = new TcpSocket(addressFamily);
	socket.blocking = true;
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	socket.connect(address);

	if(socket.send("GET " ~ service.path ~ " HTTP/1.1\r\nHost: " ~ service.host ~ "\r\nAccept: text/plain\r\n\r\n") != Socket.ERROR) {
	
		char[512] buffer;
		auto recv = socket.receive(buffer);
		socket.close();

		if(recv != Socket.ERROR) {

			immutable bodyStart = buffer.indexOf("\r\n\r\n") + 4;
			
			if(bodyStart < recv) return buffer[bodyStart..recv].idup;

		}

	}

	return "";

}

@safe string publicAddress(AddressFamily addressFamily) {
	return publicAddress(addressFamily);
}

@safe string publicAddress4(Service service=Service.ipify) {
	return publicAddress(service, AddressFamily.INET);
}

@safe string publicAddress6(Service service=Service.ipify) {
	return publicAddress(service, AddressFamily.INET6);
}

unittest {

	import std.stdio;
	writeln(publicAddress4());
	writeln(publicAddress6());

}
