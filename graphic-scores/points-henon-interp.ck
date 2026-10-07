/*

	TODO: Investigate sampling the map at a rate slower than GG.nextFrame() => now
		  this way we save computation time and then we simply interpolate to the 
		  sampled points. This could potentially allow us to have more points.

*/

public class LFO
{
    1.0 => float freq; // normalized
    float increment; // step size
    float phase; // current val
    60.0 => float fs;
 
    fun @construct( float nFreq )
    {
        nFreq => freq;
        ( freq / fs ) * 2.0 * Math.pi => increment;
    }

    fun float tick() 
    {
        increment +=> phase;

        if( phase >= 2.0 * Math.pi )
            phase - ( 2.0 * Math.pi ) => phase;
        else if( phase <= -2.0 * Math.pi )
            phase + ( 2.0 * Math.pi ) => phase;

        return Math.sin( phase );
    }
}

// mouse
Hid mouse;
HidMsg mmsg;

// spawn points
GPoints points --> GG.scene();
// eyes
GOrbitCamera cam => GG.scene().camera;
// position
cam.posZ( 10 );
// color
GG.scene().backgroundColor( Color.WHITE );
// GWindow.mouseMode( GWindow.MOUSE_DISABLED );
GWindow.fullscreen();

LFO alphaMod( 0.002601 );
LFO betaMod( 0.00261 );

// coeff
1.4 => float a;
0.31 => float b;
50000 => int NUM_POINTS;
GG.windowWidth() => float XBOUNDARY;
GG.windowHeight() => float YBOUNDARY;

// stretch
1.0 => float xStretch;
1.0 => float yStretch;
// colors of points
[Color.BLACK] @=> vec3 colors[];
// size of points
[1.0] @=> float sizes[];

// put them somewhere 
points.positions( henon( a, b ) );
// color
points.colors( colors );
// size
points.sizes( sizes );
// look at me
points.billboard( 1 );

spork ~
   mouseShred();

while( true )
{
    GG.nextFrame() => now;
    

    2.5 * alphaMod.tick() * a => float modA;
    2.5 * betaMod.tick() * b => float modB;
    points.positions( henon( modA, modB ) );
}

fun vec3[] henon( float alpha, float beta )
{
    vec3 positions[1];
    for( int i; i <= NUM_POINTS; i++ )
    {
        // x 
        ( positions[i].y  + 1.0 - alpha * ( positions[i].x * positions[i].x ) ) * xStretch => float x;
        ( beta * positions[i].x ) * yStretch => float y;
        if( x >= XBOUNDARY || x <= -XBOUNDARY )
            Math.cos( x ) => x;
        if( y >= YBOUNDARY || y <= -YBOUNDARY )
            Math.sin( y ) => y;
        
        // point
        positions << @( x , y , 0 );
    }
    return positions;
}

fun void mouseShred()
{
	// open mouse 0, exit on fail
	if( !mouse.openMouse( 0 ) ) me.exit();
	<<< "mouse '" + mouse.name() + "' ready", "" >>>;

	while( true )
	{
		mouse => now;
		while( mouse.recv( mmsg ) )
		{
		 	if( mmsg.isMouseMotion() )
		 	{
		 		Std.scalef( mmsg.scaledCursorX, 0.0, 1.0, 0.1, 2.0 ) => a;	
                Std.scalef( 1.0 - mmsg.scaledCursorY, 0.0, 1.0, 0.1, 1.4 ) => b;
		 	}
		}
		1024::samp => now; 
	}
}
