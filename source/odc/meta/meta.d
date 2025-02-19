module odc.templatehell.meta;
//TODO: copy and pasted from datastructures, probaly broke stuff
alias seq(T...)=T;
struct Tuple(T...){
	enum istuple=true;
	T expand; alias expand this;
}
auto tuple(T...)(T args){
	return Tuple!T(args);
}
unittest{
	auto foo=tuple(1,"hi");
	assert(foo[0]==1);
	assert(foo[1]=="hi");
	auto bar=tuple();
}
auto totuple(T)(T a) if(is(typeof(a.istuple)))=>a;
auto totuple(T)(T a) if( ! is(typeof(a.istuple)))=>tuple(a);
auto maybetuple(T...)(T a){
	static if(T.length==1){
		return a[0];
	} else {
		return tuple(a);
}}
enum istuple(T)=is(typeof(T.istuple));
unittest{
	assert(istuple!(typeof(tuple(1,2)))==true);
	assert(istuple!int==false);
}

template innate(T,T startingvalue=T.init,discrimination...){
	T innate=startingvalue;
}
