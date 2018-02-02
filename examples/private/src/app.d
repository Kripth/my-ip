module app;

import std.stdio : writeln;
import std.string : join;

import myip.private_;

void main() {

	writeln("Private addresses: ", privateAddresses.join(", "));

}
