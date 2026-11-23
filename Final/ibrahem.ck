// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
//  disklavier utilizes large note extensions where each note 
//  has assigned "stacks" which build upon it 
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@import "c-scenes.ck" // see the scenes

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// identities
int controllerID; int disklavierInID; int disklavierOutID;
int keyboardID;

// flags
int usingDisk; int usingController;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                args
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if( !me.args() )
{ 
    cherr <= "input arguments required | [midi controller] ; [disklavier input] ; [disklavier output] / [hid keyboard id] (optional)" <= IO.nl(); 
    me.exit();
}
else if( me.args() == 3 )
{
    me.arg( 0 ) => Std.atoi => controllerID;
    me.arg( 1 ) => Std.atoi => disklavierInID;
    me.arg( 2 ) => Std.atoi => disklavierOutID;
    0 => usingController;
    1 => usingDisk;
}
if( me.args() == 4 )
    me.arg( 3 ) => Std.atoi => keyboardID;
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
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  scenes
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// global state class
GlobalStates states;
Alpha alpha( states );
Beta beta( states );
Gamma gamma( states );
Lambda lambda( states );
Phi phi( states );
Theta theta( states );
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// open keyboard 
if( !keyboard.openKeyboard( keyboardID ) ) me.exit();
cherr <= "keyboard '" <= keyboard.name() <= "' ready" <= "" <= IO.nl();

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
// exit ticket
Event exit;

1 => int ALPHA; int ALPHA_MSG; // the midi note or cc value corresponding with alpha
2 => int BETA; int BETA_MSG;
3 => int GAMMA; int GAMMA_MSG;
4 => int LAMBDA; int LAMBDA_MSG;
5 => int PHI; int PHI_MSG;
6 => int THETA; int THETA_MSG;
// current scene
THETA => int activeScene; 
/* scene enum
    {
        ALPHA = 1,
        BETA,
        GAMMA,
        LAMBDA,
        PHI,
        THETA
    }      
*/

// trill count
int trillCount;
// if the trill ended
Event trillOver;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  shreds
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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

MidiTools.flush( disklavierOut );


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                  function & shred definitions
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
// transition scene
fun void transitionScene( int sceneTo ) // should be called using the enums
{
    if( sceneTo >= ALPHA && sceneTo <= THETA )
        sceneTo => activeScene;
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
                if( msg.key == 41 )
                {
                    // exit
                    goTime.broadcast();
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
            if( msg.data1 == MidiCodes.CC )
            {
                ;
            }
            else if( msg.data1 == MidiCodes.NOTEON )
            {
                if( msg.data2 == ALPHA_MSG )
                    transitionScene( ALPHA );
                else if( msg.data2 == BETA_MSG )
                    transitionScene( BETA );
                else if( msg.data2 == GAMMA_MSG )
                    transitionScene( GAMMA );
                else if( msg.data2 == PHI_MSG )
                    transitionScene( PHI );
                else if( msg.data2 == THETA_MSG )
                    transitionScene( THETA );
            }
            else if( msg.data1 == MidiCodes.NOTEOFF )
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
            // scene
            if( activeScene == THETA )
            {
                theta.handleInput( msg, out ); // boom
            }
            else if( activeScene == GAMMA )
            {
                gamma.handleInput( msg, out );
            }
        }
    }
}

/*
    if( activeScene == 1 )
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
    else if( activeScene == 2 )
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
*/