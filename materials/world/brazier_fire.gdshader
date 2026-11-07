shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
void fragment(){
 float height=1.0-UV.y;
 float drift=sin(height*10.0-TIME*4.0)*0.06*height;
 float width=(1.0-height)*0.38;
 float tongues=sin(UV.x*29.0+TIME*3.1)+sin(UV.x*47.0-TIME*2.7);
 float edge=width-abs(UV.x-0.5+drift)+tongues*0.025;
 float shape=smoothstep(-.04,.06,edge)*smoothstep(0.0,.14,height)*(1.0-smoothstep(.8,1.0,height));
 vec3 color=mix(vec3(1.0,.61,.18),vec3(.8,.18,.025),height);
 ALBEDO=color;EMISSION=color*0.8;ALPHA=shape*0.72;
}
