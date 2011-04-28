// create our receiver
OscRecv recv;
9999 => recv.port;
recv.listen();

// create an address in the receiver, store in new variable
recv.event( "/chord, f" ) @=> OscEvent oe;

144.0 => float tempo;
(44100*60.0/tempo)::samp => dur TimeUnit;
TimeUnit * 0.5 => dur Half;
Half * 0.5 => dur Quarter;
Quarter * 0.5 => dur Eighth;
Eighth * 0.5 => dur Sixteenth;
16.0 => float quantizationSize;

Blit chord[4];
ADSR e => NRev rev => Gain master_gain => dac;
0.07 => master_gain.gain;
e => Delay dly => rev;
dly => Gain fb => dly;
for ( 0 => int i; i<4; i++ ) chord[i] => e;

rev.mix(0.1);
rev.gain(0.35);
dly.gain(0.6);
TimeUnit => dly.max;
Half => dly.delay;
0.99 => fb.gain;

0 => int thechord;
int whichchord[];

recv.event( "/recurse, f" ) @=> OscEvent recurse;
fun void listenRecurse()
{
    while (true)
    {
        recurse => now;
        while ( recurse.nextMsg() != 0 )
        {
            recurse.getFloat() * 2.0 => float blah;
            if ( blah > 0.96 ) 0.96 => blah;
            dly.gain( blah );
            blah => fb.gain;
        }
    }
}
spork ~ listenRecurse();

// OSC sender
OscSend xmit;
xmit.setHost("10.0.1.4", 9999);

//3::second => ramp.duration;
//ramp.value( 0.0 );

e.set( 5::ms, 20::ms, .3, 150::ms );
e.keyOff();

[0,5,7,10] @=> int maj7[];
[0,2,7,10] @=> int min7[];
[5,9,12,16] @=> int maj[];
[0,3,7,12] @=> int min[];

maj7 @=> whichchord;

// HID
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;
spork ~ keys();
-1 => int index;
fun void updateParams()
{  
    while (true)
    { 
        if ( index == Scenes.current_scene_index ) return;
        Scenes.current_scene_index => index;
        
        Scenes.current_scene.chordFBgain => fb.gain;
		dly.gain(Scenes.current_scene.chordFB);
        1::second => now;
    }
}
spork ~ updateParams();

// infinite time loop
fun void playChord()
{        
    // key on
    e.keyOn();
    
    // advance time
    120::ms => now;
    
    // key off
    e.keyOff();
}

// infinite event loop
while ( true )
{
    // wait for event to arrive
    oe => now;
    
    // grab the next message from the queue. 
    while ( oe.nextMsg() != 0 )
    { 
        oe.getFloat() $ int => thechord;
        
        if ( thechord == 0 )
            maj @=> whichchord;
        if ( thechord == 1 )
            min @=> whichchord;
        if ( thechord == 2 )
        {
            xmit.startMsg("/chord, i");
            xmit.addInt(0);
            maj7 @=> whichchord;
        }
        if ( thechord == 3 )
        {
            xmit.startMsg("/chord, i");
            xmit.addInt(1); 
            min7 @=> whichchord;
        }
        for( 0 => int i; i<4; i++ )
        {
            Std.mtof( whichchord[i] + 43 + Std.rand2(0,3) * 12 ) => chord[i].freq;
            Std.rand2( 1, 5 ) => chord[i].harmonics;
        }
        now % (TimeUnit/quantizationSize) => dur mod;
        // advance time by the quantization size in samps
        (TimeUnit/quantizationSize) - mod => dur wait;
        wait => now;
        
        spork ~ playChord();
        
    }
}


fun void keys()
{
    // infinite event loop
    while( true )
    {
        // wait for event
        hi => now;
        
        // get message
        while( hi.recv( msg ) )
        {
            // check
            if( msg.isButtonDown() )
            {
                if ( msg.which == 225 )
                {
                    min7 @=> whichchord;
                }
                else if ( msg.which == 229 )
                {
                    maj7 @=> whichchord;
                }
                else continue;
                for( 0 => int i; i<4; i++ )
                {
                    Std.mtof( whichchord[i] + 45 + Std.rand2(0,3) * 12 ) => chord[i].freq;
                    Std.rand2( 1, 5 ) => chord[i].harmonics;
                }
                now % (TimeUnit/quantizationSize) => dur mod;
                // advance time by the quantization size in samps
                (TimeUnit/quantizationSize) - mod => dur wait;
                wait => now;

                spork ~ playChord();
            }
        }
    }
}
