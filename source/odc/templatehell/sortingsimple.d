/*
simple versions of sorting algorthims so I dont need to do it all at once

*/
module odc.templatehell.sortingsimple;

import odc.templatehell.algorithm;
import odc.templatehell.datastructures;

void swap(T)(ref T a,ref T b){
	T c=a;
	a=b;
	b=c;
}
auto dupdrop(R)(R r,int i){
	r.drop(i);
	return r;
}
void bubblesort(T)(T r){
	while( ! r.empty){
		foreach(ref e;r.dupdrop(1)){
			if(e<r.front){
				swap(e,r.front);
		}}
		r.popFront;
}}

unittest{
	ringarray!(int,10) foo;
	foo~=4;
	foo~=9;
	foo~=7;
	foo~=1;
	foo[].bubblesort;
	foo.remove(1);
	foo[].backwards.bubblesort;
	//foo[].summery;
	foo.remove;
	foo~=16;
	foo[].bubblesort;
	//foo[].summery;
}

void classsort(R,A...)(R r,ref A arrays){
	foreach(e;r){
		lable: switch(e.classify){
		static foreach(I;0..A.length){
			case I: arrays[I]~=e.get!I;break lable;
		}
		default: assert(0);
}}}
unittest{
	struct smallint{
		int i;
		int classify()=>i<=ubyte.max && i>=0;
		enum classmax=2;
		ubyte get(int zzz:1)()=>cast(ubyte)i;
		alias get(int zzz:0)=i;
	}
	stack!int foo;
	ubyte[] bar;
	counter(5).map!(a=>smallint(a*100)).classsort(foo,bar);
	//foo.summery;
	//bar.summery;
}
