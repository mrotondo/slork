// create our receiver
OscRecv recv;
9999 => recv.port;
recv.listen();

1 => int smooth;

144.0 => float tempo;
(44100*60.0/tempo)::samp => dur TimeUnit;
TimeUnit * 0.5 => dur Half;
Half * 0.5 => dur Quarter;
Quarter * 0.5 => dur Eighth;
Eighth * 0.5 => dur Sixteenth;
16.0 => float quantizationSize;

BlowBotl s => JCRev rev => Gain gain => dac;
0.0 => s.noiseGain;

0.5 => gain.gain;

s => Delay dly => rev;
dly => Gain fb => dly;
rev.mix(0.1);
rev.gain(0.35);
dly.gain(0.7);
TimeUnit => dly.max;
Half => dly.delay;
0.99 => fb.gain;

[0,3,5,7,8, 10,12,15,17, 19,20,22,24,27, 
 29,31,32,34,36, 39,41,43,44,46, 48,51,53,55,56] @=> int notes[];

0 => int thenote;
0.0 => float vel;
440.0 => float fTarget;

fun void slewFreq()
{
    while (true)
    {
        0.0005*(fTarget-s.freq()) + s.freq() => s.freq;
        //fTarget => s.freq;
        1::samp => now;
    }
}

if (smooth) spork ~ slewFreq();

// create an address in the receiver, store in new variable
recv.event( "/string, f, f" ) @=> OscEvent oe;

// infinite event loop
while ( true )
{
    // wait for event to arrive
    oe => now;
    
    // grab the next message from the queue. 
    while ( oe.nextMsg() != 0 )
    { 
        oe.getFloat() $ int => thenote;
        1.0 - oe.getFloat() => vel;
        
        if ( thenote < 0 ) 0.4 => s.noteOff;
        else
        {
            if (smooth) Std.mtof(43 + notes[thenote]) => fTarget;//s.freq;
            else Std.mtof(43 + notes[thenote]) => s.freq;

            0.25 * vel => s.noteOn;
        }
        
    }
}