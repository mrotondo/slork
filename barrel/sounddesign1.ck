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

ax.setRate(0.01,0.01); ay.setRate(0.005,0.01); az.setRate(0.001,0.001);
bx.setRate(0.01,0.01); by.setRate(0.005,0.01); bz.setRate(0.001,0.001);
 
 
Slew sfreqR, sfreqL;
sfreqR.setRate(0.001,0.001);
sfreqL.setRate(0.001,0.001);

0 => int fp;


// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();

SqrOsc sinL => Gain sL => ResonZ fL => Gain gL => JCRev revL => dac.chan(0);
SqrOsc sinR => Gain sR => ResonZ fR => Gain gR => JCRev revR => dac.chan(1);

fL => Delay dlyL => revL;
dlyL => Gain fbL => dlyL;
0.6 => fbL.gain;
0.5::second => dlyL.max;
0.32::second => dlyL.delay;

fR => Delay dlyR => revR;
dlyR => Gain fbR => dlyR;
0.6 => fbR.gain;
0.5::second => dlyR.max;
0.31::second => dlyR.delay;

BlitSaw triL => Gain tL => fL;
BlitSaw triR => Gain tR => fR;

0.5 => triL.gain => triR.gain;
0.7 => sinL.gain => sinR.gain;

0.04 => revL.mix => revR.mix;

[0, 7, 12, 17, 24, 27, 30, 36, 42, 48, 60, 22, 24, 26, 28, 30, 32] @=> int goodNotes[];

32 => int base;

fun float bucketFreq(float freq)
{
    Math.floor(freq) $ int => int which;
    return Std.mtof(base + goodNotes[which]);
}

// main loop
while(true) {
    -ay.val - 0.0 => float newgL;
    if ( newgL < 0.0 ) 0.0 => newgL;
    newgL => gL.gain;
    -by.val - 0.0 =>float newgR;
    if ( newgR < 0.0 ) 0.0 => newgR;
    newgR => gR.gain;
    
    (ax.val + 1)/2.0 => tL.gain;
    (bx.val + 1)/2.0 => tR.gain;
    
    (ax.val+1)*50.0 => fL.Q;
    (bx.val+1)*50.0 => fR.Q;
    
    1.0 - tL.gain() => sL.gain;
    1.0 - tR.gain() => sR.gain;
    
    ax.val - bx.val + 2.0 => float mod;
       
    if ( -by.target > 0.4 )
    {
        bucketFreq( (1.0-bz.val) * 9 ) => sfreqR.target;
    }
    
    if ( -ay.target > 0.4 )
    {
        bucketFreq( (1.0-az.val) * 9 ) => sfreqL.target;
    }
    
    //mod*5.0 + sfreqL.target => sfreqL.target;
    //-mod*5.0 + sfreqR.target => sfreqR.target;
    
    sfreqL.val + mod*5.0 => sinL.freq; sinL.freq() * 1.02 => triL.freq;
    sfreqR.val + mod*5.0 => sinR.freq; sinR.freq() * 0.98 => triR.freq;
    
    -ay.val => float tempAy;
    -by.val => float tempBy;
    
    if ( tempAy < 0.0003 ) 0.0003 => tempAy;
    if ( tempBy < 0.0003 ) 0.0003 => tempBy;
    
    tempAy*3000.0 + sfreqL.val/10.0 => fL.freq;
    tempBy*3000.0 + sfreqR.val/10.0 => fR.freq;
    
    2::samp => now;
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