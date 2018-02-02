module app;

import std.datetime : StopWatch;
import std.stdio : writeln;

import myip.public_;

void main() {

	StopWatch timing;
	
	auto peek() {
		auto ret = timing.peek.msecs;
		timing.stop();
		timing.reset();
		return ret;
	}

	foreach(member ; __traits(allMembers, Service)) {
		mixin("alias service = Service." ~ member ~ ";");
		static if(is(typeof(service) == Service)) {
			timing.start();
			writeln("Public address using ", member, " (ipv4): ", publicAddress4(service), " in ", peek(), " ms");
			timing.start();
			writeln("Public address using ", member, " (ipv6): ", publicAddress6(service), " in ", peek(), " ms");
		}
	}

}
