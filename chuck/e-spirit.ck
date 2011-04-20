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
ADSR e => NRev rev => dac;
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

//3::second => ramp.duration;
//ramp.value( 0.0 );

e.set( 5::ms, 20::ms, .3, 150::ms );


[ [0, 5, 11, 16], [0, 4, 11, 12], [5, 7, 12, 16] ] @=> int c[][];
[0,4,7,11] @=> int maj7[];
[0,3,7,10] @=> int min7[];
[0,4,7,12] @=> int maj[];
[0,3,7,12] @=> int min[];

maj7 @=> whichchord;

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
            maj7 @=> whichchord;
        if ( thechord == 3 )
            min7 @=> whichchord;
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