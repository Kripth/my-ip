module myip.public_;

import std.datetime : dur;
import std.socket : Socket, SocketException, TcpSocket, Address, InternetAddress, Internet6Address, AddressFamily, SocketOption, SocketOptionLevel;
import std.string : indexOf, strip;

struct Service {

	enum ipify = Service("api.ipify.org", "/");							/// https://www.ipify.org/
	enum plain_text_ip = Service("plain-text-ip.com", "/");				/// http://about.plain-text-ip.com/
	enum icanhazip = Service("icanhazip.com", "/");						/// http://icanhazip.com/
	enum whatismyipaddress = Service("bot.whatismyipaddress.com", "/");	/// https://whatismyipaddress.com/api
	enum amazonws = Service("checkip.amazonaws.com", "/");				/// http://checkip.amazonaws.com/

	string host;
	string path;

}

private enum empty = "";

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
				return empty;
		}
	} catch(SocketException) {
		// failed to resolve hostname
		return empty;
	}

	Socket socket = new TcpSocket(addressFamily);
	socket.blocking = true;
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	try socket.connect(address);
	catch(SocketException) return empty;

	if(socket.send("GET " ~ service.path ~ " HTTP/1.1\r\nHost: " ~ service.host ~ "\r\nAccept: text/plain\r\n\r\n") != Socket.ERROR) {
	
		char[512] buffer;
		auto recv = socket.receive(buffer);
		socket.close();

		if(recv != Socket.ERROR) {

			immutable bodyStart = buffer.indexOf("\r\n\r\n") + 4;
			
			if(bodyStart < recv) return buffer[bodyStart..recv].idup.strip;

		}

	}

	return empty;

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
