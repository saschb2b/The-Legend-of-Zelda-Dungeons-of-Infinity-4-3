PixelRender(true,true,false,noone,0,false,[]);
draw_sprite(sClawMachine_Window,clamp(5-Prizes,0,5),x+3,y+14);
var claw_x = x+2+ClawX;
var claw_y = y+14;
if (Win && (State == 5 || State == 6)) draw_sprite(sClawMachine_Item,0,claw_x+1.5,claw_y+ClawY+5+DropItemY);
draw_sprite_stretched(sClawMachine_Claw,ClawImg,claw_x,claw_y,9,8+ClawY);
draw_self();
shader_reset();
