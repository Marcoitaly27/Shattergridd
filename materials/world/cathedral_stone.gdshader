shader_type spatial;
render_mode diffuse_burley;
uniform vec3 limestone : source_color = vec3(0.43,0.405,0.35);
varying vec3 stone_position;
varying vec3 stone_normal;
float hash(vec3 p){ return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p){vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
float masonry(vec2 p){float row=floor(p.y/0.62);vec2 q=vec2(p.x/1.3+mod(row,2.0)*0.5,p.y/0.62);vec2 edge=min(fract(q),1.0-fract(q));float d=min(edge.x,edge.y);float aa=max(fwidth(d),0.008);return smoothstep(0.025-aa,0.055+aa,d);}
void vertex(){stone_position=VERTEX*vec3(70.0,47.814,88.582);stone_normal=NORMAL;}
void fragment(){
 vec3 p=stone_position;
 vec3 weights=pow(abs(stone_normal),vec3(5.0)); weights/=max(dot(weights,vec3(1.0)),0.001);
 float blocks=masonry(p.zy)*weights.x+masonry(p.xy)*weights.z+weights.y;
 float broad=noise(p*0.24);float grain=noise(p*13.0);
 float damp=(1.0-smoothstep(1.0,9.0,p.y))*(0.55+0.45*broad);
 float ledge=smoothstep(0.3,0.85,stone_normal.y);
 float moss=clamp(damp*0.55+ledge*smoothstep(0.55,0.78,noise(p*0.8))*0.30,0.0,0.6);
 vec3 color=limestone*(0.73+broad*0.4+grain*0.08)*mix(0.58,1.0,blocks);
 color=mix(color,color*vec3(0.52,0.61,0.42),moss);
 ALBEDO=color*(1.0-damp*0.22);
 ROUGHNESS=clamp(0.94-damp*0.13+grain*0.04,0.75,1.0); METALLIC=0.0;SPECULAR=0.18;
 float height=blocks*0.025+grain*0.007;
 vec3 a=cross(dFdy(VERTEX),NORMAL);vec3 b=cross(NORMAL,dFdx(VERTEX));float det=dot(dFdx(VERTEX),a);
 NORMAL=normalize(NORMAL-sign(det)*(dFdx(height)*a+dFdy(height)*b)/max(abs(det),0.00001));
}
