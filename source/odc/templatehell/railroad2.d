/* railroad

my take on "railroad oirented programming" which seems a little hyped for how unused it seems it actaully is. But nullable error handling + ranges suck, taking thier function names and hoping it turns into something useful

---
v2, my suggested v1 api didnt play out
*/

/* sumtype API

get!int: assume the value is in the Nth state, cast it into that value
set!int: ^; ugh I hate getters and setters  but I think it maybe nessery
classify: returns an int for the current state
classmax: ct max+1 of what classify returns( to call switch over a static foreach)
nullish: ct bool for a "bottom" type, such states *must* be the final state and increase classmax+1, classmax-nullish should return the number of normalish states
ismarked: ? possibly nessery enum for actaully metaprograming
*/

/* function list
element:
	match- switch over sumtype
	bindthrow- take throwing function into a nullable function
	classed- make a element pretend to be a sumtype using a function
	marked- make a element pretend to be a sumtype using a int
	combine- map of classify
	bind- apply a function
---
range:
	bimap- map but its a range of sumtypes
	bifilter- filter over classify
	tee- a "track" gets redirected out
	tap- tee but not removed?
*/

/* core types

tagunion - a sumtype where classify is a ubyte, eager
smartunion-a sumtype where classify is a function that returns a ubyte, lazy

*/

/* shorthand type list

nullable - T or null
snullable- T or errory string
smallint - int or ubyte
either

*/

enum maxsizeof(T...)=12;//todo impliment after standardizing some algorthims
struct tagunion(bool hasnull,T...){
	ubyte[maxsizeof!T] data;
	ubyte classify;
	enum classmax=T.length+hasnull;
	enum nullish=hasnull;
	enum ismarked=false;
	ref S intpertivecast(S)()=>*cast(S*)(&data);
	ref get(int I)()=>intpertivecast!(T[I]);
	void set(int I)(T[I] a){intpertivecast!(T[I])=a;classify=I;}
	static if(hasnull){
		auto get(int I:T.length)()=>null;
		auto set(int I:T.length)(typeof(null)){classify=I;}
	}
}
unittest{
	
