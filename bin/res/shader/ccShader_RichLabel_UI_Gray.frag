#ifdef GL_ES
precision mediump float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main(void)
{
    vec4 c = texture2D(CC_Texture0, v_texCoord);
    gl_FragColor.xyz = vec3(0.2126*v_fragmentColor.r + 0.7152*v_fragmentColor.g + 0.0722*v_fragmentColor.b);
    c = v_fragmentColor * c;
    gl_FragColor.w = c.w * 0.5;
}