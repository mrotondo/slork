// make HidIn and HidMsg
Hid hi;
HidMsg msg;

// cool great neat slew
class Slew
{
    0.0 => float attack;
    0.0 => float decay;
    0.0 => float target;
    0.0 => float val;
    0.0 => float diff;
    
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

ax.setRate(0.01,0.01); ay.setRate(0.005,0.0001); az.setRate(0.001,0.001);
bx.setRate(0.01,0.01); by.setRate(0.005,0.0001); bz.setRate(0.001,0.001);
 
 
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

SqrOsc sinL => Gain sL => Gain gL => JCRev revL => dac.chan(0);
SqrOsc sinR => Gain sR => Gain gR => JCRev revR => dac.chan(1);

TriOsc triL => Gain tL => gL;
TriOsc triR => Gain tR => gR;

0.5 => triL.gain => triR.gain;
0.7 => sinL.gain => sinR.gain;

0.1 => revL.mix => revR.mix;

[0, 2, 3, 5, 7, 10, 12, 14, 15, 18, 20, 22, 24, 26, 28, 30, 32] @=> int goodNotes[];

42 => int base;

fun float bucketFreq(float freq)
{
    Math.floor(freq) $ int => int which;
    return Std.mtof(base + goodNotes[which]);
}

// main loop
while(true) {
    -ay.val - 0.4 => float newgL;
    if ( newgL < 0.0 ) 0.0 => newgL;
    newgL => gL.gain;
    -by.val - 0.4 =>float newgR;
    if ( newgR < 0.0 ) 0.0 => newgR;
    newgR => gR.gain;
    
    (ax.val + 1)/2.0 => tL.gain;
    (bx.val + 1)/2.0 => tR.gain;
    
    1.0 - tL.gain() => sL.gain;
    1.0 - tR.gain() => sR.gain;
    
    if ( -by.target > 0.4 )
    {
        bucketFreq( (1.0-az.val) * 9 ) => sfreqL.target;
        bucketFreq( (1.0-bz.val) * 9 ) => sfreqR.target;
    }
    sfreqL.val => sinL.freq => triL.freq;
    sfreqR.val => sinR.freq => triR.freq;
    
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