// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
//  disklavier utilizes large note extensions where each note 
//  has assigned "stacks" which build upon it 
//
//  8 granulators can be mixed down to 1 - 8 channels
//  they are mixed by a midi controller with faders
//  the controller and laptop keyboard can select grains to edit
//  the laptop keyboard provides typical controls for the selected
//  grains.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@import "granular_support.ck"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// identities
int controllerID; int disklavierInID; int disklavierOutID;
int keyboardID; int mouseID;

// flags
int usingDisk; int usingController;

// these are like preprocessor defs
0xB0 => int CC;
0x80 => int NOTEOFF;
0x90 => int NOTEON;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                args
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if( !me.args() )
{ 
    cherr <= "input arguments required | [midi controller] ; [disklavier input] ; [disklavier output] or [hid keyboard] ; [hid mouse] ; [midi controller] (optional)" <= IO.nl(); 
    me.exit();
}
else if( me.args() > 4 )
{
    // controller
    me.arg( 0 ) => Std.atoi => controllerID; 
    1 => usingController;
    // disklavier in
    me.arg( 1 ) => Std.atoi => disklavierInID;
    1 => usingDisk;
    // disklavier in
    me.arg( 2 ) => Std.atoi => disklavierOutID;
    // are there more?
    if( me.args() == 4 ) // keyboard
        me.arg( 3 ) => Std.atoi => keyboardID;
    if( me.args() == 5 ) // mouse
        me.arg( 4 ) => Std.atoi => mouseID;
}
else if( me.args() == 2 )
{
    // skip the midi setup
    me.arg( 0 ) => Std.atoi => keyboardID;
    me.arg( 1 ) => Std.atoi => mouseID;
}
else if( me.args() == 3 )
{
    // skip the midi setup
    me.arg( 0 ) => Std.atoi => keyboardID;
    me.arg( 1 ) => Std.atoi => mouseID;
    me.arg( 2 ) => Std.atoi => controllerID;
    1 => usingController;
}
else if( me.args() == 4 )
{
    // skip the midi setup
    me.arg( 0 ) => Std.atoi => keyboardID;
    me.arg( 1 ) => Std.atoi => mouseID;
    me.arg( 2 ) => Std.atoi => disklavierInID;
    me.arg( 3 ) => Std.atoi => disklavierOutID;
    1 => usingDisk;
}
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                   audio
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// sounds
Collage grains( "mat.wav", 8 )[8] => Envelope faders[8] => Gain sum( 1.0 / ( 8.0 / dac.channels() ) )[dac.channels()] => dac;
// mapping helper class
GranularSupport support( 1 );
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  control
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// midi
MidiIn controller;
// disk in
MidiIn disklavierIn;
// disk
MidiOut disklavierOut;
// keyboard
Hid keyboard;
// mouse
Hid mouse;
// midi events
Event pressed[127];
Event released[127];
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// open keyboard 
if( !keyboard.openKeyboard( keyboardID ) ) me.exit();
cherr <= "keyboard '" <= keyboard.name() <= "' ready" <= "" <= IO.nl();

// open mouse 
if( !mouse.openMouse( mouseID ) ) me.exit();
cherr <= "mouse '" <= mouse.name() <= "' ready" <= "" <= IO.nl();

// open controller
if( usingController )
    if( !controller.open( controllerID ) ) 
        cherr <= "operating without MIDI controller." <= IO.nl();

// open disk input
if( usingDisk )
    if( !disklavierIn.open( disklavierInID ) ) 
        cherr <= "operating without MIDI output." <= IO.nl();

// open disk output
if( usingDisk )
    if( !disklavierOut.open( disklavierOutID ) ) 
        cherr <= "operating without MIDI output." <= IO.nl();
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  data & control
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// currently active grains
int activeGrains[8];
// -1 backwards 0 stopped 1 forward
int grainDirections[8];

// cursor vector
vec2 cursor;

// feature vector
FeatureCollector features[2];

// exit ticket
Event exit;

// current scene
2 => int scene;

// human error
0.05 => float human;

// trill count
int trillCount;
// if the trill ended
Event trillOver;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  shreds
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// mouse
spork ~ mouseShred( mouse, cursor );
// keyboard
spork ~ keyboardShred( keyboard, exit );
// controller
if( controller.good() )
    spork ~ controllerShred( controller );
// disklavier in & out
if( disklavierIn.good() && disklavierOut.good() )
    spork ~ disklavierShred( disklavierIn, disklavierOut );
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// forever from here on out
exit => now;



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

// decrypt mouse and update the cursor vector
fun void mouseShred( Hid @ m, vec2 c )
{
    HidMsg msg;

    // go!
    while( true )
    {
        // wait
        m => now;

        // recv
        while( m.recv( msg ) )
        {
            if( msg.isMouseMotion() ) // report back
            {
                msg.scaledCursorX => c.x;
                msg.scaledCursorY => c.y;

                // center x so that the center of the screen is 0.0, left is -0.5 and right is 0.5
                2.0 * ( c.x - 0.5 ) => float centeredX;
                // stretch factor
                8.0 => float stretch;
                // piece wise ( if we're near the center, lock it to 0.0 )
                if( centeredX >= -0.1 && centeredX <= 0.1 )
                    0.0 => centeredX;
                // set 
                for( int i; i < grains.size(); i++ )
                {
                    // if a grain is selected
                    if( activeGrains[i] )
                    {
                        if( centeredX < 0.0 ) // move backwards
                            grains[i].position( 0.0, grains[i].samples() * ( Math.fabs( centeredX ) ) * stretch::samp );
                        else if( centeredX > 0.0 ) // move forwards
                            grains[i].position( 1.0, grains[i].samples() * ( Math.fabs( centeredX ) ) * stretch::samp );
                        else // stand still
                            grains[i].position( grains[i].position() );
                    }
                }
                // printGrainPositions();
            }
        }
    }
}

// decrypt keyboard and edit global variables
fun void keyboardShred( Hid @ k, Event @ goTime )
{
    HidMsg msg;

    // go!
    while( true )
    {
        // wait
        k => now;

        // recv
        while( k.recv( msg ) )
        {
            // laptop num pad is 
            // x = msg.key - 88
            if( msg.isButtonDown() ) 
            {
                if( msg.key >= 89 && msg.key <= 97 )
                {
                    // map -> [0, 8]
                    msg.key - 89 => int index;
                    if( index == 4 )
                        activeGrains.zero();
                    else if( index < 4 )
                        // activate
                        ++activeGrains[index] % 2 => activeGrains[index];  
                    else if( index > 4 )
                        ++activeGrains[index - 1] % 2 => activeGrains[index - 1];
                    // print 
                    printActiveGrains();
                }
                else if( msg.key == 41 )
                {
                    // exit
                    goTime.broadcast();
                }
                else
                {
                    // map
                    for( int i; i < grains.size(); i++ )
                    {
                        if( activeGrains[i] )
                            support.key( msg.key, grains[i] );
                    }
                }
            }
            else if( msg.isButtonUp() )
            {
                ;
            }
        }
    }
}

// controller
fun void controllerShred( MidiIn @ c )
{
    MidiMsg msg;

    // go!
    while( true )
    {
        // wait
        c => now;

        while( c.recv( msg ) )
        {
            // cc
            if( msg.data1 == CC )
            {
                // faders
                if( msg.data2 <= 8 && msg.data2 >= 1 )
                    faders[msg.data2 - 1].ramp( 40::ms,  msg.data3 / 127.0 );
            }
            else if( msg.data1 == NOTEON )
            {
                if( msg.data2 <= 48 && msg.data2 >= 40 )
                {
                    // map -> [0,8]
                    msg.data2 - 40 => int index;
                    // zero if 8
                    if( index == 8 )
                        activeGrains.zero();
                    else // do the thing
                        ++activeGrains[index] % 2 => activeGrains[index];
                    printActiveGrains();
                }
            }
            else if( msg.data1 == NOTEOFF )
            {
                ;
            }
        }
    }
}

// disk
fun void disklavierShred( MidiIn @ in, MidiOut @ out )
{
    MidiMsg msg;

    // go!
    while( true )
    {
        // wait
        in => now;

        // decrypt
        while( in.recv( msg ) )
        {
            if( msg.data1 == NOTEON )
            {
                if( msg.data3 )
                {
                    // notify everyone that you pressed this key
                    pressed[msg.data2].broadcast();

                    if( scene == 1 )
                    {
                        if( msg.data2 == 62 ) // D3
                            spork ~ outStack( [ 73, 77, 82 ], [ 49, 31, 22 ], 150::ms, released[msg.data2], disklavierOut ); // c4, f4, Bb4
                        else if( msg.data2 == 76 ) // E4
                            spork ~ outStack( [ 60, 65, 70 ], [ 48, 27, 32 ], 200::ms, released[msg.data2], disklavierOut );
                        else if( msg.data2 == 82 ) // Bb4
                            spork ~ outStack( [ 82 + 12, 82 + 24, 82 + 36 ], [ 45, 52, 39 ], 10::ms, released[msg.data2], disklavierOut );
                        else if( msg.data2 == 83 ) // B4
                            spork ~ outStack( [ 83 - 12, 83 - 24, 82 - 36 ], [ 45, 52, 39 ], 50::ms, released[msg.data2], disklavierOut );
                    }
                    else if( scene == 2 )
                    {
                        if( msg.data2 == 67 )
                        {
                            spork ~ outPhrase( [ 74, 90 - 12, 81, 85 ], [ msg.data3, msg.data3 / 4 ], [ 500::ms ], released[msg.data2], disklavierOut );
                        }
                        else if( msg.data2 == 69 )
                        {
                            spork ~ outPhrase( [ Math.random2( 23, 69 ), Math.random2( 23, 69 ), Math.random2( 23, 69 ), Math.random2( 23, 69 ) ], [ msg.data3, msg.data3 / 4 ], [ 26::ms ], released[msg.data2], disklavierOut );
                        }
                        else if( msg.data2 == 79 || msg.data2 == 81 )
                        {
                            trillCount++;

                            if( trillCount == 24 )
                                spork ~ outPhrase( [ 74, 76 ], [ 32::ms ], trillOver, disklavierOut );
                            else if( trillCount == 36 )
                                spork ~ outPhrase( [ 69, 71 ], [ 64::ms ], trillOver, disklavierOut );
                            else if( trillCount == 48 )
                                spork ~ outPhrase( [ 67, 66 ], [ 128::ms ], trillOver, disklavierOut );
                            else if( trillCount == 60 )
                                spork ~ outPhrase( [ 57, 59 ], [ 256::ms ], trillOver, disklavierOut );
                            else if( trillCount == 88 )
                            {
                                trillOver.broadcast();
                                0 => trillCount;
                            }
                        }
                    }
                }
                else
                {
                    // notify everyone that you released this key
                    released[msg.data2].broadcast();
                    // 
                    if( msg.data2 == 59 )
                    {
                        Math.random2( 1, 12 ) => int reps;
                        spork ~ lowb( reps );
                    }
                }
            }
        }
    }
}

fun void lowb( int reps )
{
    spork ~ outStack( [ 45, 54, 67, 74, 78 ], 1::ms, 100::ms, disklavierOut );
    100::ms => now;
    flush( [ 45, 54, 67, 74, 78 ], disklavierOut );
    for( int i; i < reps; i++ )
    {    
        450::ms + humanTiming( 450::ms ) => now; // wait
        spork ~ outStack( [ 45, 54, 67, 74, 78 ], 1::ms, 100::ms, disklavierOut );
        flush( [ 45, 54, 67, 74, 78 ], disklavierOut );
    }
}

// stack
fun void stack( int notes[], dur offset, MidiOut @ out )
{
    // playback 
    for( int i; i < notes.size(); i++ )
    {
        offset + humanTiming( offset ) => now; // wait
        MidiMsg mess;
        NOTEON => mess.data1; // note on
        notes[i] => mess.data2; // which note
        64 => mess.data3; // velocity
        out.send( mess ); // send out
    }
}

// stack
fun void stack( int notes[], int velocities[], dur offset, MidiOut @ out )
{
    // playback 
    for( int i; i < notes.size(); i++ )
    {
        offset + humanTiming( offset ) => now; // wait
        MidiMsg mess;
        NOTEON => mess.data1; // note on
        notes[i] => mess.data2; // which note
        velocities[i % velocities.size()] => mess.data3; // velocity
        out.send( mess ); // send out
    }
}

// phrase ( trill, sequence, etc. )
fun void phrase( int notes[], dur lengths[], MidiOut @ out )
{
    while( true )
    {
        dur timing;
        for( int i; i < notes.size(); i++ )
        {
            lengths[i % lengths.size()] => timing;
            timing + humanTiming( timing ) => now;
            MidiMsg mess;
            NOTEON => mess.data1; 
            notes[i] => mess.data2;
            64 => mess.data3;
            out.send( mess );
        }
        timing + humanTiming( timing ) => now;
        flush( notes, out );
    }
}

// phrase ( trill, sequence, etc. )
fun void phrase( int notes[], int velocities[], dur lengths[], MidiOut @ out )
{
    while( true )
    {
        dur timing;
        for( int i; i < notes.size(); i++ )
        {
            lengths[i % lengths.size()] => timing;
            timing + humanTiming( timing ) => now;
            MidiMsg mess;
            NOTEON => mess.data1; 
            notes[i] => mess.data2;
            velocities[i % velocities.size()] => mess.data3;
            out.send( mess );
        }
        timing + humanTiming( timing ) => now;
        flush( notes, out );
    }
}

// flush stack (note off)
fun void flush( int notes[], MidiOut @ out )
{
    for( int i; i < notes.size(); i++ )
    {
        // most machines want note off
        MidiMsg mess;
        NOTEOFF => mess.data1;
        notes[i] => mess.data2;
        0 => mess.data3;
        out.send( mess );
        // some machines want note on with zero velocity
        NOTEON => mess.data1;
        out.send( mess );
    }
}

// to disklavier
fun void outStack( int notes[], dur offset, Event @ release, MidiOut @ out )
{
    // shoot out shred so it can work independently of this one
    spork ~ stack( notes, offset, out );
    // wait for the release, even if it releases before the above shred finishes, we will cut it short
    release => now;
    // flush 
    flush( notes, out );
}

// to disklavier
fun void outStack( int notes[], dur offset, dur length, MidiOut @ out )
{
    // shoot out shred so it can work independently of this one
    spork ~ stack( notes, offset, out );
    // wait for the release, even if it releases before the above shred finishes, we will cut it short
    length => now;
    // flush 
    flush( notes, out );
}

// to disklavier
fun void outStack( int notes[], int velocities[], dur offset, Event @ release, MidiOut @ out )
{
    // shoot out shred so it can work independently of this one
    spork ~ stack( notes, velocities, offset, out );
    // wait for the release, even if it releases before the above shred finishes, we will cut it short
    release => now;
    // flush 
    flush( notes, out );
}

// to disklavier
fun void outPhrase( int notes[], dur offsets[], Event @ release, MidiOut @ out )
{
    // shoot out shred so it can work independently of this one
    spork ~ phrase( notes, offsets, out );
    // wait for the release, even if it releases before the above shred finishes, we will cut it short
    release => now;
    // flush 
    flush( notes, out );
}

// to disklavier
fun void outPhrase( int notes[], int velocities[], dur offsets[], Event @ release, MidiOut @ out )
{
    // shoot out shred so it can work independently of this one
    spork ~ phrase( notes, velocities, offsets, out );
    // wait for the release, even if it releases before the above shred finishes, we will cut it short
    release => now;
    // flush 
    flush( notes, out );
}

// print the active grains
fun void printActiveGrains()
{
    // announce
    cherr <= "active grains : ";
    // cycle
    for( int a : activeGrains )
        cherr <= a <= " ";
    // end
    cherr <= IO.nl();
}

// print grain positions
fun void printGrainPositions()
{
    // announce
    cherr <= "grain positions: ";
    // cycle
    for( Collage g : grains )
        cherr <= g.position() <= " ";
    // end
    cherr <= IO.nl();
}

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