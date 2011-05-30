// make HidIn and HidMsg
Hid hi;
HidMsg msg;

// cool great neat slew
class Slew
{
    0.0 => float attack;
    0.0 => float decay;
    3.0 => float target;
    3.0 => float val;
    3.0 => float diff;
    
    fun void setRate(float _attack, float _decay)
    {
        _attack => attack;
        _decay => decay;
    }
    
    fun void setTarget(float _target)
    {
        _target => target;
    }
    
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

// all joystick values are roughly normalized -1 to 1
Slew ax; // left joystick x axis
Slew ay; // left joystick y axis
Slew az; // left joystick z axis
Slew bx; // right joystick x axis
Slew by; // right joystick y axis
Slew bz; // right joystick z axis

ax.setRate(0.01,0.01); ay.setRate(0.005,0.01); az.setRate(0.01,0.01);
bx.setRate(0.01,0.01); by.setRate(0.005,0.01); bz.setRate(0.01,0.01);
 
0 => int fp;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();

42 => int chord_root;
0 => int rootOffset;
0 => int interval;
Gain g1 => LPF lf => NRev r => ADSR adsr => dac;


Slew gainSlew;
gainSlew.setRate(0.001,0.1);

adsr.set( 0.01, 0.08, .1, 0.3 ); 
1800 => lf.freq;
4 => lf.Q;
0.08 => r.mix;
BlitSaw s1 => g1;
SinOsc s2 => blackhole;//g1;
Blit s3 => g1;
Wurley s4 => g1;
0.5 => s4.gain;


0.6 => s1.gain => s3.gain;

OscRecv orec;
9999 => orec.port;
orec.listen();
orec.event("/setRoot,i") @=> OscEvent root_event;


fun void setFrequency(float f)
{
	f * 2 * 0.999 => s1.freq;
	f * 2 => s2.freq;
	f * 4 * 1.001 => s3.freq;
    f * 2 => s4.freq;
}
setFrequency(Std.mtof(chord_root));

fun void listenForRoot()
{
    while (true)
    {
        root_event => now;
        while( root_event.nextMsg() != 0 )
        {
            root_event.getInt() + 24 => chord_root;
        }
	<<< "Got a root! " + chord_root >>>;
	if ( chord_root == 3 ) 2 => rootOffset;
    else if ( chord_root == 6 ) 4 => rootOffset;
    else if ( chord_root == 9 ) 6 => rootOffset;
    else if ( chord_root == 0 ) 8 => rootOffset;
    }
}
spork ~ listenForRoot();

8 => float env_freq;
TriOsc env => blackhole;
//env.harmonics(0);
env_freq => env.freq;
40 => float env_add;
4960 => float env_mul;

20 => float min_freq;
100 => float max_freq;

1 => float min_lfo_freq;
16 => float max_lfo_freq;
fun void setLFOFrequency(float freq_percent)
{
	min_lfo_freq + (max_lfo_freq - min_lfo_freq) * freq_percent => float f;
	f => env.freq;
}

fun void setGain(float gain_percent)
{
	if (gain_percent > 0.4) 
	{
		(gain_percent - 0.4) * 2 => gainSlew.target;

	}
    else
        0.0 => gainSlew.target;
    gainSlew.val => g1.gain;
}

7 => int numNotes;
[0, 2, 4, 7, 9, 11, 12] @=> int goodNotes[];

fun void setInterval(float percent)
{
	1.5 => float scale;
	scale *=> percent;

	//<<< percent >>>;
	Math.floor( percent*numNotes ) $ int => int ind;
    if ( ind < 0 ) 0 => ind;
    if ( ind > numNotes-1 ) numNotes-1 => ind;
    
	Std.mtof(chord_root + goodNotes[ind]) => float f;
	setFrequency(f);
}
spork ~playNotes();
1 => int canPlay;
// main loop
while(true) {
    //(env.last() * 0.5 + 0.5) * env_mul + env_add => lf.freq;

    //Math.fabs((ax.val - bx.val) / 2) => float x_diff;
    //setLFOFrequency(x_diff);
    
    ((ay.val + by.val) / -2) * 0.5 + 0.5 => float avg_y; // normalize to [0, 1] with 0 being all the way down    
    (bz.val + az.val) / 2 => float avg_z;
    if ( avg_y > 0.5 ) setInterval(avg_z);
    setGain(avg_y);
    
    10::samp => now;
    //<<< ax.val, ay.val, az.val, bx.val, by.val, bz.val >>>;
}

fun void playNotes()
{
    while (true)
    {
        adsr.keyOn();
        s4.noteOn(1);
        100::ms => now;
        adsr.keyOff();
        s4.noteOff(1);
        50::ms => now;
    }
}

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
            }
            
            else if( msg.isButtonUp() )
            {
                0 => fp;
                <<< "footpedal released " + fp >>>;
            }
        }
    }
}