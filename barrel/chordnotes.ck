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

0 => ax.val;
0 => bx.val; 

0 => int fp;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();

dac.channels() => int numChans;
if ( numChans == 8 ) 6 => numChans;

42 => int chord_root;
0 => int rootOffset;
0 => int interval;
Delay dly[numChans];
Gain   fb[numChans];
Gain g1 => LPF lf => NRev r => ADSR adsr;

for ( 0 => int i; i < numChans; i++ )
{
    dly[i] => dac.chan(i);
    dly[i] => fb[i] => dly[i];
    0.65 => dly[i].gain;
    0.999 => fb[i].gain;
    600::ms => dly[i].max;
    150::ms => dly[i].delay;
}

-1 => int lastChan;
0 => int newChan;

fun void assignChannel()
{
    Math.rand2(0, numChans-1) => newChan;
    adsr => blackhole;
    if ( lastChan >= 0 ) adsr =< dly[lastChan];
    adsr => dly[newChan];
    newChan => lastChan;
}

assignChannel();

0.0 => g1.gain;

Slew gainSlew;
gainSlew.setRate(0.001,0.1);
0.0 => gainSlew.target;
0.0 => gainSlew.val;

adsr.set( 0.01, 0.08, .1, 0.3 ); // .01 .08 .1 .3
1500 => lf.freq;
4 => lf.Q;
0.09 => r.mix;
BlitSaw s1 => g1;
SinOsc s2 => g1;
Blit s3 => g1;
Wurley s4 => g1;
0.5 => s4.gain;
0.7 => s2.gain;
0.6 => s1.gain => s3.gain;

OscRecv orec;
9999 => orec.port;
orec.listen();
orec.event("/setRoot,i") @=> OscEvent root_event;
orec.event("/sync,i") @=> OscEvent sync_event;


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


now => time sync_point;
fun void listenForSync()
{
    while (true)
    {
        sync_event => now;

	//<<< "Sync!" >>>;
	//<<< now >>>;

        while( sync_event.nextMsg() != 0 )
        {
            sync_event.getInt() => int beat_length_ms;
        }

	now => sync_point;

    }
}
spork ~ listenForSync();

1500 => float min_lpf_freq;
3500 => float max_lpf_freq;

fun void setGain(float gain_percent)
{
	if (gain_percent > 0.5) 
	{
		(gain_percent - 0.5) * 2 => gainSlew.target;

	}
    else
        0.0 => gainSlew.target;
        
    gainSlew.val => g1.gain;
}

fun void setLPF(float gain_percent)
{
    (max_lpf_freq - min_lpf_freq)*gainSlew.val + min_lpf_freq => lf.freq;
}

13 => int numNotes;
[0, 2, 4, 7, 9, 11, 12, 14, 16, 19, 21, 23, 24] @=> int goodNotes[];

fun void setInterval(float percent)
{
	1.5 => float scale;
	scale *=> percent;
	Math.floor( percent*numNotes ) $ int => int ind;
    if ( ind < 0 ) 0 => ind;
    if ( ind > numNotes-1 ) numNotes-1 => ind;
    
	Std.mtof(chord_root + goodNotes[numNotes-ind-1]) => float f;
	setFrequency(f);
}
1.0 => float offset;

spork ~playNotes();
// main loop

while(true) {
    Math.fabs((ax.val - bx.val) / 2) => float x_diff;
    70::ms + (100 * x_diff)::ms => adsr.decayTime;
    
    ((ay.val + by.val) / -2) * 0.5 + 0.5 => float avg_y; // normalize to [0, 1] with 0 being all the way down    
    (bz.val + az.val) / 2 => float avg_z;
    if ( avg_y < 0.46 ) setInterval(avg_z);
    setGain(avg_y * 0.9);
    setLPF(avg_y);
    
    10::ms => now;
    //<<< ax.val, ay.val, az.val, bx.val, by.val, bz.val >>>;
}

fun void playNotes()
{
	300::ms => dur note_length;

	while (true)
	{
	        note_length - ((now - sync_point) % note_length) => dur wait;
		//<<< wait >>>;

		if (wait >= 100::ms)
		{
			assignChannel();
        		((ay.val + by.val) / -2) * 0.5 + 0.5 => float avg_y; // normalize to [0, 1] with 0 being all the way down    
        		if ( avg_y > 0.5 )
        		{
        		    adsr.keyOn();
        		    s4.noteOn(1);
        		}
		}
		wait => now;
	}
}

fun void playNotesNope()
{
    150::ms => dur note_length;
    while (true)
    {
        note_length - ((now - sync_point) % note_length) => dur wait;
	if (wait >= 100::ms)
	{
		assignChannel();
        	((ay.val + by.val) / -2) * 0.5 + 0.5 => float avg_y; // normalize to [0, 1] with 0 being all the way down    
        	if ( avg_y > 0.5 )
        	{
        	    adsr.keyOn();
        	    s4.noteOn(1);
        	}
	}
       	wait => now;
	if (wait >= 100::ms)
	{
		adsr.keyOff();
        	s4.noteOff(1);
	}
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