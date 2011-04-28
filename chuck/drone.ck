class FeedborkListener
{
    OscEvent @ event;
    
    fun void init(OscRecv orec, string event_name, string event_type)
    {
        orec.event("/" + event_name + "," + event_type) @=> event;
    }
    
    fun void go()
    {
        while (true)
        {
            event => now;
            
            while (event.nextMsg() != 0)
            {
                handleEvent();
            }
        }
    }
    
    fun void handleEvent()
    {
}
}

class FloatListener extends FeedborkListener
{    
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",f") @=> event;
    }
}

class IntListener extends FeedborkListener
{    
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",i") @=> event;
    }
}

class PointListener extends FeedborkListener
{
    fun void init(OscRecv orec, string event_name)
    {
        orec.event("/" + event_name + ",f f") @=> event;
    }	
}

TriOsc t1 => JCRev revL => Gain gL => Gain gFinL => dac.chan(0);
Blit t2   => JCRev revR => Gain gR => Gain gFinR => dac.chan(1);

0.05 => gFinL.gain => gFinR.gain;

0.003 => gR.gain => gL.gain;

TriOsc t3 => revL;
Blit t4 => revR;

TriOsc t5 => revL;
Blit t6 => revR;

4 => t2.harmonics;
5 => t4.harmonics;
5 => t6.harmonics;

SinOsc m1 => blackhole;
0.005 => m1.freq;
SinOsc m2 => blackhole;
0.0045 => m2.freq;
SinOsc m3 => blackhole;
0.0065 => m3.freq;
SinOsc m4 => blackhole;
0.006 => m2.freq;
SinOsc m5 => blackhole;
0.0075 => m5.freq;
SinOsc m6 => blackhole;
0.007 => m6.freq;
55 => int base;
Std.mtof(base) => float cf1 => t1.freq;
Std.mtof(base) + .3 => float cf2 => t2.freq;

Std.mtof(base+7) => float cf3 => t3.freq;
Std.mtof(base+7) + .3 => float cf4 => t4.freq;

Std.mtof(base+12) => float cf5 => t5.freq;
Std.mtof(base+12) + .3 => float cf6 => t6.freq;

4.0 => float index;

0.005 => float gain_target;

0.5 => float g1;



// create our OSC receiver for messages from the iPad
OscRecv orec;
// port 9999
9999 => orec.port;
// start listening (launch thread)
orec.listen();

class IndexListener extends FloatListener
{
    fun void handleEvent()
    {
        event.getFloat() => float f;
		0.08 * f => gain_target;
		Math.max(gain_target, 0.005) => gain_target;
	}
}
IndexListener index_listener;
index_listener.init(orec, "brightness");
spork ~ index_listener.go();

while (true)
{
	//<<< (gain_target - gL.gain()) +5 gL.gain() >>>;
	0.00001 => float slew_rate;
	if (gain_target < gL.gain()) {
		0.0001 => slew_rate;
	}
	slew_rate * (gain_target - gL.gain()) + gL.gain() => gL.gain => gR.gain;
	
    gL.gain() * 30.0 => index;
    
	cf1 + index*(m1.last()) => t1.freq;
	cf2 + index*(m2.last()) => t2.freq;
	cf3 + index*(m3.last()) => t3.freq;
	cf4 + index*(m4.last()) => t4.freq;
	cf5 + index*(m3.last()) => t5.freq;
	cf6 + index*(m4.last()) => t6.freq;

	//g1 + 0.3*(m4.last()) => t1.gain;
	//g1 + 0.3*(m3.last()) => t2.gain;
	//g1 + 0.3*(m2.last()) => t3.gain;
	//g1 + 0.3*(m1.last()) => t4.gain;
	g1 + 0.3*(m6.last()) => t5.gain;
	g1 + 0.3*(m5.last()) => t6.gain;
	
	1::samp => now; 
}