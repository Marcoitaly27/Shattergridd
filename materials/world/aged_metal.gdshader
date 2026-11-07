shader_type spatial;
varying vec3 p;
uniform bool bronze = false;
float hash(vec3 v){return fract(sin(dot(v,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 v){vec3 i=floor(v),f=fract(v);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){p=VERTEX;}
void fragment(){
 float wear=noise(p*7.0),grain=noise(p*90.0);
 vec3 base=bronze ? vec3(0.34,0.24,0.115) : vec3(0.065,0.06,0.05);
 vec3 oxide=bronze ? vec3(0.08,0.145,0.115) : vec3(0.15,0.075,0.032);
 ALBEDO=mix(base,oxide,smoothstep(0.4,0.72,wear)*0.5)*(0.85+grain*.2);
 METALLIC=bronze ? 0.65 : 0.7;ROUGHNESS=0.78+wear*.18;SPECULAR=.25;
}
