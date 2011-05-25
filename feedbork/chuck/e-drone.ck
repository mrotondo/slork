// output patch
JCRev r => dac;
// gain
.005 => r.gain;
// reverb mix
.05 => r.mix;

// # of voices
3 => int N;
// sets of UGen's
SinOsc m[N];
SqrOsc s[N];
LPF f[N];
HPF g[N];

// connect
for( int i; i < m.cap(); i++ )
{
    m[i] => s[i] => f[i] => g[i] => r;
    2 => s[i].sync;
    200 * i => m[i].freq;
    400 * i => m[i].gain;
}

// carrier freq
60 => Std.mtof => s[0].freq;
65 => Std.mtof => s[1].freq;
71 => Std.mtof => s[2].freq;

// spork control
spork ~ control( s[0], f[0], g[0], 43::ms, .6 );
spork ~ control( s[1], f[1], g[1], 77::ms, .7 );
spork ~ control( s[2], f[2], g[2], 97::ms, .8 );

// go
while( true ) 1::second => now;



// control shred
fun void control( Osc s, LPF f, HPF g, dur T, float freq )
{
    // time loop
    while( true )
    {
        // set low pass cutoff
        s.freq()*1.5 + s.freq() * 
            Math.sin(now/second*freq) => f.freq;
        // set high pass cutoff
        f.freq() / 2 => g.freq;
        // set resonances
        4 => f.Q;
        2 => g.Q;

        // time step
        T => now;
    }
}
