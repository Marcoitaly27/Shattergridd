shader_type spatial;
uniform vec3 tint = vec3(0.26,0.25,0.21);
varying vec3 p;
float hash(vec2 v){return fract(sin(dot(v,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 v){vec2 i=floor(v),f=fract(v);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float dirt=noise(p.xz*1.6),grain=noise(p.xz*95.0);
 ALBEDO=mix(tint,vec3(.22,.21,.16),smoothstep(.25,.8,dirt)*.4)*(.9+grain*.1);
 ROUGHNESS=.98;SPECULAR=.12;
}
