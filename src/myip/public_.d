module myip.public_;

import std.datetime : Clock, dur;
import std.file : tempDir, exists, isFile, read, write;
import std.path : buildPath;
import std.socket : Socket, SocketException, TcpSocket, Address, InternetAddress, Internet6Address, AddressFamily, SocketOption, SocketOptionLevel;
import std.string : indexOf, strip;

private immutable string cache;

shared static this() {
	cache = buildPath(tempDir(), ".dub.my-ip");
}

struct Service {

	enum ipify = Service("api.ipify.org", "/");							/// https://www.ipify.org/
	enum plain_text_ip = Service("plain-text-ip.com", "/");				/// http://about.plain-text-ip.com/
	enum icanhazip = Service("icanhazip.com", "/");						/// http://icanhazip.com/
	enum whatismyipaddress = Service("bot.whatismyipaddress.com", "/");	/// https://whatismyipaddress.com/api
	enum amazonws = Service("checkip.amazonaws.com", "/");				/// http://checkip.amazonaws.com/

	string host;
	string path;

}

@safe string publicAddressImpl(Service service, AddressFamily addressFamily) {

	Address address = {
		switch(addressFamily) {
			case AddressFamily.INET: return cast(Address)new InternetAddress(service.host, 80);
			case AddressFamily.INET6: return cast(Address)new Internet6Address(service.host, 80);
			default: throw new SocketException("Invalid address family");
		}
	}();

	Socket socket = new TcpSocket(addressFamily);
	socket.blocking = true;
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	socket.setOption(SocketOptionLevel.SOCKET, SocketOption.SNDTIMEO, dur!"seconds"(5));
	socket.connect(address);
	scope(exit) socket.close();

	if(socket.send("GET " ~ service.path ~ " HTTP/1.1\r\nHost: " ~ service.host ~ "\r\nAccept: text/plain\r\n\r\n") != Socket.ERROR) {
	
		char[] buffer = new char[512];
		ptrdiff_t recv, body_;

		if((recv = socket.receive(buffer)) != Socket.ERROR && (body_ = buffer[0..recv].indexOf("\r\n\r\n")) != -1) return buffer[body_+4..recv].idup.strip;

	}

	throw new SocketException("Could not send or receive data");

}

@trusted string publicAddress(Service service=Service.ipify, AddressFamily addressFamily=AddressFamily.INET) {
	if(exists(cache) && isFile(cache)) {
		void[] data = read(cache);
		if(data.length > 4) {
			if((cast(int[])data[0..4])[0] + 60 * 60 > Clock.currTime.toUnixTime!int) {
				// cached less that one hour ago
				return cast(string)data[4..$];
			}
		}
	}
	try {
		string ret = publicAddressImpl(service, addressFamily);
		write(cache, cast(void[])[Clock.currTime.toUnixTime!int] ~ cast(void[])ret);
		return ret;
	} catch(SocketException) {
		return "";
	}
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
