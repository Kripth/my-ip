my-ip
=====

[![DUB](https://img.shields.io/dub/v/vibe-d.svg)](https://code.dlang.org/packages/my-ip)
[![Build Status](https://travis-ci.org/Kripth/my-ip.svg?branch=master)](https://travis-ci.org/Kripth/my-ip)
[![Build status](https://ci.appveyor.com/api/projects/status/1fh826paw30wkd9s?svg=true)](https://ci.appveyor.com/project/Kripth/my-ip)

## Usage

### [Private addresses](https://en.wikipedia.org/wiki/Private_network)

An array with the private addresses, both ipv4 and ipv6, can be obtained using the `privateAddresses` function.

### [Public address](https://en.wikipedia.org/wiki/IP_address#Public_address)

The public address is retrieved from a web service throught the `publicAddress` function using a blocking socket. It returns the the ip in dot notation or an
empty string if a problem has occured.
Specific function to get either ipv4 or ipv6 can be used as `publicAddress4` and `publicAddress6`.

```
import myip;

void main(string[] args) {

	writeln("Your ipv4 is ", publicAddress4);
	
	auto ipv6 = publicAddress6;
	if(ipv6.length) {
		writeln("Your ipv6 is ", publicAddress6);
	} else {
		writeln("You don't have an ipv6");
	}

}
```
