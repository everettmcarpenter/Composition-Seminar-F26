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

LFO alphaMod( 0.2601 );
LFO betaMod( 0.00261 );
LFO alpha( 0.054 );
LFO beta( 0.176 );

// coeff
1.4 => float a;
0.31 => float b;
5000 => int NUM_POINTS;
4.0 => float XBOUNDARY;
4.0 => float YBOUNDARY;

// sine
Step st[8] => Gain scale( 0.5 )[2] => ResonZ filter[16] => Distort dirt[filter.size()] => Gain volume( 1.0 / ( filter.size() * 0.5 ) )[2] => dac;
dirt => DelayL delay( 80::ms )[filter.size()] => Gain feed( 0.36 )[filter.size()] => filter;
volume => LPF lo( 100.0, 1.0 )[2] => Gain loGain( 0.5 )[2] => dac;

for( int i; i < filter.size(); i++ )
{
	filter[i].set( ( i + 1 ) * ( 1000.0 / filter.size() ), 4.0 );
	dirt[i].mode( 3 );
	delay[i].delay( ( Math.random2f( 0.5, 10.0 ) + ( i + 1 ) ) * 5::ms );
}

// stretch
1.0 => float xStretch;
1.0 => float yStretch;
// colors of points
[ Color.BLACK ] @=> vec3 colors[];
// size of points
[ 0.5 ] @=> float sizes[];
//
vec3 pos[];

henon( a, b ) @=> pos;

// put them somewhere 
points.positions( pos );
// color
points.colors( colors );
// size
points.sizes( sizes );
// look at me
points.billboard( 1 );

spork ~
   mouseShred();

spork ~ 
    stepper();

while( true )
{
    GG.nextFrame() => now;
    0.5 * alphaMod.tick() * ( alpha.tick() + 2.0 * 0.30 ) => float modA;
    0.7 * betaMod.tick() * ( beta.tick() + 1.7 * 0.25  ) => float modB;
    henon( modA, modB ) @=> pos;
    points.positions( pos );
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
        positions << @( x , y , Math.cos( y * x ) );
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

fun void stepper()
{
    int i;
    while( true )
    {
    	pos[i].magnitude() => float mag;
        // wrap
        if( mag > 1.0 || mag < -1.0 )
            Math.sin( mag ) => mag;
        // set 
        st[i % 2].next( mag );
        // increment wrap around
        ++i % pos.size() => i;
        1::samp => now;
    }
}
