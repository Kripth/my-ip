module app;

import std.algorithm : canFind;
import std.json : JSONValue;
import std.stdio : writeln;

import myip;

void main(string[] args) {

	bool public_ = args.canFind("--public");
	bool private_ = args.canFind("--private");
	bool v4 = args.canFind("--4");
	bool v6 = args.canFind("--6");
	
	void addImpl(ref JSONValue[string] json, string[] keys, JSONValue value) {
		if(keys.length == 1) json[keys[0]] = value;
		else {
			if(keys[0] !in json) json[keys[0]] = (JSONValue[string]).init;
			addImpl(json[keys[0]].object, keys[1..$], value);
		}
	}
	
	JSONValue[string] json;
	
	void add(T)(T value, string[] keys...) {
		addImpl(json, keys, JSONValue(value));
	}
	
	if(private_ || !public_) {
	
		if(v4 || !v6) add(privateAddresses4(), "private", "v4");
		if(v6 || !v4) add(privateAddresses6(!args.canFind("--interface")), "private", "v6");
		
	}
	
	if(public_ || !private_) {
		
		if(args.canFind("--all")) {
		
			foreach(member ; __traits(allMembers, Service)) {
				mixin("alias service = Service." ~ member ~ ";");
				static if(is(typeof(service) == Service)) {
					if(v4 || !v6) add(publicAddress4(service), "public", member, "v4");
					if(v6 || !v4) add(publicAddress6(service), "public", member, "v6");
				}
			}
		
		} else {
		
			if(v4 || !v6) add(publicAddress4(), "public", "v4");
			if(v6 || !v4) add(publicAddress6(), "public", "v6");
			
		}
	
	}
	
	if(args.canFind("--pretty")) writeln(JSONValue(json).toPrettyString());
	else writeln(JSONValue(json));

}