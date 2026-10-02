// spawn points
GPoints points --> GG.scene();
// eyes
GFlyCamera cam => GG.scene().camera;
// position
cam.posZ( 30 );
// color
GG.scene().backgroundColor( Color.WHITE );

// within what range
10 => int width;
// number of points
1000 => int NUM_POINTS;
// x step
0.0125 => float step;
// positions of points
vec3 positions[0];
// colors of points
[Color.BLACK] @=> vec3 colors[];
// size of points
[1.0] @=> float sizes[];

for( int i; i < NUM_POINTS; i++ )
{
    // x 
    i * step => float x;
    // point
    if( i < NUM_POINTS / 4 )
        positions << @( x , Math.sin( 2.0 * x ), 0 );
    else
        positions << @( x, 1.0 + -1*x, 0 );
}

// put them somewhere 
points.positions( positions );
// color
points.colors( colors );
// size
points.sizes( sizes );
// look at me
points.billboard( 1 );

while( true )
{
    GG.nextFrame() => now;
}