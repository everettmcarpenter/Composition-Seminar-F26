public class MIDICODES
{
    // these are like preprocessor defs
    0xB0 => static int CC;
    0x80 => static int NOTEOFF;
    0x90 => static int NOTEON;

    fun static void flush( MidiOut @ out )
    {
        for( int i; i < 128; i++ )
        {
            // most machines want note off
            MidiMsg mess;
            MIDICODES.NOTEOFF => mess.data1;
            i => mess.data2;
            0 => mess.data3;
            out.send( mess );
            // some machines want note on with zero velocity
            MIDICODES.NOTEON => mess.data1;
            out.send( mess );
        }
    }
}

public class GlobalStates
{
    // midi note states
    int noteStates[128];
        
    // midi events
    Event pressed[128];
    Event released[128];
}

// a scene will have a class such as this which will provide data regarding how it handles extensions
public class SceneExtensions
{
    fun void SceneExtensions( int extendThese[][] ) 
    {
        map( extendThese );
    }

    // a list of lists which contain a root at extendThese[i][0] and the subsequent entries are extensions
    // list takes the form of list[N] for N number of desired notes to be extended
    // and list[n][L] takes the form of list[n][0] being the fundamental for which will be extended and all entries are it's extensions 
    fun static void map( int list[][] )
    {
        for( int i; i < list.size(); i++ )
        {
            list[i][0] => int root;
            roots << root;
            // cycle
            for( 1 => int j; j < list[i].size(); j++ ) // don't append the root to the extensions array ( start at 1 )
            {
                extensions[root] << list[i][j]; // append to our internal array
            }
        }
    }

    // you can look up the corresponding extensions of a note here
    // each index of extensions[] may have varying sizes, so be sure to check
    static int extensions[128][0]; 
    static int roots[0];
}

// base class
public class Scene
{
    fun void extend( int extensionList[][] )
    {
        // allocate if we don't already have extensions
        if( !extensions )
            new SceneExtensions( extensionList ) @=> extensions;
        else // otherwise just map it
            extensions.map( extensionList );
        // flag
        1 => hasExtensions;
    }

    fun void updateState( MidiMsg @ msg )
    {
        if( msg.data1 == MIDICODES.NOTEON )
        {
            if( msg.data3 )
            {
                1 => states.noteStates[msg.data2];
                states.pressed[msg.data2].broadcast();
                // <<< msg.data2, "on" >>>;
            }
            else 
            {
                0 => states.noteStates[msg.data2];
                states.released[msg.data2].broadcast();
                // <<< msg.data2, "off" >>>;
            }
        }
        else if( msg.data1 == MIDICODES.NOTEOFF )
        {
            0 => states.noteStates[msg.data2];
            states.released[msg.data2].broadcast();
            // <<< msg.data2, "off" >>>;
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              member variables & objects
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // flags
    int hasExtensions;
    // has motives
    int hasMotives;

    // reference incase we don't actually need them
    SceneExtensions @ extensions;
    GlobalStates @ states;
    // human error
    0.05 => static float human;
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 



    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              stack
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // stack
    fun void stack( int notes[], dur offset, MidiOut @ out )
    {
        // playback 
        for( int i; i < notes.size(); i++ )
        {
            offset + humanTiming( offset ) => now; // wait
            MidiMsg mess;
            MIDICODES.NOTEON => mess.data1; // note on
            notes[i] => mess.data2; // which note
            <<< notes[i] >>>;
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
            MIDICODES.NOTEON => mess.data1; // note on
            notes[i] => mess.data2; // which note
            velocities[i % velocities.size()] => mess.data3; // velocity
            // <<< mess.data1, mess.data2, mess.data3 >>>;
            out.send( mess ); // send out
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              phrase
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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
                MIDICODES.NOTEON => mess.data1; 
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
                MidiMsg mess;
                MIDICODES.NOTEON => mess.data1; 
                notes[i] => mess.data2;
                velocities[i % velocities.size()] => mess.data3;
                <<< mess.data1, mess.data2, mess.data3 >>>;
                out.send( mess );

                lengths[i % lengths.size()] => timing;
                timing + humanTiming( timing ) => now;
            }
            flush( notes, out );
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              crescendo & decrescendo
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    fun int[] crescendo( int steps )
    {
        // return this
        int cresc[0];
        // increment
        127 / steps => int increment;
        // go
        for( int i; i < steps; i++ )
            cresc << i * increment;
        // we returned it
        return cresc;
    }

    fun int[] crescendo( int steps, int lhs, int rhs )
    {
        // return this
        int cresc[0];
        // increment
        ( rhs - lhs ) / steps => int increment;
        // go
        for( int i; i < steps; i++ )
            cresc << ( i * increment ) + lhs;
        // we returned it
        return cresc;
    }

    fun int[] decrescendo( int steps )
    {
        // return this
        int decresc[0];
        // increment
        127 / steps => int increment;
        // go
        for( int i; i < steps; i++ )
            decresc << 127 - ( i * increment );
        // we returned it
        return decresc;
    }

    fun int[] decrescendo( int steps, int lhs, int rhs )
    {
        // return this
        int decresc[0];
        // increment
        ( lhs - rhs ) / steps => int increment;
        // go
        for( int i; i < steps; i++ )
            decresc << lhs - ( i * increment );
        // we returned it
        return decresc;
    }

    fun int[] interleaveNoteOff( int phrase[], int start )
    {
        int newPhrase[0];
        for( int i; i < phrase.size(); i++ )
        {
            if( start )
            {
                newPhrase << 0;    
                newPhrase << phrase[i];
            }
            else
            {
                newPhrase << phrase[i];
                newPhrase << 0;    
            }
        }
        return newPhrase;
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              repeat
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    fun int[] repetition( int note, int numTimes )
    {
        // return this
        int row[0];
        // go
        for( int i; i < numTimes; i++ )
            row << note;
        // we returned it
        return row;
    }

    fun int[] repetition( int note[], int numTimes )
    {
        // return this
        int row[0];
        // go
        for( int i; i < numTimes; i++ )
            row << note[ i % note.size() ];
        // we returned it
        return row;
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              flush
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    // flush stack (note off)
    fun void flush( int notes[], MidiOut @ out )
    {
        for( int i; i < notes.size(); i++ )
        {
            // most machines want note off
            MidiMsg mess;
            MIDICODES.NOTEOFF => mess.data1;
            notes[i] => mess.data2;
            0 => mess.data3;
            out.send( mess );
            // some machines want note on with zero velocity
            MIDICODES.NOTEON => mess.data1;
            out.send( mess );
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              handle output of stack
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              handle output of phrase
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    //              utilities
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
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
}