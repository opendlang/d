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

