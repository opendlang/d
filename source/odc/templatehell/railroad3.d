/* i dum, vry smol brin

I cant make progress on railraod2

discarding nullable, till I can make a tagged null act well with ranges

tagunion
	match - apply list a functions
	bind - apply a function returning a tagged union
	apply- apply a function the lazests way possible hoping it werks
	route- map over classify (int=>int ctfe)
	part - sumtypeify a element
	tee - handle/filter a typecase from a range of taggedunions
	tap - "dupicate" a typecase from a range of taggedunions
*/
alias seq(T__...)=T__;
alias val(alias v)=v;
template repeat(int i,alias A){
	alias repeat=seq!();
	static foreach(I;0..i){
		repeat=seq!(repeat,A);
}}
template returntypes(A...){
	alias returntypes=seq!();
	static foreach(int I;0..A.length/2){
		returntypes=seq!(returntypes,typeof(A[I](A[I+$/2]())));
	}
}
unittest{
	import std;
	returntypes!(a=>13.37/a,a=>13.37/a,a=>a,a=>a,int,float,int,float).stringof.writeln;
}
enum maxsizeof(T...)=24;//todo impliment after standardizing some algorthims
struct tagunion(T...){
	ubyte[maxsizeof!T] data;
	ubyte classify;
	enum classmax=T.length;
	ref S intpertivecast(S)()=>*cast(S*)(&data);
	ref get(int I)()=>intpertivecast!(T[I]);
	//void set(int I)(T[I] a){intpertivecast!(T[I])=a;classify=I;}
	void get(int I)(T[I] a){intpertivecast!(T[I])=a;classify=I;}
}
template match(F...){
auto match(T...)(tagunion!T t){
	tagunion!(returntypes!(F,T[0..F.length])) o;
	switch(t.classify){
		static foreach(int I;0..t.classmax){
			case I: o.get!I=F[I](t.get!I); return o;
		}
	default: assert(0);
}}}
unittest{
	import std;
	tagunion!(int,int) foo;
	foo.get!0=3;
	foo.match!(a=>a/2.0,a=>a*2).apply!writeln;
	foo.get!1.writeln;
}

template routetype(alias F,T...){
	template groupby(int J){
		alias groupby=seq!();
		static foreach(I,A;T){
			static if(F(I)==J){
				groupby=seq!(groupby,A);
	}}}
	//---
	alias max=val!(0);
	static foreach(I,a;T){
		max=val!(groupby!I.length>0?I:max);
	}
	alias S=seq!();
	static foreach(int I;0..max+1){
		S=seq!(S,groupby!I[0]);
	}
	alias routetype=tagunion!S;
}
routetype!(F,T) route(alias F,T...)(tagunion!T t){
	alias O=routetype!(F,T);
	O o;
	switch(t.classify){
		static foreach(int I;0..t.classmax){
			static if(F(I)>=0){
				case I:o.get!(F(I))=t.get!I; return o;
		}}
		default: assert(0);
	}
}
auto bind(alias F,T...)(tagunion!T t){
	tagunion!(returntypes!(repeat!(t.classmax,F),T)) o;
	switch(t.classify){
		static foreach(I;0..t.classmax){
			case I: o.get!I F(t.get!I); return o;
		}
		default: assert(0);
}}
auto apply(alias F,T...)(tagunion!T t){
	switch(t.classify){
		static foreach(I;0..t.classmax){
			case I: return F(t.get!I);
		}
		default: assert(0);
}}
unittest{
	import std;
	tagunion!(int,int,float,float,bool,bool) foo;
	foo.get!3=13.37;
	foo.route!(a=>a/2).apply!writeln;
	foo.get!4=true;
	foo.route!(a=>a/2).apply!writeln;
	auto bar=foo.route!(a=>a/2);
	bar.route!(a=>a-2).apply!writeln;
	typeof(bar.route!(a=>a-2)).stringof.writeln;
	//foo.get!1.writeln;
}
auto part(alias F,int max,T)(T t){
	tagunion!(repeat!(max,T)) o;
	o.get!0=t;
	o.classify=cast(ubyte)F(t);
	return o;
}
unittest{
	//import std;
	//auto fizzbuzz(int i)=>
	//	i.part!(a=>(a%3==0)+2*(a%5==0),4)
	//	.match!(
	//		a=>a.to!string,
	//		a=>"fizz",
	//		a=>"buzz",
	//		a=>"fizzbuzz");
	//foreach(i;0..20){
	//	fizzbuzz(i).apply!(a=>a.dup).writeln;
	//}
}
auto tap(int I,alias F,R,A...)(R r,A args){
	struct Tap{
		R r;
		A args;
		bool cashe=false;
		auto ref front(){
			if( ! cashe){
				cashe=true;
				if(r.front.classify==I){
					F(r.front.get!I,args);
			}}
			return r.front;
		}
		void popFront(){
			r.popFront;
			cashe=false;
		}
		bool empty()=>r.empty;
	}
	return Tap(r,args);
}
unittest{
	import std;
	//iota(20).map!(a=>a.part!(a=>(a%3==0)+2*(a%5==0),4))
	//	.tap!(0,a=>a.write)
	//	.each!(a=>["","fizz","buzz","fizzbuzz"][a.classify].writeln);
}
auto tee(int I,alias F,R,A...)(R r, A args){
	struct Tee{
		R r;
		A args;
		bool cache=false;
		void __find(){
			if(cache){return;}
			while( ! r.empty && r.front.classify==I){
				F(r.front.get!I,args);
				r.popFront;
		}}
		auto front(){
			__find;
			return r.front.route!(a=>a==I?-1:(a-(a>I)));
		}
		void popFront(){
			__find;
			r.popFront;
		}
		bool empty(){
			__find;
			return r.empty;
		}
	}
	return Tee(r,args);
}
unittest{
	import std;
	//iota(20).map!(a=>a.part!(a=>(a%3==0)+2*(a%5==0),4))
	//	.tee!(1,a=>"fizz".writeln)
	//	.tee!(1,a=>"buzz".writeln)
	//	.tee!(1,a=>"fizzbuzz".writeln)
	//	.each!(a=>a.writeln);
	iota(20).map!(a=>a.part!(a=>(a%3==0)+2*(a%5==0),4))
		.tee!(0,writeln)
		.each!(a=>["fizz","buzz","fizzbuzz"][a.classify].writeln);
}
