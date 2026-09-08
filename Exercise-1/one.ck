@import "Line"

8 => int num;
Collage col( "Brit-Voice-Iso.wav" )[num] => Envelope fader( 1::second )[num] => Gain scale( 0.5 )[num] => dac;
fader => Gain revSend( 0.08 )[num] => NRev reverb[num] => dac; 
Line sizeInterpolators[num] => blackhole;

spork ~ sizeLink( col, sizeInterpolators );

// init
for( int i; i < num; i++ ) 
{
	sizeInterpolators[i].keyOn( 20.0, 2::second );
	col[i].position( 1.0, col[i].duration() * 12.0 );
	col[i].spacer( 800::ms );
	1::ms => now;
}

// turn everything on
for( int i; i < num; i++ ) fader[i].keyOn();
// pass time
fader[0].duration() => now; 

1 => int one;
while( col[0].position() <= 0.25 )
{
	for( int i; i < num; i++ ) 
	{
		col[i].spacer( ( Math.randomf() + 0.75 / ( one / 100.0 ) ) * 150::ms );
	}
	one++;
	150::ms => now;
}

for( int i; i < num; i++ ) 
{
	updateInterp( 112.0, 15::second );
	col[i].spacer( 0::ms );
}

15::second => now;

while( col[0].position() != 0.9 )
{
	for( int i; i < num; i++ ) 
	{
		if( Math.randomf() < ( ( col[i].position() - 0.25 ) / 0.9 ) && col[i].randomSize() == 0.0 ) 
		{
			<<< "grain size ">>>;
			col[i].randomSize( 40.0 );
			sizeInterpolators[i].keyOn( 900.0, 4::second );
		}
		else if( col[i].randomSize() ) 
		{
			col[i].randomSize( 0.0 );
			sizeInterpolators[i].keyOn( 12.0, 4::second );
		} 
	}
	4::second => now;
}

for( int i; i < num; i++ ) 
{
	col[i].spacer( 0::ms );
	col[i].randomSize( 0.0 );
	col[i].position( 0.0, col[i].duration() * 16.0 );
	<<< "backwards" >>>;
}

while( col[0].position() != 0.0 )
{
	for( int i; i < num; i++ ) 
	{
		if( Math.randomf() >= ( col[i].position() / 0.9 ) ) 
		{
			sizeInterpolators[i].keyOn( 120.0, 8::second );
		}
		else  
		{
			sizeInterpolators[i].keyOn( 900.0, 8::second );
		} 
	}
	8::second => now;
}


10::second => now;

fun void sizeLink( Collage grain[], Line interp[] )
{
	while( true )
	{
		for( int i; i < num; i++ )
		{
			if( grain[i].size() != interp[i].last() )
			{
				grain[i].size( interp[i].last() );
			}
		}
		10::ms => now;
	}	
}

fun void updateInterp( float sizes[], dur times[] )
{
	for( int i; i < sizes.size(); i++ ) sizeInterpolators[i].keyOn( sizes[i], times[i] );
}

fun void updateInterp( float size, dur time_to )
{
	for( int i; i < num; i++ ) sizeInterpolators[i].keyOn( size, time_to );
}
