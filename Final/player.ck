/*

108 troubles (of mankind)
by Rob Hamilton

6 X 3 X 2 X 3 = 108

"The large bell within the Buddha (the Tian Tan Buddha in Hong Kong) is controlled by computer and rings 108 times during the day to symbolise escape from what Buddhism terms the '108 troubles of mankind'.
"April 1961: the Soviets sent the first human to space. Russian cosmonaut Yuri Gagarin made a 108-minute suborbital flight in a Vostok 1 spacecraft and returned safely to Earth."

cmd-line$ chuck -c32 --srate48000 player.ck:out.txt:32:2:1:0:0:524:0:0:1:1.5:0

arg(0)    data filename
arg(1)    output channel count
arg(2)    play type (midi, score, combination) (0-10)
arg(3)    send Partials all to same channel as parent Note (0,1)
arg(4)    time in ms to run before pausing, then exiting
arg(5)    fadeout time in ms for setting duration on output envelopes
arg(6)    starting note from full sequence
arg(7)    cell index from which to start playback
arg(8)    cell play style (0: loop, 1-n: play cell n-times)
arg(9)    init osc positioning: 2 = send osc data then self-quit. 1 has bug on first few notes. 2 or greater sets initial speaker location set
arg(10)    default source distance for osc positioning
arg(11)   trigger scene #

Requests:

- subs
- buzzing speakers (tighten?)
- piezo for piano pedal sounds

Commands:

[h]   <toggle>   "Hold" currently playing partials and "Pause" new note playback
[p]   <toggle>   "Pause" new note playback.
[f]   <toggle>   "play File" plays file samples with each note

Bugs:
[ ] bug: fuzzy notes at start of new cells sometimes

[ ] bug: when init osc positioning == 1, first few notes are distorted
--  hack fix: set arg(9) to 2 to load OSC params then auto-quit; then restart with val of 0

[ ] bug: Note[22] causes single pop sound when played from start

[/] bug: popping sounds after multiple iterations
--  hack fix: spawning new Partial object in setPartials() stops it from happening
--  what parameter(s) of Partial aren't being reset?

[ ] bug: file play stops a few notes into playback
[ ] bug: play type 4 overloads spat~
[x] bug: repeating notes get progressively hotter (need to kill adsrs?)
[x] bug: seg faults occasionally on "hold" feature

To Do:

[ ] shell script to make launch script in bash path

[ ] multiple speaker setups
-- added different speaker orders

[ ] switch between sections/settings over time
-- added auto bass and auto hold routines
-- need to add auto stutterer

[ ] sample-and-hold envelope array for partials
-- will trigger on rhythm
-- bug: why does amp get so hot in partial with envelopes added? scaling manually to 0.33 now

[ ] pitch bend partials via osc
-- via piano left pedal
-- works but not good yet

- set array of positions for spat~
- init/send-over-osc positions for spat~

- make cells/phrases of low notes (for subwoofers)
- disklavier output rather than sample output

- midi pedal/disklavier stopper sound (caused by scrolling through logic file to piano).
-- use as rhythm for installation
-- 08:51:15.001	To MIDI Monitor (Untitled)	Control	1	64	68
-- 08:51:15.077	To MIDI Monitor (Untitled)	Control	1	64	0
-- 08:51:15.079	To MIDI Monitor (Untitled)	Control	1	64	127
-- 08:51:15.161	To MIDI Monitor (Untitled)	Control	1	64	0
-- 08:51:15.163	To MIDI Monitor (Untitled)	Control	1	64	127
-- 08:51:15.453	To MIDI Monitor (Untitled)	Control	1	64	0


spatializations:
- generic OSC send to spat~
- preset specific locations (array of locations)
- distance function (pulls note in closer)
- rotator (rotates around a point; for partials w/root)
- move from position A to position B over time X


done:
[x] midi input triggers partial lengths = to chosen Note, not note-off message
--- add flag that bypasses midi hold in playback (ignoreMidiOff)
[x] tie dsk footpedal (176 #) to holding partials (use stall code)
[x] add "hold" feature, which holds all currently playing partials
[x] play "cell" defined as set of notes from the main array
--- can "loop" cells with second parameter


---playType---
1 = MIDI Input
2 = SCORE Input (note-by-note playback; one at a time)
3 = MIDI + SCORE Input
4 = SCORE Player (mimics performance timings)
5 = Autonomous Notes
6 = Cell Player without chord (like playType==2)
7 = Cell Player with chord (like playType==4)
8 = MIDI + Cell player without chord
9 = MIDI + Cell player with chord
10 = Note Sequence (testing) 


*/


4 => int playType;                        // default
0 => int partialsSameChannel;             // flag to determine if partials automatically go to same channel as Note
1 => int scoreRepeat;                     // flag to repeat score auto playback
0 => int debug;
1 => int playFileFlag;
1 => int playPartialFlag;
1 => int muteNotePlayPartials;            // don't repeat MIDI Notes (while Note is playing) but allow partials to trigger again
0 => int cellIndex;                       // index of cell for player to start with
1 => int cellPlayType;                    // 0: loop, 1-n: play cell n-times; default to 1 (play once)
//0 => int loopCell;                        // loop cell playback
0 => int ignoreMidiOff;                   // for midi triggered notes, ignore note off and play full duration 
0 => int timerLength;                     // time (ms) before patch pauses and ramps volumes down in preparation for shut-off
0 => int hold;                            // hold currently playing partials

3 => int channel_MAXVOICES;               // maximum number of voices allowed per channel
10 => int channel_TOTALVOICES;            // total number of sound instances on each channel
//20
0 => int pause;                           // flag to pause timed output
1.0 => float speed;                       // playback speed (only for playType=4)

// Global settings/instantiations
1.0 => float master_VOLUME;

3 => int numberOfBwgs => int numberOfPartials;   // number of BWGs & Partials per piano sample

7.0 => float gFileGain;
0.7/numberOfPartials => float gPartialGain;
0 => int osc_output;
0 => int init_osc_positioning;            // whether or not to send osc source position data at launch; value -2 sets default speaker configs.
0. => float osc_default_distance;        // distance for default spat~ sources (hack)

1 => int pedal_rhythms;                   // default pedal rhythms ON
0 => int footPedalHold;                   // flag to set whether foot pedal presses on Disklavier will trigger hold

// vars for holding and pausing
0 => int gTempFileFlag;
playFileFlag => int gPlayFileFlag;

1. => float gPitchShift;
0 => int gBassShift;
0 => int gStutter;                        // starts output envelopes cycling on and off
50 => int gStutterSpeed;                  // ms rate between stutters
20 => int gStutterEnvelopeSpeed;          // ms rate of envelope
0.33 => float gEnvelopeGain;
0 => int gStartingNoteIndex;               // note on which the piece will begin (0 defaults at beginning)

5000 => int fadeOutDuration;              // ms duration for fade out on all output envelopes

0 => int toggle_position_all_ad;          // start random positioning of sound sources

0 => int trigger_scene;                   // number for timed scene to be called from 108.ck
dur gElapsedTime;                         // global elapsed time for tracking cell length in ms
int gCurrentNoteIndex;                     // current note index for tracking in scenes
1 => int gRandomHold;                      // trigger random hold calls over time
1 => int gRandomBass;
0 => int gPartialChordType;                // type of chord for partials:         // 1 = partials, 2 = random within 1 octave, 3 = major, 4=minor, 5=seventh
// ------------------------------------------------------------------------------------------------------

// array of voices/channel
int channelCount;
string filename;
string fileFolder;

"output/" => fileFolder;       // folder location of audio files (test vs recorded)

// linux needs leading "/"
// "/output/" => fileFolder;       // folder location of audio files (test vs recorded)

//"output_synth/" => fileFolder;       
//"output_testsynth/" => fileFolder;       

// set default argument values
me.sourceDir() + fileFolder + "out.txt" => filename; // default to out.txt with no input args
2 => channelCount;  // default to 2 channel with no input args


// -------------------------------------------------
// COMMAND LINE ARGS
// -------------------------------------------------
// source filename
if( me.args() > 0 ) 
    me.sourceDir() + fileFolder + me.arg(0) => filename;

// output channels
if( me.args() > 1)
    me.arg(1) => Std.atoi => channelCount;
// play type
if( me.args() > 2)
    me.arg(2) => Std.atoi => playType;

// partials "attached" to same channel as sample or separate
if( me.args() > 3)
    me.arg(3) => Std.atoi => partialsSameChannel;

// timer length in ms
if( me.args() > 4)
    me.arg(4) => Std.atoi => timerLength;

// fade out duration in ms
if( me.args() > 5) {    
    me.arg(5) => Std.atoi => int tempDuration;   // if fade out duration is set to 0, use default
    if(tempDuration > 0)
        tempDuration => fadeOutDuration;
}

// index on which to start playback
if( me.args() > 6)
    me.arg(6) => Std.atoi => gStartingNoteIndex;

// cell index to play a given cell only
if( me.args() > 7)
    me.arg(7) => Std.atoi => cellIndex;

// play type for cell playback (looping or n-plays)
if( me.args() > 8)
    me.arg(8) => Std.atoi => cellPlayType;

// send osc source positioning data at launch or not
if( me.args() > 9)
    me.arg(9) => Std.atoi => init_osc_positioning;

// send osc source positioning data at launch or not
if( me.args() > 10)
    me.arg(10) => Std.atof => osc_default_distance;

if( me.args() > 11)
    me.arg(11) => Std.atoi => trigger_scene;

// chord type for partial array
if( me.args() > 12)
    me.arg(12) => Std.atoi => gPartialChordType;


// -------------------------------------------------


// if partials are set to individual channels, just set these to 1 to force all voices to separate channels
if(partialsSameChannel==0)
{
    1 => channel_MAXVOICES;                 // maximum number of voices allowed per channel
    1 => channel_TOTALVOICES;               // total number of sound instances on each channel    
}


// BWG Default values
0.410429 => float bwgStrikePosition;
0.764 => float bwgBowPressure;            
0.278746 => float bwgBowRate;

// BWG Ring Mod parameters (0s all)
1 => int gRandomize_bwg_params;
1 => int gUse_ring_modulator;
1 => int gRandomize_ring_params;
5 => float gRing_frequency;    


// Envelope array for sample and hold sounds; need to call keyOn() for each at init
Envelope envelopes[channelCount];


// -------------------------------------------------
// OSC Code Block
// -------------------------------------------------
OscRecv orec;
9999 => orec.port;
orec.listen();
orec.event("/troubles/settings, ii") @=> OscEvent osc_settings;
orec.event("/troubles/values, if") @=> OscEvent osc_values;

fun int bLimit(int val)
{
    if(val > 1)
        1 => val;
    else if(val < 0)
        0 => val;
    
    return val;
}

fun int bLimit(int val, int ubound)
{
    if(val > ubound)
        ubound => val;
    else if(val < 0)
        0 => val;
    
    return val;    
}

fun float fbLimit(float val, float ubound)
{
    if(val > ubound)
        ubound => val;
    else if(val < 0)
        0 => val;
    
    return val;    
}

fun float fbLimit2(float val, float lbound, float ubound)
{
    if(val > ubound)
        ubound => val;
    else if(val < lbound)
        lbound => val;
    
    return val;    
}

fun void oscSettings()
{
    while(true)
    {    
        osc_settings => now;    
        
        while (osc_settings.nextMsg() ) {
            
            osc_settings.getInt() $ int => int index;
            osc_settings.getInt() $ int => int value;
            
            <<< "Osc Settings:", index, value >>>;    
            
            if(index==1)
                bLimit(value, 7) => playType;
            else if(index==2)
                bLimit(value) => partialsSameChannel;
            else if(index==3)
                bLimit(value) => gPlayFileFlag;            
            else if(index==4)
                bLimit(value) => gUse_ring_modulator;               
            else if(index==5)
                bLimit(value) => gRandomize_bwg_params;    
            else if(index==6)
                bLimit(value) => gRandomize_ring_params;     
            else if(index==7)
                bLimit(value) => pause;                                                                 
        }
        
        100::samp => now;
    }    
}

fun void oscValues()
{
    while(true)
    {    
        osc_values => now;    
        
        while (osc_values.nextMsg() ) {
            
            osc_values.getInt() $ int => int index;
            osc_values.getFloat() $ float => float value;
            
            <<< "Osc Values:", index, value >>>;          
            
            if(index==1)
            { 
            } else if(index==2)
            {
            } else if(index==3)
                fbLimit(value, 1.0) => bwgStrikePosition;
            else if(index==4)
                fbLimit(value, 1.0) => bwgBowPressure;     
            else if(index==5)
                fbLimit(value, 1.0) => bwgBowRate;   
            else if(index==6)            
                fbLimit(value, 20) => gRing_frequency;        
        }
        
        100::samp => now;
    }    
}

// ----------------------------------------------------
// OSC Output - spatialization
// ----------------------------------------------------

"10.200.40.100" => string hostname;
6666 => int port;
OscOut xmit;
if(osc_output==1)
    xmit.dest( hostname, port);

// ----------------------------------------------------
// Header output
// ----------------------------------------------------
chout <= "\n.....................................\n";
chout <= ".............108 Troubles............\n";
chout <= "...........by Rob Hamilton...........\n";
chout <= ".....................................\n";
chout <= "initalizing..........................\n";
chout <= ".....................................\n";
chout <= "..Output Channels.................. " <= channelCount <= "\n";
chout <= "..Play Type........................ " <= playType <= "\n";
if(playType == 1 || playType == 3 || playType == 8 || playType == 9 )
{
    chout <= "..MIDI Input....................... On" <= "\n";    
}
if(playType == 2 || playType == 3 || playType == 4 )
    chout <= "..Starting Note Index.............. " <= gStartingNoteIndex <= "\n";        

if(playType == 6 || playType == 7 || playType == 8 || playType == 9 )
{
    chout <= "....Cell Play...................... 1" <= "\n";
    
    chout <= "....Cell Index..................... " <= cellIndex <= "\n";    
    
    if(cellPlayType == 0)
        chout <= "....Cell Loop...................... On" <= "\n";
    else
        chout <= "....Cell Loop count................ " <= cellPlayType <= "\n";               
}
if(timerLength > 0)
    chout <= "....Timer Length..(ms)............. " <= timerLength <= "\n";
if(fadeOutDuration > 0)
    chout <= "....Fade Duration..(ms)............ " <= fadeOutDuration <= "\n";
chout <= "....Pedal Rhythms.................. " <= pedal_rhythms <= "\n";
chout <= "....Random Hold.................... " <= gRandomHold <= "\n";
chout <= "....Random Bass.................... " <= gRandomBass <= "\n";
chout <= "....Partial Chord Type............. " <= gPartialChordType <= "\n";
chout <= ".....................................\n";    
chout <= ".....................................\n\n";    


//0 => int cellIndex;                       // index of cell for player to start with
//1 => int cellPlayType;                    // 0: loop, 1-n: play cell n-times; default to 1 (play once)



// make our own event
class NoteEvent extends Event
{
    int note;
    int velocity;
}

// the event
NoteEvent on;

time launchTime;
time time_a, time_b, time_c, time_d, time_e;

time notePlay;
time partialPlay;

0 => int noteCount;
400 => float testWaitTime;

// MIDI defaults
1 => int MIDIdevice;            // midi input device (1 for hamburger; 0 for bob)
149 => int noteOn;
9600 => int ppq;                // hardcoded for now; pass these in data file?
120 => int bpm;
60000.0 / (bpm * ppq) => float msPerTick; 

1000::ms => dur recPadding;                 // time padded at end of recordings (retrieve from data file later, hardcoded now
1000::ms => dur envelopeRelease;            // ADSR release time for Note and Partial

// ARRAY TO TRACK MIDI ONS AND OFFS TO LIMIT NOTE REPEATS
int midiNotes[128];
for(0=>int i; i<128;i++)
    0=>midiNotes[i];

// output file directory
//"output/" => fileFolder;       // folder location of audio files (test vs recorded)
//"output_synth/" => string fileFolder;       
//"output_testsynth/" => string fileFolder;       

// array of voices/channel
//2 => int channelCount;
//8 => int channelCount;
int channels[channelCount];

for(0=>int a; a<channelCount;a++)
{
    0 => channels[a];    
}

float channelGains[channelCount];

-1 => int lastChannel;

// count limits: these _must_ be the same for now, else "free" array will throw ArrayOutofBounds
// this would be: 32*5*3 = 480
//channelCount*channel_MAXVOICES*numberOfBwgs => int bwgCount;
//channelCount*channel_MAXVOICES*numberOfPartials => int partialCount;

// set this lower
//channelCount*numberOfBwgs => int bwgCount => int partialCount;

2000 => int bwgCount;
2000 => int partialCount;


// hack - if we recreate partials each time, use this.
//20 => int bwgCount;
//20 => int partialCount;


// Banded Wave guide arrays
BandedWG bwgs[bwgCount];
int freeBwgs[bwgCount];

// Partial arrays
Partial partials[partialCount];
int freePartials[partialCount];

// init tracking variables for partials and bwgs
-1 => int lastFreePartial;
-1 => int lastFreeBwg;

fun void killPartial(int j)
{
    // set channel locally in case it changes
    partials[j].channel => int thisChannel;
    partials[j].bwgNumber => int thisBwgNumber;
    
    if(thisChannel > -1) 
    {        
        //        <<< "killPartial:  channels[partials[", j, "].channel] = ", channels[partials[j].channel], ", partials[", j, "].channel: ", partials[j].channel >>>;
        
        if(channels[thisChannel] > 0)
        {
            // decrement channel count            
            channels[thisChannel] - 1 => channels[thisChannel];     
            //            <<< "killPartial() decrementing, channel =", thisChannel, ", channels[", partials[j].channel, "]=",channels[partials[j].channel]>>>;
        }
        
        partials[j].e.keyOff();               
        partials[j].adsr_r => now;
        1. => bwgs[thisBwgNumber].stopBowing;
        0. => bwgs[thisBwgNumber].gain;
        
        channelGains[thisChannel] - partials[j].gg.gain() => channelGains[thisChannel]; 
        0. => (partials[j].gg).gain;
        
        /*        
        bwgs[partials[j].bwgNumber] =< partials[j].e;
        partials[j].gg =< dac.chan(partials[j].channel);
        partials[j].s =< partials[j].gg;
        partials[j].e =< partials[j].gg;
        */        
        // kill partial connections here in the same way that they're killed in partial
        bwgs[thisBwgNumber] =< partials[j].p;
        partials[j].p =< partials[j].e;
        partials[j].e =< partials[j].gg;
        partials[j].gg =< envelopes[ thisChannel ];
        
        0 => (partials[j].s).gain;
        partials[j].s =< partials[j].gg;
        1 => (partials[j].gg).op;
        /*        
        bwgs[bwgNumber] =< p;
        p =< e;
        e =< gg;
        gg =< envelopes[channel];                               
        0 => s.gain;
        s =< gg;
        1 => gg.op;             
        */        
        // TESTING COMMENTED THESE OUT FOR -1 BUG  
        // clean up partial and bwg
        partials[j].clearPartial(3);            
        partials[j].clearBwg();                                 
        
        0 => partials[j].cleaning;
        
    }
    
    10::ms => now;    
}

// ---------------------------------------------------------------------
// every n-ms step through table of notes/partials played, 
// check their starting time and duration to their proposed ending time, 
// and end them if they're too long
// ---------------------------------------------------------------------
fun void fixer_partials()
{
    Partial currentPartial;
    0 => int i;
    
    while(true)
    {
        if(hold==0)
        {
            i%partialCount => int j;
            
            now - partials[j].startTime => dur elapsedTime;        
            
            if(elapsedTime >= partials[j].fileDuration && freePartials[j]==1 && partials[j].cleaning == 0 && partials[j].midi == 0)
            {            
//                <<< "FIXER: Clearing Partial: ", j, "eTime: ", elapsedTime >>>;
                1 => partials[j].cleaning;
                
                // CHANGED FROM SPORK DEBUGGING -1 BUG          
                spork ~ killPartial(j);
                ///            killPartial(j);            
                
                /*
                for(0=>int k; k<partials.size(); k++)
                {
                    chout <= "fixer_partials(): freePartials[" +  k + "] " <= freePartials[k] <= " gain: " <= partials[k].gg.gain() <= "\n";
                }
                */
            }        
            
            i++;
        } else {
            //         <<< "fixer: holding......." >>>;   
        }
        
        10::ms => now;        
    }    
    
    1::day => now;
}

/*
*
* Array of Cell objects to contain each "trouble"
*
*/
class Cell {
    int index;     // index in main note array that starts the cell
    int size;              // number of notes in this cell (from startingIndex to last note)
    
    fun void set(int lIndex, int lSize)
    {
        lIndex => index;
        lSize => size;
    }
}

Cell cells[108];

// each cell has a starting index and a size (number of notes)
cells[0].set(0, 68);//119);
cells[1].set(68, 48);
cells[2].set(119, 53);
cells[3].set(172, 67);
cells[4].set(239, 27);
cells[5].set(269, 22);
cells[6].set(291, 31);
cells[7].set(322, 9);
cells[8].set(331, 81);
cells[9].set(412, 55);
cells[10].set(467, 53);
cells[11].set(524, 41);
cells[12].set(565, 112);
cells[13].set(677, 64);
cells[14].set(741, 97);
cells[15].set(838, 101);
cells[16].set(939, 7);
cells[17].set(946, 54);
cells[18].set(1002, 46);
cells[19].set(1048, 107);
cells[20].set(1155, 41);
cells[21].set(1196, 61);
cells[22].set(1257, 28);
cells[23].set(1285, 113);
cells[24].set(1398, 104);
cells[25].set(1502, 14);
//
cells[26].set(0, 14);
/*
*  Channels
*
*/
class Channel
{
    int id;
    int send_osc;
    
    float home_azimuth;          // (-180.0 to 180.0)
    float home_distance;         // 0.1 to 100. meters
    float home_yaw;              // (-180.0 to 180.0)  0 always faces listener
    float home_aperture;         // 10.0 to 180.0
    float home_position[3];      // x,y,z    
    
    float azimuth;    
    float distance;   
    float yaw;        
    float aperture;   
    float position[3];
    
    float target_azimuth;          // (-180.0 to 180.0)
    float target_distance;         // 0.1 to 100. meters
    float target_yaw;              // (-180.0 to 180.0)  0 always faces listener
    float target_aperture;         // 10.0 to 180.0
    float target_position[3];      // x,y,z                
    
    // takes channel index as input
    // - retrieves position data from hard-coded channelPositions[] array
    fun void init(int index)
    {
        
        
        
    }       
    
    fun int setAzimuth(float val)
    {
        val => target_azimuth => azimuth;
        //        <<< "setting [",id,"].azimuth and target_azimuth: ", azimuth, target_azimuth >>>;
        
        return 0;
    }
    
    fun void setDistance(float val)
    {
        val => target_distance => distance;
        //        <<< "setting [",id,"].distance and target_distance: ", distance, target_distance >>>;        
    }       
    
    fun int sendOsc()
    {
        if( ( Math.round(target_distance) != Math.round(distance) ) || ( Math.round(target_azimuth) != Math.round(azimuth) ) )
            1 => send_osc;
        else
            0 => send_osc;
        
        return send_osc;
    }
    
}

// create array of channels
Channel outputChannels[channelCount];

/*
az, dist, yaw, ap, x, y, z
*/
1.0 => float default_dist;
0. => float default_yaw;
80. => float default_aperture;

[
[-90.0, default_dist, default_yaw, default_aperture, -1.0, -0., 0.],
[-84.4, default_dist, default_yaw, default_aperture, -1.0, 0.1, 0.],
[-78.7, default_dist, default_yaw, default_aperture, -1.0, 0.2, 0.],
[-73.1, default_dist, default_yaw, default_aperture, -1.0, 0.3, 0.],
[-67.5, default_dist, default_yaw, default_aperture, -0.9, 0.4, 0.],
[-61.9, default_dist, default_yaw, default_aperture, -0.9, 0.5, 0.],
[-56.2, default_dist, default_yaw, default_aperture, -0.8, 0.6, 0.],
[-50.6, default_dist, default_yaw, default_aperture, -0.8, 0.6, 0.],
[-45.0, default_dist, default_yaw, default_aperture, -0.7, 0.7, 0.],
[-39.4, default_dist, default_yaw, default_aperture, -0.6, 0.8, 0.],
[-33.8, default_dist, default_yaw, default_aperture, -0.6, 0.8, 0.],
[-28.1, default_dist, default_yaw, default_aperture, -0.5, 0.9, 0.],
[-22.5, default_dist, default_yaw, default_aperture, -0.4, 0.9, 0.],
[-16.9, default_dist, default_yaw, default_aperture, -0.3, 1.0, 0.],
[-11.3, default_dist, default_yaw, default_aperture, -0.2, 1.0, 0.],
[-5.60, default_dist, default_yaw, default_aperture, -0.1, 1.0, 0.],
[0.00, default_dist, default_yaw, default_aperture, 0.0, 1.0, 0.],
[5.60, default_dist, default_yaw, default_aperture, 0.1, 1.0, 0.],
[11.3, default_dist, default_yaw, default_aperture, 0.2, 1.0, 0.],
[16.9, default_dist, default_yaw, default_aperture, 0.3, 1.0, 0.],
[22.5, default_dist, default_yaw, default_aperture, 0.4, 0.9, 0.],
[28.1, default_dist, default_yaw, default_aperture, 0.5, 0.9, 0.],
[33.8, default_dist, default_yaw, default_aperture, 0.6, 0.8, 0.],
[39.4, default_dist, default_yaw, default_aperture, 0.6, 0.8, 0.],
[45.0, default_dist, default_yaw, default_aperture, 0.7, 0.7, 0.],
[50.6, default_dist, default_yaw, default_aperture, 0.8, 0.6, 0.],
[56.2, default_dist, default_yaw, default_aperture, 0.8, 0.6, 0.],
[61.9, default_dist, default_yaw, default_aperture, 0.9, 0.5, 0.],
[67.5, default_dist, default_yaw, default_aperture, 0.9, 0.4, 0.],
[73.1, default_dist, default_yaw, default_aperture, 1.0, 0.3, 0.],
[78.7, default_dist, default_yaw, default_aperture, 1.0, 0.2, 0.],
[84.4, default_dist, default_yaw, default_aperture, 1.0, 0.1, 0.],
[90.0, default_dist, default_yaw, default_aperture, 1.0, 0.0, 0.]
] @=> float channelPositions[][];

[31, 29, 27, 25, 23, 21, 19, 17, 15, 13, 11, 9,
7, 5, 3, 1, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18,
20, 22, 24, 26, 28, 30, 32] @=> int centerMirrorPattern[];

[ 0, 2, 4, 6, 8, 10, 12, 14, 16, 18,
20, 22, 24, 26, 28, 30, 31, 29, 27,
25, 23, 21, 19, 17, 15, 13, 11, 9, 7, 5, 3, 1] @=> int outwardMirrorPattern[];


// array of positions to be used as "targets" for the piece
[
[123.4, 0.6],
[90.0, 0.3],
[ 0.00, 0.0],
[0.0, 0.0]
] @=> float targetPositions[][];


// azimuth interpolation
fun void slewAzimuth(int i)
{        
    0.005 => float slew_amount;    
    
    while(true)
    {
        //if( Math.round(outputChannels[i].target_azimuth) != Math.round(outputChannels[i].azimuth) )           
        //            <<< "slewing[", i, "]: target_azimuth: ", outputChannels[i].target_azimuth, ", azimuth: ", outputChannels[i].azimuth >>>;        
        
        (( outputChannels[i].target_azimuth - outputChannels[i].azimuth) * slew_amount + outputChannels[i].azimuth) => outputChannels[i].azimuth;
        50::ms => now;        
    }   
    
    10::day => now;
}

fun void slewDistance(int i)
{        
    0.005 => float slew_amount;    
    
    while(true)
    {
        //        <<< "slewing[", i, "]: target_distance: ", outputChannels[i].target_distance, ", distance: ", outputChannels[i].distance >>>;                
        (( outputChannels[i].target_distance - outputChannels[i].distance) * slew_amount + outputChannels[i].distance) => outputChannels[i].distance;
        50::ms => now;        
    }   
    
    10::day => now;
}

fun void setChannelPositions(int set)
{
    if(set == 0)        
        initChannelPositions();       // default init set
    else if(set == 1)
        alternateChannelPositions(centerMirrorPattern); // alternate r and l source positions
    else if(set == 2)
        alternateChannelPositions(outwardMirrorPattern); // start 0 at center, alternate outward    
}


fun void alternateChannelPositions(int array[])
{
    for(0=>int j; j<channelCount; j++)
    {
        array[j] => int i;
        
        // i => outputChannels[i].id;  
        outputChannels[i].setAzimuth(channelPositions[i][0]);     
        channelPositions[i][0] => outputChannels[i].home_azimuth => outputChannels[i].azimuth => outputChannels[i].target_azimuth;                   
        
        if(osc_default_distance == 0)
        {
            outputChannels[i].setDistance(channelPositions[i][1]);
            channelPositions[i][1] => outputChannels[i].home_distance => outputChannels[i].distance => outputChannels[i].target_distance;                      
        }
        else
        {
            outputChannels[i].setDistance(osc_default_distance);
            osc_default_distance => outputChannels[i].home_distance => outputChannels[i].distance => outputChannels[i].target_distance;                      
        }        
    }    
}

// initalize channel positions
fun void initChannelPositions()
{
    //    <<< "channelCount: ", channelCount >>>;
    
    // build batch string for spat~
    string batch;    
    
    for(0=>int i; i<channelCount; i++)
    {
        // init channel with a permanent home location (around a semi-circle) and a current location
        i => outputChannels[i].id;
        
        //working - why doesn't distance and azimuth get set here???
        outputChannels[i].setAzimuth(channelPositions[i][0]);
        //         outputChannels[i].setDistance(channelPositions[i][1]);
        
        channelPositions[i][0] => outputChannels[i].home_azimuth => outputChannels[i].azimuth => outputChannels[i].target_azimuth;                  
        
        if(osc_default_distance == 0)
        {
            outputChannels[i].setDistance(channelPositions[i][1]);
            channelPositions[i][1] => outputChannels[i].home_distance => outputChannels[i].distance => outputChannels[i].target_distance;                      
        }
        else
        {
            outputChannels[i].setDistance(osc_default_distance);
            osc_default_distance => outputChannels[i].home_distance => outputChannels[i].distance => outputChannels[i].target_distance;                      
        }
        //         batch + "source " + Std.itoa(i+1) + " az " + channelPositions[i][0] => batch; 
        //         batch + ", source " + Std.itoa(i+1) + " dist " + channelPositions[i][1] => batch;         
        
        //         if(i < channelCount-1)
        //             batch + ", " => batch;
        
        //        channelPositions[i][0] => outputChannels[i].home_azimuth => outputChannels[i].azimuth => outputChannels[i].target_azimuth;         
        //        channelPositions[i][1] => outputChannels[i].home_distance => outputChannels[i].distance => outputChannels[i].target_distance;
        
        //        channelPositions[i][2] => outputChannels[i].home_yaw => outputChannels[i].yaw;
        //        channelPositions[i][3] => outputChannels[i].home_aperture => outputChannels[i].aperture;
        //        channelPositions[i][4] => outputChannels[i].home_position[0] => outputChannels[i].position[0];
        //        channelPositions[i][5] => outputChannels[i].home_position[1] => outputChannels[i].position[1];
        //        channelPositions[i][6] => outputChannels[i].home_position[2] => outputChannels[i].position[2];                     
    }    
    
    // time buffer
    //5000::ms => now;
    //<<< "Calculating channel positions..." >>>;
    
    //    <<< batch >>>;
    /*    
    xmit.start( "/batch");            
    batch => xmit.add;       // azimuth
    xmit.send();            
    1::samp => now;            
    */    
}




/*
targetPositions[0][0] => outputChannels[0].target_azimuth;
5::second => now;
targetPositions[1][0] => outputChannels[0].target_azimuth;
20::second => now;
targetPositions[0][0] => outputChannels[0].target_azimuth;
//me.exit();
*/




/*
*
* Note Object
*
*/
class Note
{
    int index;
    int pitch;
    int velocity;
    
    int midi; // 1 = was created by live midi input; 0 = generated note
    int midi_on;
    int midi_hold;  // to keep Note shred alive on held MIDI notes
    
    float timeOn;
    time startTime;
    float duration;
    dur release;
    
    Channel myChannel;
    
    string filename;       
    string filepath;
    //    0.6 => float filegain;
    1.0 => float filegain;
    
    dur fileDuration;
    dur calcDuration;          // duration calculated to account for envelope timing
    
    int channel;
    
    float position[3];         // x,y,z position for this note in 3D space
    
    int dirty;                 // when a note has already been played it is "dirty" until cleaned
    int activated;             
    
    SndBuf buf;    
    ADSR e;
    Gain g;
    
    dur adsr_a;
    dur adsr_d;
    float adsr_s;
    dur adsr_r; // set in set function
    
    //buf => e => g;           
    
    fun void activate(int midi_input)
    {
        1 => activated;
        1 => dirty;
        
        // if midi input
        setMidiNote(midi_input);
    } 
    
    fun void deactivate()
    {
        0 => activated;     
        0 => midi;
        launchTime => startTime;
        
    }
    
    fun void setPosition(float x, float y, float z)
    {
        setPositionX(x);
        setPositionY(y);
        setPositionZ(z);
    }
    
    fun float[] getPosition()
    {
        return position;    
    }
    
    fun void setPositionX(float x)
    {
        x => position[0];   
    }
    
    fun void setPositionY(float y)
    {
        y => position[1];   
    }
    
    fun void setPositionZ(float z)
    {
        z => position[2];   
    }    
    
    fun void setMidiNote(int midi_input)
    {
        midi_input => midi;
        midi_input => midi_on;
    }
    
    fun void set(int thisChannel, float lFileGain)
    {    
        //1.0 => g.gain;
        //1.0 => buf.gain;
        
        //        <<< "Note.set()" >>>;
        buf => e => g;      
                  
        myChannel.init(thisChannel);
        
        // set gain for file playback (from global scoped in main)
        lFileGain => filegain;
        
        // WHICH DURATION WORKS FOR US HERE: duration SHOULD BE THE VALUE FROM MIDI (RECORDED INTO LOG). fileDuration IS TOO LONG AND NOT WHAT WE WANT UNLESS FILES ARE TRIMMED
        dur usedDuration;
        //duration => usedDuration;
        fileDuration => usedDuration;
        
        thisChannel => channel;
        
        now =>startTime;
        
        if(usedDuration > envelopeRelease)
            envelopeRelease => release;
        else
            usedDuration => release; // this is a hack for now... doesn't give what we want
        
        //        if(fileDuration > envelopeRelease)
        //            envelopeRelease => release;
        //        else
        //            fileDuration*0.8 => release;
        
        10::ms => adsr_a;
        8::ms => adsr_d;
        1.0 => adsr_s;
        release => adsr_r; 
        
        // THIS DURATION IS TOO LONG.. FILE DURATION NOT WHAT WE WANT, CALCULATED DURATION SHOULD COME FROM MIDI NOTE LENGTH IN THE SOURCE FILE
        usedDuration - adsr_r => calcDuration;
        //fileDuration - adsr_r => calcDuration;
        
        e.set( adsr_a, adsr_d, adsr_s, adsr_r);                
    }
    
    fun void what(dur val)
    {
        while(true)
        {
            <<< ".......... what() ... channels[",channel,"] = ", channels[channel] >>>;         
            1::ms => now;    
        }
        
        val => now;
        
    }
    
    fun void play()
    {              
        //        <<< "Note.play.gPlayFileFlag: ", gPlayFileFlag >>>;
        channel => int thisChannel;
        
        if(gPlayFileFlag==1)
        {       

            channels[thisChannel] + 1 => channels[thisChannel];     // increment channel count                      
            //            <<< "Note.play() incrementing, pitch = ", pitch, ", channels[",channel,"] = ", channels[channel] >>>;     
            
            //            g => dac.chan(channel);                        
            g => envelopes[thisChannel] => dac.chan(thisChannel);            
                                    
            filegain => g.gain;
                       
            channelGains[thisChannel] + g.gain() => channelGains[thisChannel];        
            
            now => notePlay;
        
            e.keyOn();   
            
            filepath => buf.read;                        
            me.yield();
            
            calcDuration => now;

            while(hold==1)
            {
                //                <<< "HOLDING.........: ", hold, " pitch=", pitch >>>;
                100::ms=>now;
            }
            
            //            <<< "Note.play.keyOff()..........." >>>;            
            e.keyOff();                    
            
            //            <<< "Note.play() decrementing, pitch = ", pitch, ", channel = ", channel, ", channels[channel] = ", channels[channel] >>>;                                     
            channels[thisChannel] - 1 => channels[thisChannel];     // decrement channel count        
            channelGains[thisChannel] - g.gain() => channelGains[thisChannel];  
            
            adsr_r => now;          
            
            0 => g.gain;            
            
            deactivate();      
            
            // kill adsr here
            buf =< e;
            e =< g;            
            //            g =< dac.chan(thisChannel);
            g =< envelopes[thisChannel];            
            
            //        null @=> e;
            //        null @=> buf;            
            // mark note as done "playing"
            0 => midiNotes[pitch-1];                    
        }          
    }            
    
    fun void clear()
    {       
        channel => int thisChannel;
        
        0 => g.gain;            
        
        deactivate();      
        
        buf =< e;
        g =< dac.chan(thisChannel);            
        e =< g;
        
        null @=> e;
        null @=> buf;          
    }
    
}

// init array of Notes
Note notes[0];

// init array of rhythms (durations)
float rhythms[0];



/*
fun void clearNote(int index, dur wait)
{
    <<< "clearNote ----- after disconnect" >>>;                                    
    
    0 => notes[index].g.gain;            
    
    notes[index].deactivate();      
    
    notes[index].buf =< notes[index].e;
    notes[index].g =< dac.chan(notes[index].channel);            
    notes[index].e =< notes[index].g;
    
    null @=> notes[index].e;
    null @=> notes[index].buf;  
    
    1000::ms => now;                          
}
*/
fun void fixer_notes()
{
    Note currentNote;
    0 => int i;
    
    while(true)
    {
        i%notes.size() => int j;
        
        if(notes[j].startTime > launchTime)
        {
            now - notes[j].startTime => dur elapsedTime;
            
            <<< "Note[", j, "] elapsed Time: ", elapsedTime, " fileDuration: ", notes[j].fileDuration, " = ", (notes[j].fileDuration - elapsedTime), ", activated = ", notes[j].activated  >>>;            
            
            if(notes[j].activated == 1 && (notes[j].fileDuration - elapsedTime) <= 0::samp)
            {
                channels[notes[j].channel] - 1 => channels[notes[j].channel];     // decrement channel count        
                channelGains[notes[j].channel] - notes[j].g.gain() => channelGains[notes[j].channel];  
                
                0 => notes[j].g.gain;                        
                notes[j].deactivate();                  
                notes[j].g =< dac.chan(notes[j].channel);                                                    
            }                        
        }
        
        i++;
        
        10::ms => now;
    }    
}

class Partial
{
    int id;                // unique identifier for this partial
    int index;             // index for this partial in freePartials[] array
    int partialNumber;
    int bwgNumber;
    
    1 => int type;         // default value of 1 == integer multiple
    
    int midi;              // 1 = was created by live midi input; 0 = generated note
    int midi_on;
    //    int midi_hold;
    int note_index;
    Event midiEvent;
    
    dur duration;
    dur fileDuration;
    dur calcDuration;          // duration calculated to account for envelope timing
    
    int pitch;
    float freq;
    int volume;
    
    gPitchShift => float pitchShift;
    
    dur release;
    
    0 => int cleaning;          // flag for clean up
    int channel;
    
    float position[3];
    
    time startTime;
    
    // parent Note 
    Note parent;
    int parentIndex;
    int parentPitch;
    int parentVelocity;
    int parentPosition[3];
    
    // next parent/target Note
    Note target;
    int targetIndex;
    int targetPitch;
    int targetVelocity;
    int targetPosition[3];   
    
    // FM parameters
    int FMOn;
    
    ADSR e;
    dur adsr_a;
    dur adsr_d;
    float adsr_s;
    dur adsr_r; // set in set function
    
    Gain gg;
    SinOsc s;    
    PitShift p;
    
    //    bwgs[bwgNumber] => p => e => gg => envelopes[channel] => dac.chan(channel);
    p => e => gg;
    
    // midi note intervals for chords (4 note by default)        
    // steps from "root" or pitch of given note; 4th value is a bass note (optional)
    [4, 7, 12, -12] @=> int major_chord_intervals[];
    [3, 7, 12, -12] @=> int minor_chord_intervals[];
    [4, 7, 11, -12] @=> int seventh_chord_intervals[];   
    
    // params to randomize bwg and ring mod params    
    gRandomize_bwg_params => int randomize_bwg_params;
    gUse_ring_modulator => int use_ring_modulator;
    gRandomize_ring_params => int randomize_ring_params;
    gRing_frequency => float ring_frequency;
    
    fun void setPosition(float x, float y, float z)
    {
        setPositionX(x);
        setPositionY(y);
        setPositionZ(z);
    }
    
    fun float[] getPosition()
    {
        return position;    
    }
    
    fun void setPositionX(float x)
    {
        x => position[0];   
    }
    
    fun void setPositionY(float y)
    {
        y => position[1];   
    }
    
    fun void setPositionZ(float z)
    {
        z => position[2];   
    }    
    
    fun void reset()
    {        
        // extra to fix bug
        0. => bwgs[bwgNumber].gain;
        1. => bwgs[bwgNumber].stopBowing;
        1. => p.shift;
        0. => p.mix;    
        
        -1 => id, index, partialNumber, bwgNumber, pitch, volume, freq;
        -1 => channel;
        0 => parentIndex, parentPitch, parentVelocity, parentPosition[0], parentPosition[1], parentPosition[2];
        0 => targetIndex, targetPitch, targetVelocity, targetPosition[0], targetPosition[1], targetPosition[2];
        0 => position[0], position[1], position[2];
        0.0 => gg.gain;
        //0::ms => duration, fileDuration, calcDuration, release;      
        
        
        
        
        // bug: clearing values here helps with bug (popping sounds on Partial reuse) but doesn't fix
        //     _must_ reconnect p => e => gg here
        /*
        ADSR tempADSR => e;
        dur tempAdsr_a => adsr_a;
        dur tempAdsr_d => adsr_d;
        float tempAdsr_s => adsr_s;
        dur tempAdsr_r => adsr_r; // set in set function        
        Gain tempGg => gg;
        SinOsc tempS => s;    
        PitShift tempP => p;        
        gPitchShift => pitchShift;
        
        0::ms => adsr_a;
        20::ms => adsr_d;
        1 => adsr_s;
        release => adsr_r;               
        e.set( adsr_a, adsr_d, adsr_s, adsr_r);   
        */     
        
        // hack
        //p => e => gg;
        
        setMidiNote(0);
        
    }
    
    //    0=>int mycount;
    
    fun void play(int noteIndex)
    {
        // channel can be reset before play is complete... process this locally so it finishes
        channel => int thisChannel;
        
        noteIndex => note_index;
        
        //        <<< "Partial.play() .... start partial play... pitch: ", pitch, ", channel: ", channel >>>;                
        
        if(channel > -1)
        {           
            
            channelGains[thisChannel] + gg.gain() => channelGains[thisChannel];          
            
            if(playPartialFlag==1)
            {                                
                now => partialPlay;
                
                e.keyOn();    
                
                1.0 => bwgs[bwgNumber].startBowing; 
                1.0 => bwgs[bwgNumber].gain;                                                     
                
                // if not midi, kill partial here after appropriate duration
                // if midi, handle note off event elsewhere ( )
                if(midi == 0)              
                {                    
                    while (hold==1)
                    {                                                
                        100::ms => now;   
                    }
                    
                    calcDuration => now;                    
                    
                    e.keyOff();               
                    
                    //                    mycount+1=>mycount;
                    
                    adsr_r => now;
                    
                    1. => bwgs[bwgNumber].stopBowing;
                    
                    
                    0. => gg.gain;
                    0. => bwgs[bwgNumber].gain;
                    
                    // disconnect
                    // gg =< dac.chan(channel);                
                    // bwgs[bwgNumber] =< e;
                    // e =< gg;
                    
                    bwgs[bwgNumber] =< p;
                    p =< e;
                    e =< gg;
                    gg =< envelopes[thisChannel];                       
                    
                    //                    <<< "Partial.play() disconnected, channel: ", channel, ", bwg: ", bwgNumber >>>;        
                    
                    0 => s.gain;
                    s =< gg;
                    1 => gg.op;                        
                    
                    channelGains[thisChannel] - gg.gain() => channelGains[thisChannel];                                                                              
                    channels[thisChannel] - 1 => channels[thisChannel];     // decrement channel count 
                    
                    //                    <<< "YYYYYYY - pitch: ", pitch, ", channels[", channel, "]: ", channels[channel] >>>;                    
                    
                    //                    <<< "here: decrementing channel=", channel, ", channels[channel]", channels[channel] >>>;
                    
                    // clean up partial and bwg
                    clearPartial(1);
                    clearBwg();  
                    
                    //                <<< "Partial.play() cleared... pitch:", pitch >>>;                            
                } else {
                    
                    // if midi = 1 then set Note midi_hold flag to keep Note shred alive until MIDI key is released
                    1 => notes[noteIndex].midi_hold;
                }
            }        
            
        } else {
            <<< "PARTIAL NOT PLAYED --- PARTIAL CHANNEL = ", thisChannel >>>; 
            
            // clean up partial and bwg
            clearPartial(5);
            clearBwg();                
        }            
    }
    
    fun void midi_play(Event midiEvent)
    {
        
        <<< "sporking shred midi_play">>>;
        
        /*
        1 => midi_hold;
        
        while(midi_hold==1)
        {
            <<< "midi_hold ==", midi_hold >>>;
            
            10::ms => now;   
        }
        <<< "After midi_hold=", midi_hold>>>;        
        */
        midiEvent => now;
        
        <<< "After midiEvent - midi_play">>>;        
        1::samp => now;
        
        //        e.keyOff();               
        
        <<< "Partial.midi_play() e.keyOff()" >>>;        
        
        //        if(midi == 1)
        //          adsr_r => now;
        //        else 
        //        {         
        //            while (hold==1)
        //            {
        //                <<<"(partial) holding.......... pitch=", pitch>>>;
        //                100::ms => now;   
        //            }
        //        }
        
        e.keyOff(); 
        adsr_r => now;
        
        1. => bwgs[bwgNumber].stopBowing;
        
        0. => gg.gain;
        0. => bwgs[bwgNumber].gain;
        
        //         bwgs[bwgNumber] => p => e => gg => envelopes[channel] => dac.chan(channel);
        // disconnect
        //        gg =< dac.chan(channel);                
        //        bwgs[bwgNumber] =< e;
        //        e =< gg;
        bwgs[bwgNumber] =< p;
        p =< e;
        e =< gg;
        gg =< envelopes[channel];                
        
        0 => s.gain;
        s =< gg;
        1 => gg.op;                        
        
        channelGains[channel] - gg.gain() => channelGains[channel];                  
        
        channels[channel] - 1 => channels[channel];     // decrement channel count 
        
        <<< "Partial.midi_play() - channels[", channel, "]: ", channels[channel] >>>;                    
        
        
        // clean up partial and bwg
        clearPartial(2);
        clearBwg(); 
        
        // release note Shred
        0 => notes[note_index].midi_hold;          
        
    }
    
    fun void setMidiNote(int midi_input)
    {
        //        <<< "Partial.setMidiNote(", midi_input, ")">>>;
        
        midi_input => midi;
        midi_input => midi_on;        
    }        
    
    //                 <<<"setPartials()... channels[", channel, "]=", channels[channel] >>>;  
    //            partials[freePartial].set( noteIndex, freePartial, pitch, channel, thisFileDuration, i+1, freeBwg, midi_input );     
    
    fun void set(int noteIndex, int thisIndex, int thisPitch, int thisChannel, dur thisFileDuration, int thisPartialNumber, int thisBwgNumber, int midi_input)
    {                
        // TESTING TYPE SETTINGS
        1 => type;
        gPartialChordType => type;
        
        setMidiNote(midi_input);
        
        thisChannel => channel;
        
        thisIndex => index;
        noteIndex => parentIndex;
        thisPitch => pitch;
        //        thisDuration => duration;
        thisPartialNumber => partialNumber;
        thisBwgNumber => bwgNumber;
        
        //notes[parentIndex].fileDuration => fileDuration;
        thisFileDuration => fileDuration;
        now =>startTime;        
        
        if(fileDuration > envelopeRelease)
            envelopeRelease => release;
        else
            fileDuration*0.8 => release;
        
        0::ms => adsr_a;
        20::ms => adsr_d;
        1 => adsr_s;
        release => adsr_r;               
        
        fileDuration - adsr_r => calcDuration;
        
        if(debug) chout <= "Partial.set()... \n";
        
        //bwgs[bwgNumber] => e => gg => dac.chan(channel);
        
        // try pitch shifting here
        //        bwgs[bwgNumber] => p => e => gg => dac.chan(channel);
        
        // adding envelope for sample and hold
        // MOVING TO INIT
        //bwgs[bwgNumber] => p => e => gg => envelopes[channel] => dac.chan(channel);
        bwgs[bwgNumber] => p;// => e => 
        gg => envelopes[channel];// => dac.chan(channel);        
        
        gEnvelopeGain => envelopes[channel].value; // why does amp get so hot with envelopes added?
        
        1. => p.mix;
        gPitchShift => pitchShift;
        pitchShift => p.shift;
        
        1 => gg.gain;
        
        gPartialGain => gg.gain;      
        
        //        if(debug) chout <= "\t Partial.set::gg.gain: " <= gg.gain() <= "\n";
        
        1 => bwgs[bwgNumber].preset;        
        //3 => bwgs[bwgNumber].preset; // prayer bowl        
        
        bwgs[bwgNumber].controlChange(11, 20);
        
        if(midi == 1) 
        {
            1 => randomize_bwg_params;
            1 => use_ring_modulator;
            1 => randomize_ring_params;
            5 => ring_frequency;
        }
        
        if(use_ring_modulator == 1)
        {
            ring_frequency => s.freq;
            
            if(randomize_ring_params == 1)
            {
                // Ring Modulator
                if(Math.random2(1,3) == 3) {
                    1 => s.gain;
                    s => gg;
                    Math.random2(0,10) => s.freq;
                    3 => gg.op;
                } else {
                    1 => gg.op;
                    s =< gg;
                    0 => s.gain;            
                }            
            } else {
                1 => gg.op;
                s =< gg;
                0 => s.gain;                            
            }
        }
        
        if(randomize_bwg_params == 1)
        {                        
            bwgStrikePosition + Math.random2f(-0.1, 0.1) => bwgs[bwgNumber].strikePosition;
            bwgBowPressure + Math.random2f(-0.03, 0.03) => bwgs[bwgNumber].bowPressure;
            bwgBowRate + Math.random2f(-0.1, 0.1) => bwgs[bwgNumber].bowRate;            
        } else {
            
            // default settings            
            bwgStrikePosition => bwgs[bwgNumber].strikePosition;
            bwgBowPressure => bwgs[bwgNumber].bowPressure;
            bwgBowRate => bwgs[bwgNumber].bowRate;                        
        }        
        
        // check partial type variable and return frequency of chord/partial set
        getBwgFrequency(pitch, partialNumber) => bwgs[bwgNumber].freq;               
        
        //        <<< "partials.set... bwgs[", bwgNumber, "].freq = ", bwgs[bwgNumber].freq() >>>;
        
        e.set( adsr_a, adsr_d, adsr_s, adsr_r);        
        
        if(midi_input == 1) {
            spork ~ midi_play(midiEvent);
        } 
        
    }         
    
    fun void clearPartial(int source) 
    {
        0 => freePartials[index];            
        reset();
    }
    
    fun void clearBwg() {
        0 => freeBwgs[index]; 
    }     
    
    fun float getBwgFrequency(float pitch, int partialNumber)
    {
        float freq_value;

        // 0 randomizes choice
        if(type == 0)
            Math.random2(1, 5) => type;
        
//        <<< "chord type: ", type >>>;
        
        // use partial_type variable to choose which type of partial (integer multiple, chord type)
        if(type == 1)
        {
            // partials (integer multiples)
            Std.mtof(pitch)*partialNumber => freq_value;
        } else if(type == 2){
            // random within 1 octave
            Std.mtof(pitch + Math.random2(1, 11) + partialNumber*12) => freq_value;
        } else if(type == 3){            
            // major chord
            //            <<< "getBwgFrequency: Major Chord, partial number: ", partialNumber, ", pitch: ", pitch, ", partial midi: ", pitch + (major_chord_intervals[partialNumber-1]) >>>;             
            Std.mtof(pitch + (major_chord_intervals[partialNumber-1]) ) => freq_value;
        } else if(type == 4){            
            // minor chord
            Std.mtof(pitch + (minor_chord_intervals[partialNumber-1]) ) => freq_value;
        } else if(type == 5){ 
            Std.mtof(pitch + (seventh_chord_intervals[partialNumber-1]) ) => freq_value;
        }

        return freq_value;
    }
    /*    
    fun void slew_freq()
    {        
        // the slew
        0.005 => float slew;
        // go
        while( true )
        {
            // slew
            ((pitch_target - pitch) * slew + pitch) => pitch;
            // wait
            5::ms => now;
        }
    }        
    */
    
}




fun void readFile()
{
    if(debug) chout <= "readFile()..." <= "\n";
    
    StringTokenizer tok;    
    int fileLineCount;
    
    // instantiate
    FileIO fio;
    
    // open a file
    fio.open( filename, FileIO.READ );
    //<<< "filename: ", filename >>>;
    // ensure it's ok
    if( !fio.good() )
    {            
        cherr <= "can't open file: " <= filename <= " for reading..." <= IO.nl();
        me.exit();
    }
    
    int lineCount;
    // get linecount from file first, populate with empty note objects (lets us order by index)
    while( fio.more() )
    {
        fio.readLine();
        notes << new Note;
    }
    
    fio.open( filename, FileIO.READ );
    
    SndBuf buf;
    
    -1 => int lastIndex;
    
    
    int fcount;
    
    while( fio.more() )
    {        
        tok.set( fio.readLine() );
        tok.next().toInt() => int index;    // get index first
        
        // remove trailing 0 index issue from data file
        if(index > lastIndex)
        {
            index => notes[index].index;
            tok.next().toInt() => notes[index].pitch;
            tok.next().toInt() => notes[index].velocity;
            tok.next().toFloat() => notes[index].timeOn;
            tok.next().toFloat() => notes[index].duration;
            tok.next().toString() => notes[index].filename;   
            me.sourceDir() + fileFolder + notes[index].filename => notes[index].filepath;  
            
            // write duration to an array for rhythmic patterns
            rhythms << notes[index].duration;
            
            launchTime => notes[index].startTime;
            
            notes[index].filepath => buf.read;    
            buf.length() => notes[index].fileDuration;  
            
            // build chord + note order of "real" playback
            setPlaybackOrder(index);
            
            index => lastIndex;
            
            fcount++;
        }
        
        //        if(index == inputlimit)
        //            break;
        /*
        if(fcount==226)
        {
            <<< "notes[", index, "].filepath:", notes[index].filepath >>>;
            break;
        }
        if(fcount==227)
        {
            <<< "notes[", index, "].filepath:", notes[index].filepath >>>;
            //me.exit();
        }
        */
        //        if(fcount==1500)
        //            me.exit();
    }       
}

0 => float lastTimeOn;

fun void setPlaybackOrder(int index)
{   
    if(notes[index].timeOn == lastTimeOn)    
        notes[index].timeOn => lastTimeOn;
}

// This gets triggered if input rows are out of order in source file
fun void testFileData()
{
    0 => int exit;
    
    for(0=>int i; i<notes.size();i++)
    {                
        if(notes[i].filename.length() == 0)
        {
            chout <= "---------------------------\n";            
            chout <= "---- INPUT FILE ERROR -----" <= "\n";
            chout <= "---- ROW # " <= i <=  "\n";
            chout <= "---- FILENAME EMPTY \n";            
            chout <= "---------------------------\n";   
            1 => exit;
        }
    }
    
    if(exit==1)
        me.exit();    
}

// debug values
fun void printFile()
{
    if(debug) chout <= "printFile()..." <= "\n";
    
    chout <= "notes.size(): " + notes.size() <= "\n";    
    
    for(0=>int i; i<notes.size();i++)
    {
        chout <= "i: " + i <= "\n";
        chout <= "index: " + notes[i].index <= "\n";
        chout <= "pitch: " + notes[i].pitch <= "\n";
        chout <= "velocity: " + notes[i].velocity <= "\n";        
        chout <= "timeOn: " + notes[i].timeOn <= "\n";                
        chout <= "duration: " + notes[i].duration <= "\n";                        
        chout <= "filename: " + notes[i].filename <= "\n";                                
    }
}



fun int getFreePartial()
{
    if(debug) chout <= "getFreePartial()..." <= "\n";    
    
    -1 => int returnVal;
    
    (lastFreePartial + 1)%freePartials.size() => int nextPartial;    
    
    if(debug) chout <= "getFreePartial()... nextPartial=" <= nextPartial <= "\n";    
    
    if(freePartials[ nextPartial ] == 0)
        nextPartial => returnVal;        
    else {
        for( 0 => int i; i<freePartials.size(); i++)
        {
            if(freePartials[i] == 0)
            {
                i => returnVal;
                break;
            }
        }        
    }
    
    return returnVal;
}


fun int getFreeBwg()
{
    -1 => int returnVal;
    (lastFreeBwg+1)%freeBwgs.size() => int nextBwg;
    
    if(freeBwgs[ nextBwg ] == 0)
        nextBwg => returnVal;        
    else {
        
        for( 0 => int i; i<freeBwgs.size(); i++)
        {            
            if(freeBwgs[i] == 0)
            {
                i => returnVal;                
                break;
            }            
        }        
    }
    
    return returnVal;
}

// duration for some reason seems to be 1/2 its actual pre-buffered value (?)
fun int playNote(int index, int channel)
{        
    notes[index].play(); 

    // hack
    2*notes[index].fileDuration => now;
}


fun int[][] setPartialChannels(int noteIndex, int pitch, dur thisFileDuration, int midi_input)
{
    // array to hold return vals of freePartial and freeBwg for play shred
    int free[numberOfPartials][2];
    
    int freePartial;
    int freeChannel;
    int freeBwg;    
    
    for (0=>int i; i<numberOfPartials; i++)
    {            
        // gets next channel that's "open" meaning, not "full"
        getOpenChannel_solo(pitch) => freeChannel;
        
        // don't mark partial as "free" if there's no channel for it
        if(freeChannel > -1)
            getFreePartial() => freePartial;   
        
        -1 => freeBwg;
        
        getFreeBwg() => freeBwg;
        
        if( freePartial > -1 && freeChannel > -1 && freeBwg > -1 )
        {
            // increment noteCount;
            noteCount++;
            
            freePartial => lastFreePartial; // update tracking of last free partial
            1 => freePartials[freePartial]; // set partial as not free
            
            freeBwg => lastFreeBwg;   // update tracking of last free Bwg
            1 => freeBwgs[ freeBwg ]; // set as not free     
            
            <<< "setPartialChannels... pitch: ", pitch, ", i: ", i, ", freePartial: ",freePartial, ", freeChannel: ", freeChannel >>>;
            
            getFreeBwg() => freeBwg;                           
            
            if(freeBwg > -1)
            {
                freePartial => free[i][0];                                
                freeBwg => free[i][1];                                
                
                channels[freeChannel] + 1 => channels[freeChannel];     // increment channel count                                   
                
                partials[freePartial].set( noteIndex, freePartial, pitch, freeChannel, thisFileDuration, i+1, freeBwg, midi_input );        
            }
            
        } else {
            
            if(freePartial == -1)                
                if(debug) chout <= "\t setPartialChannels() pitch[" + pitch + "] ...NO OPEN BWG" <= "\n";           
            
            if(freeChannel == -1)
                if(debug) chout <= "\t setPartialChannels()... partialNumber:" <= i <= ", pitch[" + pitch + "] ...NO OPEN CHANNEL" <= "\n";           
            
            // if channel isn't free, make sure to mark partial and bwg as not free
            -1 => free[i][0];                                
            -1 => free[i][1];              
        }            
    }        
    
    // return array of n-pairs of free partials and bwgs
    return free;                
}

int partialCounter;

fun int[][] setPartials(int noteIndex, int pitch, dur thisFileDuration, int channel, int midi_input)
{
    // <<< "setPartials... channels[",channel,"] = ", channels[channel] >>>;
    
    // array to hold return vals of freePartial and freeBwg for play shred
    int free[numberOfPartials][2];
    
    for (0=>int i; i<numberOfPartials; i++)
    {            
        getFreePartial() => int freePartial;                           
        
        // hack -- kill last partial dead
        //        null @=> partials[freePartial];
        
        // hack -- spawning new partials stops popping bug, but why?
        // this kills "holding"
        //        Partial tempPartial @=> partials[freePartial];
        
        //        <<< "setPartial: freePartial: ", freePartial >>>;  
        //        <<< "setPartial: partialCounter: ", partialCounter++ >>>;
        
        if(freePartial > -1)
        {
            getFreeBwg() => int freeBwg;                           
            
            if(freeBwg > -1)
            {
                
                freePartial => lastFreePartial; // update tracking of last free partial
                1 => freePartials[freePartial]; // set partial as not free
                
                freeBwg => lastFreeBwg;   // update tracking of last free Bwg
                1 => freeBwgs[ freeBwg ]; // set as not free     
                
                freePartial => free[i][0];                                
                freeBwg => free[i][1];                
                
                //                <<< "setPartials:   freePartial: ", freePartial, ", freeBwg: ", freeBwg >>>;
                
                partials[freePartial].set( noteIndex, freePartial, pitch, channel, thisFileDuration, i+1, freeBwg, midi_input );     
            }
            
        } else {
            if(debug) chout <= "\t setPartials() pitch[" + pitch + "] ...NO OPEN BWG" <= "\n";   
            
            // make sure to mark partial and bwg as not free
            -1 => free[i][0];                                
            -1 => free[i][1];                     
        }           
    }        
    
    // return array of n-pairs of free partials and bwgs
    return free;    
}


fun void playPartials(int free[][], int noteIndex) //int noteIndex, int pitch, dur thisFileDuration, int channel, int free[][])
{            
    
    for (0=>int i; i<numberOfPartials; i++)
    {                    
        if(free[i][0] > -1) // check free partial
        {            
            if(free[i][1] > -1) // check free bwg
            {                
                spork ~ partials[free[i][0]].play(noteIndex);
                me.yield();        
            }            
        }                
        
        me.yield();           
    } 
    
    10000::ms => now;   
}

/*
*  midiActivator() - MIDI input activates the next note in the sequence
*              - findNote() - finds the next .wav file in the source set with the same pitch
*/
fun void midiActivator()
{        
    if(debug) chout <= "midiActivator()..." <= "\n";
    
    MidiIn min;    
    MidiMsg msg;
    
    int index, pitch, velocity;
    
        if( !min.open( MIDIdevice ) ) me.exit();
        chout <= "MIDI device: " + min.num() + " -> " + min.name() <= "\n";
    
    // infinite time-loop
    while( true )
    {
        min => now;
        
        while( min.recv(msg) )
        {            
            <<< "testing: ", msg.data1, msg.data2, msg.data3 >>>;
            
            // 149 = oxygen keyboard
            // 144 = kawaii/Disklavier noteOn. 
            // 177/176 (ignore) = kawaii pedal on/off
            
            if( (msg.data1 == 149 || msg.data1 == 144) || msg.data1 == 128)
            {
                // if noteOn and velocity is greater than 0, and not Disklavier note off (128)
                if( msg.data3 > 0 && msg.data1 != 128)
                {
                    <<< "midi noteOn: ", msg.data1, msg.data3 >>>;                
                    
                    if(debug) chout <= msg.data1 + ", " + msg.data2 + ", " + msg.data3 <= "\n";
                    
                    msg.data2 => pitch;
                    msg.data3 => velocity;                                      
                    
                    // midi event handlers
                    msg.data2 => on.note;
                    msg.data3 => on.velocity;
                    on.signal();             
                    
                    if(ignoreMidiOff==1)
                        spork ~ findNote(pitch, velocity, 0);
                    else
                        spork ~ findNote(pitch, velocity, 1);    
                    
                    
                    me.yield();
                    
                } else if(msg.data3 == 0 || msg.data1 == 128) {
                    
                    // Note-off MIDI message                                                            
                    spork ~ turnOffMidiPartials(msg.data2);              
                    me.yield();
                }        
            } else if(msg.data1 == 176)
            {
                // Foot pedal continuous controller [67 (cont), 66 (discrete), 64 (cont)]
                if( footPedalHold ==1 )
                {
                    if(msg.data2 == 66)
                    {
                        if(msg.data3 == 127)
                            holder();
                    }
                }
            } 
        }
    }
}

fun void turnOffMidiPartials(int pitch)
{
    <<< "MIDI NOTE OFF...(turnOffMidiPartials): pitch=", pitch>>>;
    
    for(0=>int i; i<partials.size(); i++)
    {                        
        if(partials[i].pitch == pitch && partials[i].midi == 1 && partials[i].midi_on == 1)
        {
            chout <= "\t FOUND MIDI PARTIAL TO TURN OFF: " + i + " pitch: " + pitch <= "\n";
            
            // send stop event to note
            partials[i].midiEvent.signal();
            
            0 => partials[i].midi_on;
            <<< "MIDI PARTIAL["+i+"].midi_on: " + partials[i].midi_on >>>;
            
            10::ms => now;
        }
    }              
}

fun int channelIsFree(int channelNumber, int count)
{
    -1 => int returnValue;
    
    if(channels[channelNumber] + count <= channel_TOTALVOICES)
    {
        // reserve the channel slots here?
        channels[channelNumber] + count => channels[channelNumber];
        
        1 => returnValue; 
    }
    
    return returnValue;    
}

fun void findNote(int pitch, int velocity, int midi_input)
{
    if(debug) chout <= "findNote(" + pitch + ", " + velocity + ") noteCount: " + noteCount <= "\n";
    
    // if muteNotePlayPartials flag == 1:
    //    - don't restrike Note but restrike Partials on midi keyboard strikes    
    if(midi_input==1 && muteNotePlayPartials==1 && midiNotes[pitch-1] == 1)
        playNoteAndPartials(pitch, velocity, midi_input, 1);                
    else
        playNoteAndPartials(pitch, velocity, midi_input, 0);        
}

fun void playNoteAndPartials(int pitch, int velocity, int midi_input, int mute_note_play_partials)
{
    int foundNoteIndex;
    
    for(0=>int i; i<notes.size(); i++)
    {            
        //        <<< "playNoteAndPartials   notes[",i,"].activated: ", notes[i].activated >>>;
        
        // use this to play each note recording only once; without dirty flag, the first will play each time
        // without dirty, notes get progressively louder [BUG]  //        if(notes[i].pitch == pitch && notes[i].dirty == 0)        
        if(notes[i].pitch == pitch && notes[i].activated == 0)
        {                
            notes[i].filename => string filename;
            
            if(debug) chout <= "\t FOUND: " + i + ", " + filename + ", " + notes[i].duration <= "\n";
            
            // get channel for file first
            getOpenChannel() => int channel;                                   
            
            // only play note (+ partials) if there's at least 1 open channel
            if(channel > -1)
            {
                notes[i].activate(midi_input);                
                
                // set note and set partials
                notes[i].set(channel, gFileGain); 
                
                if(midi_input == 1)                    
                    1 => midiNotes[pitch-1];  // mark note as "playing"
                
                if(mute_note_play_partials == 0)
                {
                    // play note and partials at same time (?) on same channel
                    spork ~ playNote(i, channel);
                    me.yield();                
                } 

//                10::second => now;
                
                i => foundNoteIndex;
                
                int free[numberOfPartials][2];
                
                // partials on same channel as Note
                if(partialsSameChannel==1)
                {                    
                    // check for free channels for the partials
                    if(channelIsFree(channel, numberOfPartials) > -1)
                        setPartials(i, pitch, notes[i].fileDuration, channel, midi_input) @=> free;                                                
                    
                } else {                    
                    
                    // partials will be set each on their own channel
                    setPartialChannels(i, pitch, notes[i].fileDuration, midi_input) @=> free;                                            
                }                    
                
                // only spork partials if there are open channels     
                // - set midi_hold for the Note here too, to hold it open until note release           
                spork ~ playPartials(free, i);
                me.yield();                                
                
                notes[i].calcDuration => now;               
                notes[i].deactivate();                                        
            }            
            
            break;   
        }
    }     
    
    // hold off killing this shred until midi held notes have been released
    while(notes[foundNoteIndex].midi_hold == 1)
    {
        10::ms => now;
    } 
    
    if(notes[foundNoteIndex].midi==0)
    {
        //hack: long wait... calculate this?        
        10000::ms => now;                 
    }
}

fun int getOpenChannel()
{    
    -1 => int returnVal; // return -1 if no open channel                                    
   
    // randomize first channel
    if(lastChannel == -1)
        Math.random2(0, channels.size()-1 ) => lastChannel;

//    <<< "getOpenChannel()... lastChannel:", lastChannel >>>;
            
    (lastChannel+1) % channels.size() => int nextChannel; // start checking at last clear channel + 1    
    
    if(channels[nextChannel] <= channel_TOTALVOICES) {
        nextChannel => lastChannel => returnVal;                   
    } else {        
        for(0=>int i; i< channels.size(); i++)
        {
            if(channels[i] <= channel_TOTALVOICES) {
                i => lastChannel => returnVal;                     
                break;
            } 
        }    
    }
    
    if(returnVal > -1)
        noteCount++;   
    
    return returnVal;
}

fun int getOpenChannel_solo(int pitch)
{    
    -1 => int returnVal; // return -1 if no open channel                                    
    
    (lastChannel+1) % channels.size() => int nextChannel; // start checking at last clear channel + 1    
    
    <<<"getOpenChannel_solo... pitch: ", pitch, ", nextChannel=", nextChannel, ", channels[", nextChannel, "]=", channels[nextChannel]>>>;
    
    if(channels[nextChannel] == 0) {
        nextChannel => lastChannel => returnVal;                   
    } else {        
        //        <<<"now here">>>;
        for(0=>int i; i< channels.size(); i++)
        {
            if(channels[i] == 0) {
                i => lastChannel => returnVal;                     
                break;
            } 
        }    
    }
    
    <<<"getOpenChannel_solo... returnVal=", returnVal>>>;
    
    return returnVal;
}

/* 
------------------------------------------------- 
Testing Functions/Activators
------------------------------------------------- 
*/
fun void autoActivator()
{
    25 => int pitch;
    90 => int velocity;
    
    500 => float testWaitTime;
    
    0 => int i;
    
    // infinite time-loop
    while( i < 1110 )
    {        
        if(pitch > 45 ) 
            25 => pitch;
        
        if(debug) chout <= "---------------------------------------------- \n";        
        if(debug) chout <= "autoActivator: " + pitch <= "\n";
        
        // increasing pitch/index
        //        spork ~ findNote(pitch, velocity, 0);
        
        // try random value here
        Math.random2(25, 80) => int rndPitch;
        spork ~ findNote(rndPitch, velocity, 0);
        
        // repeat same pitch
        //spork ~ findNote(25, velocity, 0);  
        
        //        testWaitTime::ms => now;                
        //        spork ~ findNote(26, velocity, 0); 
        
        testWaitTime::ms => now;        
        
        pitch + 1 => pitch;
        
        i++;
    }
    
    1::day => now;
}

fun void noteActivator(int pitch)
{
    
    90 => int velocity;
    
    10*1000 => float noteWaitTime;
    
    // set last param to 1 to hold indefinitely
    spork ~ findNote(pitch, velocity, 0);
    
    noteWaitTime::ms => now;   
    
    chout <= "Killing shred for note #" + noteCount + ", pitch=" + pitch <= "\n";     
    
}

fun void testActivator(int pitch)
{
    
    90 => int velocity;
    
    10*1000 => float testWaitTime;
    
    spork ~ findNote(pitch, velocity, 0);
    
    testWaitTime::ms => now;   
    
    chout <= "Killing shred for note #" + noteCount + ", pitch=" + pitch <= "\n";     
    
}

fun void testPlayback()
{
    0 => float thisTime;
    
    for(0 => int i; i < notes.size(); i++)
    {        
        (notes[i].timeOn - thisTime)::ms => now;
        notes[i].timeOn => thisTime;
        
        spork ~ findNote(notes[i].pitch, notes[i].velocity, 0);
        
        if(i==(notes.size()-1))
            0 => i;
    }
    
    1::day => now;
}

fun void scoreActivator()
{    
    0 => int startIndex;
    notes.size() => int totalNotes;
    
    <<< "scoreActivator: notes.size(): ", notes.size(), ", startIndex: ", gStartingNoteIndex >>>;
    
    // retrieve starting index from passed-in argument
    if(gStartingNoteIndex < notes.size())
        gStartingNoteIndex => startIndex;
    
    // step through note array from starting point (defaults to 0)
    for(startIndex=>int i; i<totalNotes;i++)
    {
        if(pause==0)
        {
            <<< ".....scoreActivator: i=", i, ", notes.size(): ", notes.size() >>>;
            
            notes[i].pitch => int pitch;
            notes[i].velocity => int velocity;
            notes[i].duration => float duration;
            
            spork ~ findNote(pitch, velocity, 0);
            me.yield();
            
            duration::ms => now;
            
            if(scoreRepeat==1)
            {
                if(i == totalNotes-1)
                    0 => i;
            }
        } else {
            10::ms=> now;  
            i-1=>i; 
        }
    }
    
    1::day => now;
    
}

fun void scorePlayer()
{   
    0 => int startIndex;     
    notes.size() => int totalNotes;
    
    // retrieve starting index from passed-in argument
    if(gStartingNoteIndex < notes.size())
        gStartingNoteIndex => startIndex;        
    
    for(startIndex=>int i; i<totalNotes;i++)
    {        
        if(pause==0)
        {            
            <<< ".....scorePlayer: i=", i>>>;
            
            notes[i].pitch => int pitch;
            notes[i].velocity => int velocity;
            notes[i].duration => float duration;
            
            spork ~ findNote(pitch, velocity, 0);
            me.yield();
            
            if(i != totalNotes-1)
            {
                notes[i+1].timeOn - notes[i].timeOn => float timeDifference;
                
                // get next note's timeOn and move forward the difference
                (timeDifference)::ms => now;
                
                // check to see if next note has same timeOn (chord-notes)
                if(timeDifference == 0)
                    <<< "********* CHORD NOTES **********" >>>;
                
            } else {
                duration::ms => now;    
            }
            
            if(scoreRepeat==1)
            {
                if(i == totalNotes-1)
                    0 => i;
            }
        } else {
            10::ms => now;
            i-1=>i;    
        }
    }
    
    1::day => now;         
}

fun void checker()
{
    -2 => int last0;
    -2 => int last1;
    
    while(true)
    {
        if(channels[0] != last0)    
        {
            <<< "-------- channel[0] size=",channels[0]>>>;
            channels[0] => last0;
        }
        
        if(channels[1] != last1)    
        {
            <<< "-------- channel[1] size=",channels[1]>>>;
            channels[1] => last1;        
        }
        
        1::ms => now;
    }    
    
    1::day => now;    
}

// startIndex = array index from which to start
// rhythmCount = number of notes to play
fun void playRhythms(int startIndex, int rhythmCount)
{
    Impulse imp => BiQuad f => dac;    
    .99 => f.prad; // set the filter's pole radius
    1 => f.eqzs; // set equal gain zero's
    0.0 => float v; // initialize float variable
    
    rhythms.size() => int size;
    
    if(startIndex+rhythmCount < size)
    {                
        for(0=>int i; i<rhythmCount;i++)
        {                        
            //            <<< "rhythm: ", i, rhythms[startIndex+i] >>>;            
            
            1.0 => imp.next;                             // set the current sample/impulse    
            Std.fabs(Math.sin(v)) * 4000.0 => f.pfreq; // sweep the filter resonant frequency    
            v + .1 => v;                               // increment v
            
            rhythms[startIndex+i]::ms => now;
        }                
    }        
}


// playType: 0 = loop, 1-n = play n-times
fun void cellPlayer(int cell, int playType, int chord)
{        
//    <<< "IN CELL PLAYER: playType: ", playType>>>;
    
    0 => int loop;           // loop forever if loop = 1
    0 => int playCount;      // # of times to loop (1-n)
    
    if(playType == 0)
        1 => loop;              // loop forever
    else 
        playType => playCount;  // play n-times
    
    cells[cell].size => int size; 
    cells[cell].index => int index;
    size+index => int ubound;
    
    // track number of times we've played cell
    int loopCounter;    
    0 => gCurrentNoteIndex;
    
    for(index=>int i; i<ubound;i++)
    {        
        if(pause==0)
        {                        
            //            <<< ".....cellPlayer: i=", i>>>;
            
            notes[i].pitch => int pitch;
            notes[i].velocity => int velocity;
            notes[i].duration => float duration;

            spork ~ findNote(pitch, velocity, 0);
            me.yield();

            if( i != ubound-1 && chord==1 )
            {
                notes[i+1].timeOn - notes[i].timeOn => float timeDifference;
                
                // get next note's timeOn and move forward the difference
                (timeDifference)::ms => now;
                
            } else {
                duration::ms => now;    
            }            
            
            //<<< "cells[",cell,"]: i=", i, ", ubound: ", ubound, ", elapsedTime: ", gElapsedTime/ms >>>;                       
            
            // print to get cell timing       
            //if( i == ubound-1)
            //    <<< "cells[",cell,"]: i=", i, ", elapsedTime: ", gElapsedTime/ms >>>;                       
            
            if(loop==1 || loopCounter < playCount-1)
            {                
                if(i == ubound-1)
                {                    
                    0 => i;
                    loopCounter + 1 => loopCounter;
                }
            }
            
            // use this in scenes
            //            <<< "HERE" >>>;
            gCurrentNoteIndex + 1 => gCurrentNoteIndex;
            
        } else {
            100::ms => now;
            i-1=>i;    
        }                
    }
    
    fadeOut();    
    //    fadeOutDuration::ms => now;         
}


fun void osc_init_channel_locations_()
{
    <<< "osc_init_channel_locations: osc_default_distance: ", osc_default_distance >>>;
    
    xmit.start( "/reset" );
    xmit.add(osc_default_distance);
    xmit.send();
    
    // "source 0 az -90.0000, source 0 dist 1.0000, source 1 az -84.4000, source 1 dist 1.0000, source 2 az -78.7000, source 2 dist 1.0000, source 3 az -73.1000, source 3 dist 1.0000, source 4 az -67.5000, source 4 dist 1.0000, source 5 az -61.9000, source 5 dist 1.0000, source 6 az -56.2000, source 6 dist 1.0000, source 7 az -50.6000, source 7 dist 1.0000, source 8 az -45.0000, source 8 dist 1.0000, source 9 az -39.4000, source 9 dist 1.0000, source 10 az -33.8000, source 10 dist 1.0000, source 11 az -28.1000, source 11 dist 1.0000, source 12 az -22.5000, source 12 dist 1.0000, source 13 az -16.9000, source 13 dist 1.0000, source 14 az -11.3000, source 14 dist 1.0000, source 15 az -5.6000, source 15 dist 1.0000, source 16 az 0.0000, source 16 dist 1.0000, source 17 az 5.6000, source 17 dist 1.0000, source 18 az 11.3000, source 18 dist 1.0000, source 19 az 16.9000, source 19 dist 1.0000, source 20 az 22.5000, source 20 dist 1.0000, source 21 az 28.1000, source 21 dist 1.0000, source 22 az 33.8000, source 22 dist 1.0000, source 23 az 39.4000, source 23 dist 1.0000, source 24 az 45.0000, source 24 dist 1.0000, source 25 az 50.6000, source 25 dist 1.0000, source 26 az 56.2000, source 26 dist 1.0000, source 27 az 61.9000, source 27 dist 1.0000, source 28 az 67.5000, source 28 dist 1.0000, source 29 az 73.1000, source 29 dist 1.0000, source 30 az 78.7000, source 30 dist 1.0000, source 31 az 84.4000, source 31 dist 1.0000"=> string batch;
    // "source 0 az -90.0000, source 0 dist 1.0000, source 1 az -84.4000, source 1 dist 1.0000, source 2 az -78.7000, source 2 dist 1.0000, source 3 az -73.1000, source 3 dist 1.0000, source 4 az -67.5000, source 4 dist 1.0000, source 5 az -61.9000, source 5 dist 1.0000, source 6 az -56.2000, source 6 dist 1.0000, source 7 az -50.6000, source 7 dist 1.0000, source 8 az -45.0000, source 8 dist 1.0000, source 9 az -39.4000, source 9 dist 1.0000, source 10 az -33.8000, source 10 dist 1.0000, source 11 az -28.1000, source 11 dist 1.0000" => string batch1;
    // "source 12 az -22.5000, source 12 dist 1.0000, source 13 az -16.9000, source 13 dist 1.0000, source 14 az -11.3000, source 14 dist 1.0000, source 15 az -5.6000, source 15 dist 1.0000, source 16 az 0.0000, source 16 dist 1.0000, source 17 az 5.6000, source 17 dist 1.0000, source 18 az 11.3000, source 18 dist 1.0000, source 19 az 16.9000, source 19 dist 1.0000, source 20 az 22.5000, source 20 dist 1.0000, source 21 az 28.1000, source 21 dist 1.0000, source 22 az 33.8000, source 22 dist 1.0000" => string batch2;
    // "source 23 az 39.4000, source 23 dist 1.0000, source 24 az 45.0000, source 24 dist 1.0000, source 25 az 50.6000, source 25 dist 1.0000, source 26 az 56.2000, source 26 dist 1.0000, source 27 az 61.9000, source 27 dist 1.0000, source 28 az 67.5000, source 28 dist 1.0000, source 29 az 73.1000, source 29 dist 1.0000, source 30 az 78.7000, source 30 dist 1.0000, source 31 az 84.4000, source 31 dist 1.0000"=> string batch3;
    
    /* 
    "source 1 az -90.0000, source 1 dist 1.0000, source 2 az -84.4000, source 2 dist 1.0000, source 3 az -78.7000, source 3 dist 1.0000, source 4 az -73.1000, source 4 dist 1.0000, source 5 az -67.5000, source 5 dist 1.0000, source 6 az -61.9000, source 6 dist 1.0000, source 7 az -56.2000, source 7 dist 1.0000, source 8 az -50.6000, source 8 dist 1.0000, source 9 az -45.0000, source 9 dist 1.0000, source 10 az -39.4000, source 10 dist 1.0000, source 11 az -33.8000, source 11 dist 1.0000, source 12 az -28.1000, source 12 dist 1.0000" => string batch1;
    "source 13 az -22.5000, source 13 dist 1.0000, source 14 az -16.9000, source 14 dist 1.0000, source 15 az -11.3000, source 15 dist 1.0000, source 16 az -5.6000, source 16 dist 1.0000, source 17 az 0.0000, source 17 dist 1.0000, source 18 az 5.6000, source 18 dist 1.0000, source 19 az 11.3000, source 19 dist 1.0000, source 20 az 16.9000, source 20 dist 1.0000, source 21 az 22.5000, source 21 dist 1.0000, source 22 az 28.1000, source 22 dist 1.0000, source 23 az 33.8000, source 23 dist 1.0000" => string batch2;
    "source 24 az 39.4000, source 24 dist 1.0000, source 25 az 45.0000, source 25 dist 1.0000, source 26 az 50.6000, source 26 dist 1.0000, source 27 az 56.2000, source 27 dist 1.0000, source 28 az 61.9000, source 28 dist 1.0000, source 29 az 67.5000, source 29 dist 1.0000, source 30 az 73.1000, source 30 dist 1.0000, source 31 az 78.7000, source 31 dist 1.0000, source 32 az 84.4000, source 32 dist 1.0000" => string batch3;
    
    xmit.start( "/batch" );
    batch1 => xmit.add;
    xmit.send();
    
    1000::ms => now;
    
    xmit.start( "/batch" );
    batch2 => xmit.add;
    xmit.send();
    
    1000::ms => now;
    
    xmit.start( "/batch" );
    batch3 => xmit.add;
    xmit.send();
    
    // <<< "************************************ SENDING BATCH ********************************" >>>;
    
    10::ms => now;
    */
    
}

init_osc_positioning-2 => int channelPattern;

fun void osc_init_channel_locations()
{    
    if(osc_output == 1)
    {        
        for(0=>int i; i<33; i++)
        {
            xmit.start( "/source/ad");            
            i +1 => xmit.add;     // source # 
            
            int channelLocationTempArray[];
            
            if (channelPattern == 0)
            {
                channelPositions[i][0] => xmit.add;
                
                if(osc_default_distance == 0)
                    channelPositions[i][1] => xmit.add;       // distance            
                else
                    osc_default_distance => xmit.add;                
            }
            else if( channelPattern == 1)
            {
                centerMirrorPattern[i] => int index;
                channelPositions[index][0] => xmit.add;
                
                if(osc_default_distance == 0)
                    channelPositions[index][1] => xmit.add;       // distance            
                else
                    osc_default_distance => xmit.add;                
            } else if( channelPattern == 2)
            {
                outwardMirrorPattern[i] => int index;
                channelPositions[index][0] => xmit.add;
                
                if(osc_default_distance == 0)
                    channelPositions[index][1] => xmit.add;       // distance            
                else
                    osc_default_distance => xmit.add;                
            }
            
            
            
            //channelPositions[i][0] => xmit.add;             // azimuth
            
            if(osc_default_distance == 0)
                channelPositions[i][1] => xmit.add;       // distance            
            else
                osc_default_distance => xmit.add;
            
            xmit.send();            
            
            10::ms => now;                                    
        }                         
    }
}


fun void osc_init_channel_locations_()
{    
    if(osc_output == 1)
    {        
        for(0=>int i; i<33; i++)
        {
            xmit.start( "/source/ad");            
            i +1 => xmit.add;                               // source #            
            channelPositions[i][0] => xmit.add;             // azimuth
            
            if(osc_default_distance == 0)
                channelPositions[i][1] => xmit.add;       // distance            
            else
                osc_default_distance => xmit.add;
            
            xmit.send();            
            
            10::ms => now;                                    
        }                         
    }
}


fun void osc_sender()
{
    while(true)
    {
        for(0=>int i; i<channelCount; i++)
        {
            outputChannels[i].sendOsc() => int val;    
            
            if(  val == 1 )
            {
                osc_send_channel( i );
                1::ms => now;
            }                        
        }
        
        10::ms => now;
    }
    
    10::day => now;
}

fun void osc_send_channel(int id)
{
    
    xmit.start( "/source/ad");            
    id + 1 => xmit.add;                            // source #                
    outputChannels[id].azimuth => xmit.add;    
    outputChannels[id].distance => xmit.add;        
    xmit.send();
    5::ms => now;
    
    /*        
    xmit.start( "/source/azimuth");            
    id + 1 => xmit.add;                            
    outputChannels[id].azimuth => xmit.add;    
    xmit.send();
    5::ms => now;
    
    xmit.start( "/source/distance");            
    id + 1 => xmit.add;                            
    outputChannels[id].distance +0.5=> xmit.add;    
    xmit.send();
    50::ms => now;
    */    
}

fun void setAllSources_randomAD()
{
    targetPositions[0].size() => int size;
    
    float randomAz;
    float randomDist;
    
    while(true)
    {        
        for(0=>int i; i<channelCount; i++)
        {
            if(toggle_position_all_ad==1)
            {                
                Std.rand2f(-90., 90.) => randomAz;
                Std.rand2f(0.1, 1.8) => randomDist;
                
                randomAz => outputChannels[i].target_azimuth;
                randomDist => outputChannels[i].target_distance;
            }
            500::ms => now;
        }
    }
    
    10::day => now;
}

fun void holder()
{    
    if(hold==0)
        gPlayFileFlag => gTempFileFlag;
    
    (hold + 1)%2 => hold;                    
    
    if(hold==1) {
        0 => gPlayFileFlag;
        3000::ms => now;  
        1 => pause;                                          
    } else {
        0 => pause;
        gTempFileFlag => gPlayFileFlag;
    }
}


fun void keyboardListener()
{
    Hid hi;
    HidMsg msg;
    0 => int device;
    if( !hi.openKeyboard( device ) ) me.exit();
    <<< "keyboard '" + hi.name() + "' ready", "" >>>;
    
    while(true)
    {
        hi => now;
        
        while( hi.recv( msg ) )
        {
            if( msg.isButtonDown() )
            {
                //<<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;                
                
                // Hold message
                if( msg.which == 11)            // "h" = hold
                {                    
                    holder();
                } 
                else if( msg.which == 19 )     // "p" = pause
                {
                    (pause +1)%2 => pause;                    
                } else if( msg.which == 9)     // "f" = play File
                {
                    (gPlayFileFlag + 1)%2 => gPlayFileFlag;
                } else if( msg.which == 5)     // "b" = bend partials
                {
                    //                    <<< "bending.........." >>>;
                    
                    for(0=>int i; i< bwgs.size();i++)
                    {
                        spork ~ bender(i);
                        me.yield();
                        1::ms => now;
                    }                    
                } else if( msg.which == 14) // "k" = disklavier action rhythms
                {
                    (pedal_rhythms + 1)%2 => pedal_rhythms;
                } else if( msg.which == 17) // "n" = bass shift for all new notes
                {
                    (gBassShift + 1)%2 => gBassShift;
                } else if( msg.which == 22) // "s" - stutterer
                {
                    (gStutter +1)%2 => gStutter;
                    <<< "gStutter = ", gStutter >>>;
                } else if( msg.which == 30) // "1" - toggle_position_all_ad
                {
                    (toggle_position_all_ad +1)%2 => toggle_position_all_ad;    
                }
            }            
        }        
    }
    
    10::day => now;   
}

fun void pedalRhythms_test()
{
    MidiOut mout;
    MidiMsg msg;        
    
    // check if port is open
    //    if( !mout.open( 0 ) ) me.exit();           
    
    // 1	64	127
    while(true)
    {
        0xB0 => msg.data1;                           // continuous controller hex value
        64 => msg.data2;                             // controller #
        
        Math.random2(0, 127) => msg.data3;           // controller value (127 max)
        
        mout.send(msg);
        
        20::ms => now;
    }
    
    10::day => now;
}

fun void pedalRhythms()
{
    MidiOut mout;
    MidiMsg msg;        
    
    20 => float baseTime;
    1.0 => float mult;
    
    // verify midi port is open    
    if( !mout.open( MIDIdevice ) ) <<< "*** Midi Out not connected (pedalRhythms) ***" >>>;        
    
    // 1	64	127
    while(true)
    {
        if(pedal_rhythms == 1)
        {
            //<<< "pedal rhythms: here">>>;
            0xB0 => msg.data1;                           // continuous controller hex value
            64 => msg.data2;                             // controller #
            
            Math.random2(0, 127) => msg.data3;           // controller value (127 max)
            
            mout.send(msg);
            
            Math.randomf() => float eval;
            
            if( eval > 0.95)
                100 => mult;
            else if( eval > 0.75 )
                0.5 => mult;
            else if( eval < 0.05 ) //0.15
                0.25 => mult;
            
            (mult*baseTime)::ms => now;    
        } else
        {
            // clear pedal if necessary
            0xB0 => msg.data1;                           
            64 => msg.data2;           
            0 => msg.data3;
            mout.send(msg);
            10::ms => now;
        }
    } 
    
    
    10::day => now;
}

fun void basser()
{
    int triggered;
    
    while(true)
    {
        if(gBassShift == 1 && triggered==0)
        {
            gPlayFileFlag => gTempFileFlag;
            
            // set global pitch shift to subwoofer range
            Math.random2f(0.05, 0.1) => gPitchShift;
            0 => gPlayFileFlag;
            1 => triggered;            
            
        } else {
            if(gBassShift == 0 && triggered==1)
            {                
                1.0 => gPitchShift;
                gTempFileFlag => gPlayFileFlag;                             
                0 => triggered;                       
            }
        }
        
        100::ms => now;
    }
    
    10::day => now;   
}

fun void bender(int index)
{
    while(partials[index].p.shift() > 0.08)
    {        
        partials[index].p.shift() - 0.001 => partials[index].p.shift;     
        
        if(partials[index].p.shift() <= 0.08) 0.08 => partials[index].p.shift;
        
        <<< "bender: partials[", index, "].p.shift() = ",  partials[index].p.shift() >>>;
        
        10::ms => now;      
    }   
    
    int counter;
    
    while(counter<1000)
    {
        partials[index].p.shift() + Math.random2f(-0.0005, 0.0005) => partials[index].p.shift;
        
        counter++;
        
        100::ms => now;
    }    
}

// timer runs if timerLength > 0
// when timer duration is reached, code ends
fun void timer()
{        
    if (timerLength > 0)
    {
        dur elapsedTime;        
        
        while(elapsedTime < timerLength::ms)
        {            
            // <<< "Timer: ", elapsedTime/ms, ", timerLength: ", timerLength  >>>;                           
            -1. * (launchTime - now) => elapsedTime => gElapsedTime;                            
            
            100::ms => now;
        }
        
        // call pause to stop new voices from sporking (comment out for testing fade)
        1 => pause;
        
        // trigger fade out on all envelopes
        fadeOut();        
        
        // kill call is triggered in master script
        
        10::day => now;
    }            
}

fun void initEnvelopes()
{
    gStutterEnvelopeSpeed::ms => dur t;
    
    for(0=>int i; i<channelCount; i++)
    {
        t => envelopes[i].duration;
        
        envelopes[i].keyOn();
        
        envelopes[i] => dac.chan(i);
    }   
}

// gStutterSpeed - rate between stutters
fun void stutterer()
{    
    int flip;
    
    initEnvelopes();
    
    while(true)
    {
        if(gStutter == 1)
        {                        
            for(0=>int i; i<channelCount; i++)
            {      
                if(flip == 1)     
                    envelopes[i].keyOff();
                else                    
                    envelopes[i].target(gEnvelopeGain);                                
            }              
            
            (flip+1)%2 => flip;            
        }
        
        gStutterSpeed::ms => now; 
    }
    
    10::day => now;
}

fun void fadeOut()
{
    <<<"triggering fadeout: ", fadeOutDuration >>>;
    
    for(0=>int i; i<channelCount; i++)
    {
        fadeOutDuration::ms => envelopes[i].duration;
        envelopes[i].keyOff();
    }    
    
    fadeOutDuration::ms => now;
    
    //<<< "DEBUGGING......notes.size()", notes.size(), ", partials.size():", partials.size() >>>;
    
    
    for(0 => int i; i<envelopes.size();i++)
    {
        null @=> envelopes[i];  
        <<< "killing envelope: ", i >>>; 
        1::samp => now;           
    }
    
    // kill all voices here?
    //    for(0 => int i; i<notes.size();i++)
    //    {
    //        null @=> notes[i]; 
    //        <<< "DEBUGGING......A:", i >>>;
    //        1::samp => now;     
    //    }
    
    /*    
    // kill all partials here?
    for(0 => int i; i<partials.size();i++)
    {
        null @=> partials[i];  
        <<< "DEBUGGING......A: ", i >>>; 
        1::samp => now;           
    }
    <<< "DEBUGGING......B" >>>;    
    for(0 =>int i; i<bwgs.size();i++)
    {
        null @=> bwgs[i]; 
        <<< "DEBUGGING......B: ", i >>>;    
        1::samp => now;          
    }
    <<< "DEBUGGING......done" >>>;
    */    
    
}

// timed scenes to be called from external script via "trigger_scene" param
// - scenes can trigger other scenes by setting "trigger_scene"
fun void scenester()
{
    while(true)
    {
        if(trigger_scene == 1)
        {
            10::second => now;
            
            1 => gBassShift;              // trigger bass shift
            
            10::second => now;
            
            0 => gBassShift;              // trigger bass shift            
            
        } else if(trigger_scene == 2)
        {
            <<< "in trigger_scene == 2: cellIndex" >>>;
            
            if(cellIndex == 13)
            {
                <<< "scenester... gCurrentNoteIndex: ", gCurrentNoteIndex >>>;
                /*
                // hold for short times
                3::second => now;
                1 => hold;
                8::second => now;
                0 => hold;
                1::second=>now;
                1 => pause;
                5::second => now;
                0=> pause;
                */
                
                if(gCurrentNoteIndex == 14 ) 
                {
                    holder();
                    5::second => now;
                    holder();
                }
                
                if(gCurrentNoteIndex == 18 || gCurrentNoteIndex == 35 || gCurrentNoteIndex == 42 || gCurrentNoteIndex == 58)
                {
                    1 => pause;
                    5::second => now;
                    0 => pause;
                    5::second => now;
                    
                }
                
                100::ms => now;
                
            }
            
        } else {
            100::ms => now;
        }
    }    
    
    10::day => now;   
}

fun void testHold()
{
    
    <<< "testHold..." >>>;
    5::second => now;
    holder();    
    20::second => now;    
    holder();        
}


fun void randomHold()
{
    while(true)
    {
        if( gRandomHold == 1 ) 
        {
            Math.random2(0, 3) => int chance;
            
            if(hold == 0 && chance == 0)
            {
                Math.random2(10, 200)::second => now;                
                holder();
                <<< ".....randomHold() on" >>>;
            }
            
            if( hold == 1 && chance == 0)
            {                
                Math.random2(10, 20)::second => now;                
                holder();                
                <<< ".....randomHold() off" >>>; 
                
                Math.random2(20, 40)::second => now;                                               
            }
        }
        
        1::samp => now; 
    }   
    
    10::day => now;
}

fun void randomBass()
{
    while(true)
    {
        if( gRandomBass == 1 ) 
        {
            Math.random2(0, 3) => int chance;
            
            if(gBassShift == 0 && chance == 0)
            {
                Math.random2(30, 200)::second => now;                
                1 => gBassShift;
                <<< ".....randomBass() on" >>>;
            }
            
            if( gBassShift == 1 && chance == 0)
            {                
                Math.random2(10, 20)::second => now;                
                0 => gBassShift;                
                <<< ".....randomBass() off" >>>; 
                
                Math.random2(10, 20)::second => now;                                               
            }
        }
        
        1::samp => now;
    }   
    
    10::day => now;
}

/* 
* -------------------------------------------------
* Main()
* -------------------------------------------------
*/

if(debug) chout <= "main()..." <= "\n";

now => launchTime;

readFile();

testFileData();
//printFile();

// timer routine to pause and fade out all output in preparation for shut-down via 108.ck
spork ~ timer();
me.yield();

initEnvelopes();

spork ~ stutterer();

spork ~ keyboardListener();

spork ~ oscSettings();
spork ~ oscValues();
me.yield();

if(osc_output==1)
{    
    for(0=> int i; i<channelCount; i++)
    {
        //working - why isn't distance and azimuth get set here???    
        spork ~ slewAzimuth(i);
        me.yield();
        
        spork ~ slewDistance(i);
        me.yield();
    }
    
    // only reset osc source positioning data if flag is set
    if( init_osc_positioning > 0)
    {        
        <<< ".....Starting:   calculating channel positions..." >>>;        
        //initChannelPositions();
        setChannelPositions(1);
        <<< ".....Finished:   calculating channel positions..." >>>;                
    }
    /*    
    for(0=>int i; i<channelCount; i++)
    {
        <<< "outputChannels[", i, "].id:", outputChannels[i].id, ", azimuth:", outputChannels[i].azimuth, ", home_azimuth:", outputChannels[i].home_azimuth, ", target_azimuth:", outputChannels[i].target_azimuth  >>>;
    }
    */    
    
    if(init_osc_positioning>0)
    {
        <<< ".....Starting:   sending channel positions..." >>>;
        // default distance with osc_default_distance.........
        osc_init_channel_locations();        // set source locations in spat~  
        <<< ".....Finished:   sending channel positions..." >>>;    
        
        // if param == 2 then send osc position data and quit.
        if(init_osc_positioning > 1)
            me.exit();
    }
    
    // need to make this send azimuth and distance separately
    spork ~ osc_sender();
    me.yield();    
}

spork ~ fixer_partials();
me.yield();
//spork ~ fixer_notes();

spork ~ basser();

// play piano pedal rhythms
//if(pedal_rhythms==1)
spork ~ pedalRhythms();

//2000::ms => now;
if(playType == 1)
    spork ~ midiActivator(); // MIDI Input
else if(playType == 2)
    spork ~ scoreActivator(); // SCORE Input
else if(playType == 3)
{
    spork ~ midiActivator(); // MIDI Input    
    spork ~ scoreActivator(); // SCORE Input   
}
else if(playType == 4)
    spork ~scorePlayer();
else if(playType == 5)
    spork ~ autoActivator(); // Autonomous Notes
else if(playType == 6)
{
    // "cell" playback without chord play
    spork ~ cellPlayer(cellIndex, cellPlayType, 0);
    
} else if(playType == 7)
{
    // "cell" playback without chord play
    spork ~ cellPlayer(cellIndex, cellPlayType, 1);
    
} else if(playType == 8)  
{
    // MIDI + "cell" playback without chord play
    spork ~ midiActivator(); // MIDI Input        
    spork ~ cellPlayer(cellIndex, cellPlayType, 0);
    
} else if(playType == 9)  
{
    // MIDI + "cell" playback with chord play
    spork ~ midiActivator(); // MIDI Input        
    spork ~ cellPlayer(cellIndex, cellPlayType, 1);
    
} else if(playType == 10)  
{   
    // Individual Notes
    spork ~ noteActivator(26);
}

spork ~ setAllSources_randomAD();
spork ~ scenester();
spork ~ randomHold();
spork ~ randomBass();

//spork ~ testHold();
1::day => now;