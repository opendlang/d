#!opend -run
import odc.templatehell;
import odc.raylib;
import odc.colorscheme;
maxlengtharray!(Rectangle,8) data;

void main(){
	InitWindow(800, 640, "raylib");
	SetTargetFPS(60);
	import std;
	//colorcsv!().writeln;
	while (!WindowShouldClose()){
		BeginDrawing();
		ClearBackground(BLACK);
		foreach(r;data[]){
			DrawRectangleRec(r,RED);
		}
		if(IsMouseButtonPressed(0)){
			data~=Rectangle(GetMouseX,GetMouseY,30,30);
		}
		EndDrawing();
	}
	CloseWindow();
}
