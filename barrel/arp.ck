// make HidIn and HidMsg
Hid hi;
HidMsg msg;

//----------------------------------------------------------------
// cool great neat slew
//----------------------------------------------------------------
class CoolGreatNeatSlew
{
    0.0 => float attack;
    0.0 => float decay;
    3.0 => float target;
    3.0 => float val;
    3.0 => float diff;
    
    // individual rates for attack and decay
    fun void setRate(float _attack, float _decay)
    {
        _attack => attack;
        _decay => decay;
    }
    
    // slew will approach this value
    fun void setTarget(float _target)
    {
        _target => target;
    }
    
    // tick gets shreded automatically upon instantiation
    fun float tick()
    {
        while (true)
        {
            (target-val) => diff;
            if ( diff > 0 )
                diff*decay + val => val;
            else
                diff*attack + val => val;
            10::samp => now;
        }
    }
    spork ~ tick();
}

//----------------------------------------------------------------
// GameTrak Code
//----------------------------------------------------------------
// all joystick values are roughly normalized -1 to 1
CoolGreatNeatSlew ax; // left joystick x axis
CoolGreatNeatSlew ay; // left joystick y axis
CoolGreatNeatSlew az; // left joystick z axis
CoolGreatNeatSlew bx; // right joystick x axis
CoolGreatNeatSlew by; // right joystick y axis
CoolGreatNeatSlew bz; // right joystick z axis

ax.setRate(0.5,0.5); ay.setRate(0.1,0.1); az.setRate(0.01,0.01);
bx.setRate(0.5,0.5); by.setRate(0.1,0.1); bz.setRate(0.01,0.01);
0 => int fp;
// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;
// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();
<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();
fun void GetGameTrakInput() {
    while( true )
    {
        // wait on HidIn as event
        hi => now;
        
        // messages received
        while( hi.recv( msg ) )
        {
            // dual joysticks axis motion
            if( msg.isAxisMotion() )
            {
                if( msg.which == 0 )
                {
                    msg.axisPosition => bx.target;
                }
                else if( msg.which == 1 ) 
                {
                    msg.axisPosition => by.target;
                }
                else if( msg.which == 2 ) 
                {
                    (msg.axisPosition*-1 + 1)/2.0 => bz.target;
                }
                else if( msg.which == 3 ) 
                {
                    msg.axisPosition => ax.target;
                }
                else if( msg.which == 4 ) 
                {
                    msg.axisPosition => ay.target;
                }
                else if( msg.which == 5 ) 
                {
                    (msg.axisPosition*-1 + 1)/2.0 => az.target;
                }
            }
            
            // footpedal message
            else if( msg.isButtonDown() )
            {
                1 => fp;
                <<< "footpedal depressed " + fp >>>;
                spork ~ killVolume();
                                
            }
            
            else if( msg.isButtonUp() )
            {
                0 => fp;
                <<< "footpedal released " + fp >>>;
                spork ~ restoreVolume();
                spork ~ changeChord();
               	             
            }
        }
    }
}


//----------------------------------------------------------------
// Sound synthesis
//----------------------------------------------------------------

// set up the saws
10 => int numSaws;
BlitSaw bs[numSaws];
CoolGreatNeatSlew freq[numSaws];

// master volume
CoolGreatNeatSlew masterVolume;
masterVolume.setRate(0.0005,0.0008);
1.0 => masterVolume.target;
1.0 => masterVolume.val;

// chain in to the channels
ADSR adsr1 => LPF lpfL => Gain masterL => NRev revL => dac.chan(0);
ADSR adsr2 => LPF lpfR => Gain masterR => NRev revR => dac.chan(1);

// chain into more if possible
if ( dac.channels() == 8 )
{
    dac.channels() => int numChannels;
    revL => dac.chan(numChannels-1) => dac.chan(numChannels-3) => dac.chan(numChannels-5);
    revR => dac.chan(numChannels-2) => dac.chan(numChannels-4) => dac.chan(numChannels-6);

}

// stereo delay
Delay dlyL => lpfL;
dlyL => Gain fbL => dlyL;
0.4 => dlyL.gain;
0.8 => fbL.gain;
540::ms => dlyL.max;
280::ms => dlyL.delay;

Delay dlyR => lpfR;
dlyR => Gain fbR => dlyR;
0.4 => dlyR.gain;
0.8 => fbR.gain;
540::ms => dlyR.max;
260::ms => dlyR.delay;

// set some starter parameters to avoid crazy town
80.0 => lpfL.freq;
80.0 => lpfR.freq;
0.04 => revL.mix => revR.mix;
adsr1.set(0.05, 0.2, 0.2, 0.1);
adsr2.set(0.03, 0.1, 0.2, 0.15);

// here is where we actually assign the saws to stuff
for ( 0 => int i; i < numSaws; i++ )
{
    0.2 => bs[i].gain;
    if ( i % 2 == 0)
    {
        bs[i] => lpfL;
        bs[i] => dlyL;
    }
    else
    {
        bs[i] => lpfR;
        bs[i] => dlyR;
    }
    freq[i].setRate(0.1,0.1);
}

// 36 total notes for goodNotes
[0, 2, 4, 7, 9, 11, 12, 14, 16, 19, 21, 23, 24, 26, 28, 31, 33, 35, 36, 38, 40, 43, 45, 47, 48, 50, 52, 55, 57, 59, 60, 62, 64, 67, 69, 71] @=> int goodNotes[];
// two octaves of major7
[0, 4, 7, 11, 12, 14, 16, 19, 23, 24] @=> int maj7[];
int chord[];

[0, 12, 24, 36, 48] @=> int octaves[];

0 => int base => int indexOffset;

0.03 => float spread;
0.04 => float spreadRange;
7000.0 => float LPFrange;
5.0 => float LPFbase;
0 => int lNoteRange;
1 => int rNoteRange;

300::ms => dur sampsPerBeat;

0 => int tempy;
1.0 => float numSubdivisions;
18 => int root;
0 => int melodyNote;
0 => int prevMelodyNote;
0.25 => float nearnessThresh;

fun float arpFreq(int which)
{
    // this if statement because rand2 of 0 doesn't work
    //if ( noteRange >= 2 ) Math.rand2(0,noteRange/2) => tempy;
    //else 0 => tempy; 
    //return Std.mtof(root + base + octaves[tempy] + maj7[which]);
    12 +=> which; // for bass extension    
    which + indexOffset => which; // for index offset    
    
    if ( which > 35 ) 35 => which;
    if ( which < 0 ) 0 => which;
    return Std.mtof(root + base + goodNotes[which]);

}


fun float bucketSubdivision(float delta)
{
    return Math.floor(Math.fabs(delta)*3.0) + 1;
}

fun void updateParams()
{
    while (true)
    {
        // update frequency
        for ( 0 => int i; i < numSaws; i++ )
        {
            freq[i].val => bs[i].freq;
            
        }
        // update LPF
        (Math.fabs(az.val+bz.val)/2.0 + 0.1)*LPFrange + LPFbase => lpfL.freq => lpfR.freq;
        // update detune spread
        Math.fabs(ay.val-by.val)*spreadRange => spread;
        // update pitch spread
        Math.fabs(ax.val+1)*10 => float rDiff;
        Math.floor(rDiff) $ int => rNoteRange;

        if ( az.val > 0.35 && rNoteRange >= 19 ) 
            (az.val - 0.35)*15 +=> rDiff;
        else if ( az.val > 0.35 && rNoteRange <= 0 ) 
            (az.val - 0.35)*15 -=> rDiff;
        
        Math.floor(rDiff) $ int => rNoteRange;
        //Math.fabs(rDiff - rNoteRange)*100 => float rPhasey;
        //rPhasey => modR.vibratoRate;
        
        Math.fabs(bx.val+1)*10 => float lDiff;
        Math.floor(lDiff) $ int => lNoteRange;

        if ( bz.val > 0.35 && lNoteRange >= 19 ) 
            (bz.val - 0.35)*15 +=> lDiff;
        else if ( bz.val > 0.35 && lNoteRange <= 0 ) 
            (bz.val - 0.35)*15 -=> lDiff;
        Math.floor(lDiff) $ int => lNoteRange;
        //Math.fabs(lDiff - lNoteRange)*100 => float lPhasey;
        //lPhasey => modL.vibratoRate;
        
        // update number of subdivisions per beat
        bucketSubdivision( Math.fabs( -ay.val + -by.val + 2 )*0.4 ) => numSubdivisions;
        // update master volume
        masterVolume.val => masterL.gain => masterR.gain;

        10::ms => now;
    }
}

fun void killVolume()
{
    0.0 => masterVolume.target;
}

fun void restoreVolume()
{
    1.0 => masterVolume.target;
}

OscSend xmits[8];
xmits[0].setHost("poutine.local", 9999);
xmits[1].setHost("poutine.local", 9999);
xmits[2].setHost("poutine.local", 9999);
xmits[3].setHost("poutine.local", 9999);
xmits[4].setHost("poutine.local", 9999);
xmits[5].setHost("poutine.local", 9999);
xmits[6].setHost("poutine.local", 9999);
xmits[7].setHost("poutine.local", 9999);
fun void changeChord()
{
    3 +=> base;
    2 -=> indexOffset;
    if ( base >= 12 ) 0 => base;
    if ( indexOffset <= -8 ) 0 => indexOffset;
    for (0 => int i; i < 8; i++)
    {
        xmits[i].startMsg("/setRoot, i");
    	xmits[i].addInt(root + base);
    }
}

spork ~ updateParams();
float randnote, prevrandnote;
0 => float count;



now % sampsPerBeat => dur offset;
fun void waitToLineUp( float notesPerBeat )
{
    (now - offset) % (sampsPerBeat/notesPerBeat) => dur mod;
    // advance time by the quantization size in samps
    (sampsPerBeat/notesPerBeat) - mod => dur wait;
    (wait + 1::samp) => now;
}

//SndBuf test => dac;
//test.read("snare.aiff");
//fun void testClick()
//{
//    while (true)
//    {
//        0 => test.pos;
//        300::ms => now;
//    }
//}
//spork ~testClick();

while (true)
{
    0 => int bail;
    while ( randnote == prevrandnote && lNoteRange != rNoteRange )
    {
        // break if we have crossed streams
        if ( lNoteRange > rNoteRange + 1 )
        {
            killVolume();
             break;
         }
        restoreVolume(); // if it is down
        bail++;
        arpFreq( Math.rand2(lNoteRange,rNoteRange) ) => randnote;
        if (bail > 20 ) break;
    }
    if ( lNoteRange == rNoteRange || lNoteRange == rNoteRange + 1 )
    {
        restoreVolume(); // if it is down
        arpFreq( Math.rand2(lNoteRange,rNoteRange) ) => randnote;
    }
    <<< lNoteRange, "----", rNoteRange >>>;
    randnote => prevrandnote;
    
    for ( 0 => int i; i < numSaws; i++ )
    {
        randnote*Math.rand2f(1.0 - spread,1.0 + spread) => freq[i].target;
    }
    
    //1 => adsr1.keyOn;
    //1 => adsr2.keyOn;
    
    //waitToLineUp(numSubdivisions);

    sampsPerBeat/numSubdivisions => now;
    
    1.0/numSubdivisions +=> count;
   
}
