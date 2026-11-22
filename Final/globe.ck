// these are like preprocessor defs
0xB0 => global int CC;
0x80 => global int NOTEOFF;
0x90 => global int NOTEON;
// human error
0.05 => global float human;

// midi to logarithm
fun float midi2log( int midiValue )
{
    return 40.0 * Math.log10( midiValue / 127.0 );
}

// human timing
fun dur humanTiming( dur length )
{
    return length + ( Math.randomf() * length * human );
}
