shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position=(MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_position.xz;
 vec2 blocks=p/vec2(1.7,1.1);
 blocks.x += mod(floor(blocks.y),2.0)*0.5;
 vec2 f=fract(blocks + vec2(noise(p*4.0), noise(p*4.0+9.0))*0.015);
 vec2 edge=min(f,1.0-f);
 float joint=1.0-smoothstep(0.012,0.035,min(edge.x,edge.y));
 float grain=noise(p*18.0);
 float weather=noise(p*0.28);
 float variation=hash(floor(blocks));
 vec3 stone=mix(vec3(0.23,0.235,0.205),vec3(0.37,0.36,0.31),variation);
 stone *= 0.82 + weather*0.26 + grain*0.12;
 vec3 dirt=mix(vec3(0.085,0.075,0.055),vec3(0.12,0.14,0.085),weather);
 // Broad paving joins soil beyond the court, rather than ending at a visible plane edge.
 float soil=smoothstep(38.0,65.0,length(p-vec2(-22,8))) * smoothstep(0.25,0.7,weather);
 ALBEDO=mix(mix(stone,dirt,joint*0.65),dirt,soil);
 float stain=smoothstep(0.48,0.75,noise(p*0.5)) * 0.24;
 ALBEDO *= 1.0-stain;
 float relief=(1.0-joint)*0.018 + grain*0.004;
 vec3 dx=dFdx(VERTEX), dy=dFdy(VERTEX);
 vec3 r1=cross(dy,NORMAL), r2=cross(NORMAL,dx);
 float det=dot(dx,r1);
 NORMAL=normalize(abs(det)*NORMAL-sign(det)*(dFdx(relief)*r1+dFdy(relief)*r2));
 ROUGHNESS=0.94;
 SPECULAR=0.16;
}
