/* railroad

my take on "railroad oirented programming" which seems a little hyped for how unused it seems it actaully is. But nullable error handling + ranges suck, taking thier function names and hoping it turns into something useful

*/

/* sumtype API

get!int: assume the value is in the Nth state, cast it into that value
classify: returns an int for the current state
classmax: the max+1 of what classify returns( to call switch over a static foreach)
bind- apply a function to the sumtype
*/

/* function list
element:
	match- switch over sumtype
	bindthrow- take throwing function into a nullable function
	classed- make a element pretend to be a sumtype using a function
	marked- make a element pretend to be a sumtype using a int
	combine- map of classify
---
range:
	bimap- map but its a range of sumtypes
	bifilter- filter over classify
	tee- a "track" gets redirected out
	tap- tee but not removed?
*/

/* type list

nullable - T or null
snullable- T or errory string
either(maybe) T or S
smallint - errory int or ubyte
tunion - my name for whatever sumtype

*/
struct nullable(T){//todo op overloads
	T get_; alias get_ this;
	bool isnull=true;
	int classify()=>isnull;
	enum classmax=2;
	alias get(int i=0)=get_;
	enum iserror(int i:0)=false;
	enum iserror(int i:1)=true;
	auto bind(alias F,A...)(A args){
		alias O=nullable!(typeof(F(get_,args)));
		if(isnull){
			static if(is(O==typeof(this))){
				return this;
			} else {
				return O();
		}}
		return O(F(get_,args),true);
	}
}
struct snullable(T){
	T get_; alias get_ this;
	string error;
	//bool isnull=false; //CONSIDER: should this still exist, maybe a property function?
	bool isnull()=>error.length==0;
	int classify()=>error.length!=0;
	enum classmax=2;
	alias get(int i:0)=get_;
	alias get(int i:1)=error;
	enum iserror(int i:0)=false;
	enum iserror(int i:1)=true;
	auto bind(alias F,string function_=__FUNCTION__,int line=__LINE__,A...)(A args){
		import std.conv;//TODO remove
		alias O=snullable!(typeof(F(get_,args)));
		if(isnull){
			static if(is(O==typeof(this))){
				return O(get_,error~function_~";("~line.to!string~")");
			} else {
				return O(O().get_.init,error~function_~";("~line.to!string~")");
		}}
		return O(F(get_,args));
	}
}
unittest{
	import std;
	nullable!int foo;
	snullable!int bar;
	alias f=a=>10/a;
	//foo.bind!f.writeln;
	//foo.get_=3;foo.isnull=false;
	//foo.bind!f.writeln;
	//bar.bind!f.error.writeln;
	//bar.get_=3;
	//bar.bind!f.writeln;
}
template match(F...){
auto match(T)(T t){
	switch(t.classify){
		static foreach(I;0..T.classmax){
			case I: return F[I](t.get!I);
		}
	default: assert(0);
}}}
//unittest{
//	import std;
//	auto bar=snullable!int(3);
//	void foo(snullable!int i)=>i.match!(writeln,writeln);
//	foo(bar);
//	bar.error="sadness";
//	foo(bar);
//}

enum maxsizeof(T...)=12;//todo impliment after standardizing some algorthims
struct tunion(T...){
	ubyte[maxsizeof!T] data;
	ubyte classify;
	enum classmax=T.length;
	ref get(int I)()=>intpertivecast!(T[I]);
	ref S intpertivecast(S)()=>*cast(S*)(&data);
	enum iserror(int I)=false;
	template bind(F...){
	auto bind(A...)(A args){
		alias O=tunion!(T[0..F.length]);//todo static map types
		switch(classify){
			static foreach(I;0..F.length){
				case I:
					O o; 
					o.classify=classify;
					o.get!I=F[I](get!I,args);
					return o;
			}
			default: assert(0,"not enough functions");
	}}}

}
//unittest{
//	import std;
//	tunion!(float) foo;
//	foo.intpertivecast!float=3.14;
//	foo.data.writeln;
//	foo.intpertivecast!float().writeln;
//	foo.data[3]=80;
//	foo.intpertivecast!float().writeln;
//	foo.get!0.writeln;
//}
//unittest{
//	import std;
//	tunion!(int,bool,float,int) foo;
//	void bar(){foo.bind!(a=>a+1,a=>!a).writeln;}
//	foo.get!0=3;
//	bar;
//	foo.classify=1;
//	foo.get!1=true;
//	bar;
//	foo.classify=2;
//	foo.get!2=3.14;
//	bar;
//}
struct Classed(T,alias F,int maxvalid,int errors=0){
	T t; alias t this;
	auto classify()=>F(t);
	enum classmax=maxvalid+errors;
	ref get(int I)()=>t;
	enum bool iserror(int I)=I<maxvalid;
}
auto classed(alias F,int maxvalid,int errors=0,T)(T t)=>Classed!(T,F,maxvalid,errors)(t);
unittest{
	int fizzbuzzclassify(int i){
		return (i%3==0)+2*(i%5==0);
	}
	Classed!(int,fizzbuzzclassify,4) i;
	//i=15;
	//import std;
	//i.classify.writeln;
}
struct Marked(T,int maxvalid,int errors=0){
	T t; alias t this;
	ubyte classify=0;
	enum classmax=maxvalid+errors;
	ref get(int I)()=>t;
	enum bool iserror(int I)=I<maxvalid;
	//this(T t) { this.t = t; } //TODO: FUCKING ALIAS THIS WAS INTENTIONAL BROKEN
	//void opAssign(T t) { this.t = t; }
}
auto marked(int maxvalid,int errors=0,T)(T t,ubyte i)=>Marked!(T,maxvalid,errors)(t,i);
//unittest{
//	import std;
//	Marked!(int,2) foo=100;
//	void bar(){
//		foo.match!(
//			(a){writeln("fizz",a);},
//			(a){writeln("buzz",a);}
//	);}
//	//foo=100;
//	//foo.classify=0;
//	bar(foo);
//	foo=10.marked(1);
//	bar(foo);
//}
//template bind(F...){//CONSIDER: is this impossible to impliment?
//auto bind(T)(T t){
//	switch(t.classify){
//		static foreach(I;0..T.classmax){
//			static if( ! T.iserror!I){
//				case I: return F[I](t.get!I);
//			} else {
//				static if(I<=F.length){
//				case I: return F[I](t.get!I);
//		}}}
//		default: assert(0);
//}}}
unittest{
	
}
