@import "c-basescene.ck"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//                      doc
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//      scenes act as modular "parsers". they each have a function called
//      "handleInput" which is passed as midi msg, midi out.
//      the midi msg is the next message in a midi input stream such as a piano
//      this means it will contain note on and off messages, along with ccs
//      midi out is where the scene should send any responses it has to the input  
//      each of the below scenes extends a base class which contains 128 events 
//      for note on signaling and note off signaling, as well as boolean states
//      for presently depressed keys. scenes should handle state updates on their
//      own.
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

public class Alpha extends Scene
{
    fun void Alpha( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }
}

public class Beta extends Scene
{
    fun void Beta( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }
}

public class Gamma extends Scene
{
    fun void Gamma( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }

    34 => int bb1;
    37 => int db2;
    43 => int ab2;
    45 => int bb2;
    48 => int c3;
    49 => int db3;
    51 => int e3;
    57 => int bb3;
    73 => int db5;
    76 => int e5;

    // init with the desired extensions
    this.extend(
        [
            [ 0 ],
        ]    
    );

    // how does this scene respond?
    // when this scene is active, all midi messages are sent to it
    // no other processing should be done
    fun void handleInput( MidiMsg @ msg, MidiOut @ out )
    {
        // state update
        updateState( msg );

        // handle input
        if( msg.data1 == MidiCodes.CC )
        {
            ;
        }
        else if( msg.data1 == MidiCodes.NOTEON )
        {
            if( msg.data3 )
            {
                for( int i; i < extensions.roots.size(); i++ )
                {
                    if( msg.data2 == extensions.roots[i] ) // look up the notes which we are applying extensions to
                    {
                        // handle extensions
                        spork ~ outStack( extensions.extensions[msg.data2], 1::samp, states.released[msg.data2], out );
                    }
                }
            }
        }
        else if( msg.data1 == MidiCodes.NOTEOFF )
        {
            ;
        }
    }
}

public class Phi extends Scene
{
    fun void Phi( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }
}

public class Lambda extends Scene
{
    fun void Lambda( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }
}

// scene theta !
// extension of A + Db
// slow repetition of extensions as note is held
public class Theta extends Scene
{
    67 => int g4;
    69 => int a4;
    73 => int db5;
    76 => int e5;

    fun void Theta( GlobalStates handler )
    {
        handler @=> states; // now we have universal knowledge of note states
    }

    // init with the desired extensions
    this.extend(
        [
            [ a4, 60 ], // A4 + C4
            [ db5, 86, 93 ], // Db5 + D6 + A6
            [ g4, 71, g4 - 12, g4 - 2 ],
            [ e5, e5 + 12, e5 + 5, e5 + 7 ],
        ]    
    );

    // how does this scene respond?
    // when this scene is active, all midi messages are sent to it
    // no other processing should be done
    fun void handleInput( MidiMsg @ msg, MidiOut @ out )
    {
        // state update
        updateState( msg );

        // handle input
        if( msg.data1 == MidiCodes.CC )
        {
            ;
        }
        else if( msg.data1 == MidiCodes.NOTEON )
        {
            if( msg.data3 )
            {
                for( int i; i < extensions.roots.size(); i++ )
                {
                    if( msg.data2 == extensions.roots[i] ) // look up the notes which we are applying extensions to
                    {
                        // handle extensions
                        spork ~ outStack( extensions.extensions[msg.data2], [ 46, 64, 23, 52 ], 1::ms, states.released[msg.data2], out );
                        // if we're playing the full chord
                        if( states.noteStates[a4] && states.noteStates[db5] )
                        {
                            spork ~ firstChordTimer( out );
                        }
                        else if( states.noteStates[g4] && states.noteStates[e5] )
                        {
                            spork ~ secondChordTimer( out );
                        }
                    }
                }
            }
            <<< "A4", states.noteStates[a4], "Db5", states.noteStates[db5], "G4", states.noteStates[g4], "E5", states.noteStates[e5] >>>;
        }
        else if( msg.data1 == MidiCodes.NOTEOFF )
        {
            ;
        }
    }

    // wait
    fun void firstChordTimer( MidiOut @ out )
    {
        // states
        int phraseStates[128];
        extensions.extensions[db5] @=> int intervals[];
        // exit event
        Event exit;
        // while
        while( states.noteStates[a4] && states.noteStates[db5] )
        {
            // decide octave
            Math.random2( -4, 2 ) => int oct; 
            // decide interval
            Math.random2( 0, intervals.size() - 1 ) => int intervalIdx;
            
            // shift 
            ( oct * 12 ) + 48 => int note;

            if( Math.randomf() < 0.25 )
            {
                if( !phraseStates[note] )
                {
                    Math.random2( 1, 8 ) * 8 => int length;
                    spork ~ outPhrase( repetition( [ note ], length ), interleaveNoteOff( crescendo( length, 20, 120 ), 0 ), [ ( 1 + Math.abs( oct ) ) * 140::ms, 40::ms ], exit, out );
                    1 => phraseStates[note];
               }
            }
            500::ms => now;
        }
        // we broke the loop!
        exit.broadcast();
    } 

    // wait
    fun void secondChordTimer( MidiOut @ out )
    {
        // states
        int phraseStates[128];
        // intervals
        [ 5, 7, 14 ] @=> int intervals[];
        // exit event
        Event exit;
        // while
        while( states.noteStates[g4] && states.noteStates[e5] )
        {
            int note;
            // decide which note
            if( Math.randomf() < 0.5 )
                g4 => note;
            else 
                e5 => note; 
            // decide octave
            Math.random2( -4, 3 ) => int oct; 
            // decide interval
            Math.random2( 0, intervals.size() - 1 ) => int intervalIdx;
            
            // shift 
            ( oct * 12 ) + note + intervals[intervalIdx] => note;

            if( Math.randomf() < 0.25 )
            {
                if( !phraseStates[note] )
                {
                    Math.random2( 1, 8 ) * 8 => int length;
                    spork ~ outPhrase( repetition( [ note, note + 3, note + 4, note + 12 ], length ), interleaveNoteOff( crescendo( 2 * length, 35, 85 ), 0 ), [ 148::ms, 1::ms ], exit, out );
                    1 => phraseStates[note];
                }
            }
            2000::ms => now;
        }
        // we broke the loop!
        exit.broadcast();
    } 
}
