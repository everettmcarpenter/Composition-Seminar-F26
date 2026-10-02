SinOsc voices[64] => Envelope envelopes[64] => dac;

fun void trackKeys()
{
    Hid key;
    HidMsg kmsg;

    while( true ) 
    {
        key => now;
        while( key.recv( kmsg ))
        {
            if( kmsg.isButtonDown() )
            {
                <<< "down:", kmsg.which, "(code)", kmsg.key, "(usb key)", kmsg.ascii, "(ascii)" >>>;
                if( kmsg.ascii == 27 )
                {
                    <<< "exiting!", "" >>>;
                    me.exit();
                }
            }
        }
    }
}

fun void trackMouse()