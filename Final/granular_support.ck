public class GranularSupport // carbon copy of keyboard mapping from Everett
{
    int print;

    fun void GranularSupport( int mode )
    {
        mode => print;
    }

    fun void key(int key, Collage gran ) // huge interface layer 
    {
        // position setting via numerics
        if( key < 40 && key > 29 )
        {
            ( key - 29 ) * gran.samples() / 10.0 => gran.position;
            if( print ) 
                <<< "position: ", gran.targetPosition() >>>;
        }
        // enable spacer via alt key
        else if( key == 226 )
        {
            if( print ) 
                <<< "spacer: ", gran.spacer() >>>;
        }
        // left arrow
        else if( key == 79 )
        {
            Math.min( gran.sizeMS(), ( gran.size() * 1.06 ) ) => gran.size;
            if( print ) <<< "- grain length: ", gran.size() >>>;
        }
        // right arrow
        else if( key == 80 )
        {
            Math.max( 1.0, ( gran.size() / 1.06 ) ) => gran.size;
            if( print ) <<< "- grain length: ", gran.size() >>>;
        }
        // go to beginning of the file via `
        else if( key == 53 )
        {
            0 => gran.position;
            if( print ) 
                <<< "position: ", gran.targetPosition() >>>;
        }
        // advance via = 
        else if( key == 46 )
        {
            Math.min( 1.0, ( gran.position() ) + 0.001 ) => gran.position;
            if( print ) 
                <<< "position: ", gran.targetPosition() * gran.samples() >>>;
        }
        // and step back via -
        else if( key == 45 )
        {
            Math.max( 0.0, gran.position() - 0.001 ) => gran.position;
            if( print ) 
                <<< "position: ", gran.targetPosition() * gran.samples() >>>;
        }
        // random grain duration
        else if( key == 229 )
        {
            // shift to decrease random grain duration
            Math.max( 0.01, ( gran.randomSize() / 1.3 ) ) => gran.randomSize;
            if( gran.randomSize() 
                <= 0.01 ) 
                0.01 => gran.randomSize;
            if( print ) 
                <<< "- randomness grain length: ", gran.randomSize() >>>;
        }
        else if( key == 40 )
        {
            if( gran.randomSize() <= 0.01 ) 
                0.01 => gran.randomSize;
            Math.min( 4000.0, ( gran.randomSize() * 1.3 ) ) => gran.randomSize;
            if( print ) 
                <<< "+ randomness grain length: ", gran.randomSize() >>>;
        }
        // reduce rand position via [
        else if( key == 47 )
        {
            ( Math.max( 0.0, gran.randomPosition() - 50.0 ) ) => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        // increase rand position via ]
        else if( key == 48 )
        {
            ( Math.min( gran.sizeMS(), gran.randomPosition() + 50.0 ) ) => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        // set random position via qwertyuiop
        else if( key == 20 )
        {
            0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 26 )
        {
            200.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 8 )
        {
            2000.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 21 )
        {
            20000.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 23 )
        {
            40000.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 28 )
        {
            80000.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 24 )
        {
            100000.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 12 )
        {
            gran.sizeMS() * 7.0 / 9.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 18 )
        {
            gran.sizeMS() * 8.0 / 9.0 => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        else if( key == 19 )
        {
            gran.sizeMS() => gran.randomPosition;
            if( print ) 
                <<< "randomness of position: ", gran.randomPosition() >>>;
        }
        // pitch of granulator via asdfghjkl;' 
        else if( key == 10 )
        {
            gran.pitch( 1.0, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 9 )
        {
            gran.pitch( 0.75, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 7 )
        {
            gran.pitch( 0.5, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 22 )
        {
            gran.pitch( 0.25, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 4 )
        {
            gran.pitch( 0.000083, 250::ms ); // 4 samples per second at 48000
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 11 )
        {
            gran.pitch( 2.0, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 13 )
        {
            gran.pitch( 4.0, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 14 )
        {
            gran.pitch( 8.0, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 15 )
        {
            gran.pitch( 16.0, 250::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 51 )
        {
            gran.pitch( gran.pitch() - .05 / 12.0, 50::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        else if( key == 52 )
        {
            gran.pitch( gran.pitch() + .05 / 12.0, 50::ms );
            if( print ) 
                <<< "pitch: ", gran.targetPitch() >>>;
        }
        // rand pitch via < and >
        else if( key == 54 )
        {
            gran.randomPitch() - 0.025 => gran.randomPitch;
            if( print ) 
                <<< "rando of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 55 )
        {
            gran.randomPitch() + 0.025 => gran.randomPitch;
            if( print ) 
                <<< "rando of pitch: ", gran.randomPitch() >>>;
        }
        // random pitch via zxcvbnm
        else if( key == 29 )
        {
            0.0 => gran.randomPitch;      
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 27 )
        {
            1.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 6 )
        {
            2.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 25 )
        {
            3.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 5 )
        {
            4.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 17 )
        {
            5.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
        else if( key == 16 )
        {
            6.0 => gran.randomPitch;
            if( print ) 
                <<< "randomness of pitch: ", gran.randomPitch() >>>;
        }
    }
}
