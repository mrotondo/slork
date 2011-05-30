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
0 => int interval;
Gain g1 => LPF lf => dac;

SawOsc s1 => g1;
SawOsc s2 => g1;
SawOsc s3 => g1;

OscRecv orec;
9999 => orec.port;
orec.listen();
orec.event("/setRoot,i") @=> OscEvent root_event;


fun void setFrequency(float f)
{
	f * 0.99 => s1.freq;
	f => s2.freq;
	f * 1.01 => s3.freq;
}
setFrequency(Std.mtof(chord_root));

fun void listenForRoot()
{
    while (true)
    {
        root_event => now;
        while( root_event.nextMsg() != 0 )
        {
            root_event.getInt() => chord_root;
        }
	<<< "Got a root! " + chord_root >>>;
	Std.mtof(chord_root + interval) => float f;
	setFrequency(f);
    }
}
spork ~ listenForRoot();

8 => float env_freq;
SawOsc env => blackhole;
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
	if (gain_percent > 0.5) 
	{
		(gain_percent - 0.5) * 2 => g1.gain;
	}
}

fun void setInterval(float percent)
{
	<<< percent >>>;
	if (percent < 0.4)
	{
		0 => interval;
	}
	if (percent > 0.4 && percent < 0.7)
	{
		7 => interval;
	}
	else if (percent >= 0.7)
	{
		12 => interval;
	}
	Std.mtof(chord_root + interval) => float f;
	setFrequency(f);
}

// main loop
while(true) {
    1::samp => now;
    (env.last() * 0.5 + 0.5) * env_mul + env_add => lf.freq;

    (bz.val + az.val) / 2 => float avg_z;
    setInterval(avg_z);

    Math.fabs((ax.val - bx.val) / 2) => float x_diff;
    setLFOFrequency(x_diff);

    ((ay.val + by.val) / -2) * 0.5 + 0.5 => float avg_y; // normalize to [0, 1] with 0 being all the way down
    setGain(avg_y);

    1::samp => now;
    //<<< ax.val, ay.val, az.val, bx.val, by.val, bz.val >>>;
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