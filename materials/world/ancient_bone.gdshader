shader_type spatial;
render_mode diffuse_burley;
uniform bool wood = false;
varying vec3 p;
float hash(vec3 v){return fract(sin(dot(v,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 v){vec3 i=floor(v),f=fract(v);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float weather=noise(p*2.3),grain=noise(p*42.0);
 float damp=(1.0-smoothstep(0.0,1.2,p.y))*smoothstep(0.25,0.7,weather);
 ALBEDO=mix(vec3(0.37,0.32,0.23),vec3(0.61,0.56,0.43),weather)*(0.88+grain*0.18);
 ALBEDO=mix(ALBEDO,vec3(0.105,0.13,0.075),damp*0.65);
 float relief=grain*0.005+weather*0.012;
 if(wood){
  float furrows=noise(p*vec3(17.0,1.4,17.0));
  ALBEDO=mix(vec3(0.055,0.045,0.035),vec3(0.18,0.16,0.125),furrows)*(0.85+grain*0.15);
  relief=furrows*0.018+grain*0.003;
 }
 vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX),r1=cross(dy,NORMAL),r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 NORMAL=normalize(abs(det)*NORMAL-sign(det)*(dFdx(relief)*r1+dFdy(relief)*r2));
 ROUGHNESS=0.94;SPECULAR=0.15;
}
