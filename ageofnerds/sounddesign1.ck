// make HidIn and HidMsg
Hid hi;
HidMsg msg;

// cool great neat slew
class Slew
{
    0.0 => float rate;
    0.0 => float target;
    0.0 => float val;
    
    fun void setRate(float _rate)
    {
        _rate => rate;
    }
    
    fun void setTarget(float _target)
    {
        _target => target;
    }
    
    fun float tick()
    {
        while (true)
        {
            (target-val)*rate + val => val;
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

ax.setRate(0.01); ay.setRate(0.01); az.setRate(0.01);
bx.setRate(0.01); by.setRate(0.01); bz.setRate(0.01);
 
0 => int fp;


// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openJoystick( device ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;
spork ~GetGameTrakInput();

SinOsc sinL => Gain sL => Gain gL => JCRev revL => dac.chan(0);
SinOsc sinR => Gain sR => Gain gR => JCRev revR => dac.chan(1);

SqrOsc triL => Gain tL => gL;
SqrOsc triR => Gain tR => gR;

0.1 => revL.gain => revR.gain;

// main loop
while(true) {
    az.val => gL.gain;
    bz.val => gR.gain;
    
    (ax.val + 1)/1.0 => tL.gain;
    (bx.val + 1)/1.0 => tR.gain;
    
    2.0 - tL.gain() => sL.gain;
    2.0 - tR.gain() => sR.gain;
    
    (ay.val + 1) * 400.0 => sinL.freq => triL.freq;
    (by.val + 1) * 400.0 => sinR.freq => triR.freq;
    
    20000::samp => now;
    <<< ax.val, ay.val, az.val, bx.val, by.val, bz.val >>>;
}


fun void GetGameTrakInput() {
    while( true )
    {
        // wait on HidIn as event
        hi => now;
        
        <<< "GOT EVENT" >>>;
        
        // messages received
        while( hi.recv( msg ) )
        {
            <<< msg >>>;
            
            // dual joysticks axis motion
            if( msg.isAxisMotion() )
            {
                if( msg.which == 0 )
                {
                    msg.axisPosition => ax.target;
                }
                else if( msg.which == 1 ) 
                {
                    msg.axisPosition => ay.target;
                }
                else if( msg.which == 2 ) 
                {
                    (msg.axisPosition*-1 + 1)/2.0 => az.target;
                }
                else if( msg.which == 3 ) 
                {
                    msg.axisPosition => bx.target;
                }
                else if( msg.which == 4 ) 
                {
                    msg.axisPosition => by.target;
                }
                else if( msg.which == 5 ) 
                {
                    (msg.axisPosition*-1 + 1)/2.0 => bz.target;
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