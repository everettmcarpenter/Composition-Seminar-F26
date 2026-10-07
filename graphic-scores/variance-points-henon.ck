/*

	TODO: Investigate sampling the map at a rate slower than GG.nextFrame() => now
		  this way we save computation time and then we simply interpolate to the 
		  sampled points. This could potentially allow us to have more points.

*/

@import "Line"

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
// GWindow.fullscreen();

LFO alphaMod( 0.002601 );
LFO betaMod( 0.00261 );
LFO alpha( 0.00245 );
LFO beta( 0.00876 );

// coeff
1.4 => float a;
0.31 => float b;
200 => int NUM_POINTS;
4.0 => float XBOUNDARY;
4.0 => float YBOUNDARY;
float VARIANCE;
second / samp => float srate;

// sine
SinOsc sines[ NUM_POINTS ] => Envelope env( 0.0 )[ NUM_POINTS ] => dac;
Line pitchSlew[ NUM_POINTS ] => blackhole;

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
	soundUpdate();

spork ~
	interpolateFreq();

while( true )
{
    GG.nextFrame() => now;
    // modulate
    0.5 * alphaMod.tick() * ( alpha.tick() + 2.0 * 1.0 ) => float modA;
    0.7 * betaMod.tick() * ( beta.tick() + 1.7 * 1.5  ) => float modB;
    // calculate points
    henon( modA, modB ) @=> pos;
    // place points
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

fun void soundUpdate()
{
	100::ms => dur rate;
	while( true )
	{	
		// variance
	    float sum;
	    // pop mean
	    for( int i; i < pos.size(); i++ )
	        pos[i].magnitude() +=> sum;
	    // divide
	    sum / pos.size() => sum;
	    // variance
	    for( int j; j < pos.size(); j++ )
	        ( pos[j].magnitude() - sum ) * ( pos[j].magnitude() - sum ) => VARIANCE;
	    // divide again
	    VARIANCE => VARIANCE;
		// rate
		if( VARIANCE > 1.0 )
			700::ms => rate;
	    // osc
	    for( int o; o < sines.size(); o++ )
	    {
	        // save 
	        pos[o].magnitude() => float mag;
	        // wrap
	        if( mag > 1.0 || mag < -1.0 )
	            env[o].ramp( rate, Math.sin( mag ) / sines.size() );
	        else
	            env[o].ramp( rate, mag / sines.size() );
	        // freq
	        o * VARIANCE => float multiplier;
	        if( multiplier > 1.0 )
	        	Math.cos( multiplier ) => multiplier;
	       	// square
	        multiplier * multiplier => multiplier;
        	pitchSlew[o].keyOn( multiplier * ( srate * 0.1125 ), rate * 2.0 );
	    }
	    rate => now;
	}
}

fun void interpolateFreq()
{
	while( true )
	{
		for( int i; i < NUM_POINTS; i++ )
		{
			pitchSlew[i].last() => sines[i].freq;
			pitchSlew[i].last() * Math.pi * 2.0 => sines[i].phase;
		}
		256::samp => now;
	}
}
