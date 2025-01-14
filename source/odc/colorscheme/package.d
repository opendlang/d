import odc.templatehell;
import odc.raylib.raylib_types;

enum string colorcsv()=import("base-16.csv");
alias colors=Color[16];
enum colors[string] colorschemes=(){
	colors[string] o;
	foreach(row;colorcsv!().range.split!(a=>a=='\n')){
		auto row_=row.split!(a=>a==',');
		string s=row_.front.array;
		colors cs;
		int i=0;
		row_.popFront;
		foreach(c;row_){
			cs[i++]=Color(c.array);
		}
		o[s]=cs;
	}
	return o;
}();
R dup(R)(R r)=>r;
auto split(alias F,R)(R r){
	struct Split{
		R r;
		auto front()=>r.dup.takeuntil!(a=>F(a.front));
		void popFront(){r=r.find!(a=>F(a)).find!(a=> ! F(a));}
		bool empty()=>r.empty;
	}
	return Split(r.find!(a=> ! F(a)));
}
unittest{
	//colorcsv!().range.split!(a=>a=='\n').front.split!(a=>a==',').summery;
	//counter(100).split!(a=>a%10==0).summery;
}
unittest{
	//colorschemes.summery;
}
auto array(R)(R r){
	typeof(r.front())[] o;//TODO:
	foreach(e;r){
		o~=e;
	}
	return o;
}
alias currentcolorscheme_()=innate!(string,"solarized-dark","color123");
void currentcolorscheme()(string s){currentcolorscheme_=s;}
auto currentcolorscheme()()=>colorschemes[currentcolorscheme_!()];
