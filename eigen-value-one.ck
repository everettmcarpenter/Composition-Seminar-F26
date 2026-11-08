@import "Rec.ck"

Rec.auto();

Collage voice( "raw-eigen-value-one.wav", 4 ) => dac;
DelayA delays( 0.13::second )[4] => Gain feedback( 0.7 )[4] => delays;
voice => Gain sends( 0.1 ) => delays => dac;

for( int i; i < delays.size(); i++ )
{
	delays[i].delay( Math.floor( i * i + 1 )::ms );
}

voice.position( 1.0, voice.samples() * 1.5::samp );
voice.pitch( 0.8 );
voice.size( 28.0 );
voice.randomSize( 100.0 );

while( voice.position() != 1.0 )
{
	if( Math.randomf() > 0.5 )
	{
		voice.randomSize( 1000.0 );
	}
	else
	{
		voice.randomSize( 0.0 );	
	}
	if( Math.randomf() > 0.9 )
	{
		voice.randomPitch( 6.0 );
	}
	else
	{
		voice.randomPitch( 0.0 );
	}
	100::ms => now;
}
