attribute vec4 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
uniform mat4 gm_Matrices[5];
varying vec2 v_vTexcoord;
void main()
{
    gl_Position = gm_Matrices[4] * in_Position;
    v_vTexcoord = in_TextureCoord;
}
