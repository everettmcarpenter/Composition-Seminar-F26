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
    float lastSamp;
 
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

        Math.sin( phase ) => lastSamp;
        return lastSamp;
    }

    fun float last()
    {
        return lastSamp;
    }
}

// mouse
Hid mouse;
HidMsg mmsg;
Event theNotification;

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
LFO alpha( 0.00245 );
LFO beta( 0.00876 );

// coeff
1.4 => float a;
0.31 => float b;
150 => int NUM_POINTS;
4.0 => float XBOUNDARY;
4.0 => float YBOUNDARY;

// stretch
1.0 => float xStretch;
1.0 => float yStretch;
// colors of points
[Color.BLACK] @=> vec3 colors[];
// size of points
[ 0.5 ] @=> float sizes[];
// targets
vec3 targets[ NUM_POINTS ];
// current
vec3 current[];

// put them somewhere 
henon( a, b ) @=> current;
points.positions( current );
// color
points.colors( colors );
// size
points.sizes( sizes );
// look at me
points.billboard( 1 );

spork ~
    mouseShred();

spork ~
    sampler( theNotification, targets );

while( true )
{
    GG.nextFrame() => now;
    // tick
    alphaMod.tick();
    betaMod.tick();
    alpha.tick();
    beta.tick();

    lerp( current, targets, 0.25 ) @=> current;
    points.positions( current );
}

fun vec3 lerp( vec3 lhs, vec3 rhs, float d )
{
    return lhs + d * ( rhs - lhs );
}

fun vec3[] lerp( vec3 lhs[], vec3 rhs[], float d )
{
    // we output this
    vec3 out[0];
    // vectorize vectors
    for( int i; i < lhs.size(); i++ )
    {
        out << lerp( lhs[i], rhs[i], d ); // overloaded recursion? i should learn computer science
        <<< out[i] >>>;
    }
    return out;
}

fun void sampler( Event @ notif, vec3 buffer[] )
{
    while( true )
    {
        1000::ms => now;
        1.0 * alphaMod.last() * ( alpha.last() + 2.0 * 1.0 ) => float modA;
        1.0 * betaMod.last() * ( beta.last() + 1.7 * 1.5  ) => float modB;
        henon( modA, modB ) @=> buffer;
    }
}

fun vec3[] henon( float alpha, float beta )
{
    vec3 positions[1];
    for( int i; i < NUM_POINTS; i++ )
    {
        // x 
        ( positions[i].y  + 1.0 - alpha * ( positions[i].x * positions[i].x ) ) * xStretch => float x;
        ( beta * positions[i].x ) * yStretch => float y;
        if( x >= XBOUNDARY || x <= -XBOUNDARY )
            Math.cos( x ) => x;
        if( y >= YBOUNDARY || y <= -YBOUNDARY )
            Math.sin( y ) => y;

        // point
        positions << @( x , y , Math.cos( x ) * Math.sin( y ) );
    }

    // pop front since we needed a reference point
    positions.popFront();

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
