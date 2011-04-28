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

0.3 => gain.gain;

s => Delay dly => rev;
dly => Gain fb => dly;
rev.mix(0.1);
rev.gain(0.35);
dly.gain(0.9);
TimeUnit => dly.max;
Half => dly.delay;
0.9999 => fb.gain;

s => Delay dly2 => rev;
dly2 => Gain fb2 => dly2;
//rev.mix(0.1);
//rev.gain(0.35);
dly2.gain(0.9);
TimeUnit => dly2.max;
Half + 200::ms => dly2.delay;
0.9999 => fb2.gain;

[0,4,5,7,8, 10,12,16,17, 19,20,22,24,28, 
 29,31,32,34,36, 40,41,43,44,46, 48,52,53,55,56] @=> int notes[];

0 => int thenote;
0.0 => float vel;
440.0 => float fTarget;

fun void slewFreq()
{
    while (true)
    {
        0.005*(fTarget-s.freq()) + s.freq() => s.freq;
        //fTarget => s.freq;
        1::samp => now;
    }
}

if (smooth) spork ~ slewFreq();
-1 => int index;
fun void updateParams()
{  
    while (true)
    { 
        if ( index == Scenes.current_scene_index ) return;
        Scenes.current_scene_index => index;
        
        Scenes.current_scene.stringsFBgain => fb.gain => fb2.gain;
        dly.gain(Scenes.current_scene.stringsFB);
        dly2.gain(Scenes.current_scene.stringsFB);
        
        1::second => now;
    }
}
       
spork ~ updateParams();

// create an address in the receiver, store in new variable
recv.event( "/string, f, f" ) @=> OscEvent oe;
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
            dly2.gain( blah );
            blah => fb.gain => fb2.gain;
        }
    }
}
spork ~ listenRecurse();
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