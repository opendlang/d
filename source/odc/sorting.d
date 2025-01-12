import algorithm;

void swap(T)(T[] a,T[] b){
	if(a.length==0||b.length==0){return;}
	T c=a[0];
	a[0]=b[0];
	b[0]=c;
}
bool cmp(T)(T[] a,T[] b){
	if(a.length==0||b.length==0){return false;}
	return a[0]>b[0];
}

void bubblesortarray(T)(T[] a){
	if(a.length==0){return;}
	foreach(b;a[1..$].slide){
		if(cmp(a,b)){
			swap(a,b);
	}}
	bubblesortarray(a[1..$]);
}
unittest{
	int[] foo=[1,4,2,3,5,7];
	foo.bubblesortarray;
	import std;
	foo.writeln;
}
ref realfront(R)(R r)=>(*r.data)[r.key];
void swapfront(R)(R r1,R r2){
	if(r1.empty||r2.empty){return;}
	auto t=r1.realfront;
	r1.realfront=r2.realfront;
	r2.realfront=t;
}
bool cmpfront(R)(R r1,R r2){
	if(r1.empty||r2.empty){return false;}
	return r1.front>r2.front;
}
void bubblesort(R)(R r){
	if(r.empty){return;}
	auto r2=r.slide;
	r2.popFront;
	foreach(r3;r2){
		if(cmpfront(r,r3)){
			swapfront(r,r3);
	}}
	r.popFront;
	r.bubblesort;
}
unittest{
	int[] foo=[1,4,2,3,5,7];
	foo.range.bubblesort;
	import std;
	foo.writeln;
}
unittest{
	int[] foo=[1,-4,2,-3,-5,7];
	foo.range.map!(a=>a*a).bubblesort;
	import std;
	foo.writeln;
}
unittest{
	int[] foo=[1,3,4,3,2,3,5,7];
	foo.range.filter!(a=>a!=3).bubblesort;
	import std;
	foo.writeln;
}
auto zip(R1,R2)(R1 r1,R2 r2){//CONSIDER: how long can I delay making this nthdegree 
	//CONSIDER: can this be the offical zip or does sorting need a seperate one?
	struct Zip{
		import meta;
		R1 r1;
		R2 r2;
		auto front()=>tuple(r1.front,r2.front);
		void popFront(){r1.popFront;r2.popFront;}
		bool empty()=>r1.empty||r2.empty;
		auto key()(){
			static assert(is(typeof(r1.key())==typeof(r2.key())));
			assert(r1.key==r2.key,"unsynced keys");
			return r1.key;
		}
		auto data()(){
			
	}
	return Zip(r1,r2);
}
unittest{
	string[] foo=["hello","bye","foobar"];
	int[] bar=[1,3,2];
	auto foobar=zip(foo.range,bar.range);
	//foobar.bubblesort;
	foobar.summery;
}
	
