KBHit kb;

4096::samp => dur T;

// patch
Impulse i => BiQuad f => Envelope e => DelayL d => Gain g => d => JCRev r => dac;

1::second => d.max;
T => d.delay;
0.9 => g.gain;

// set the filter's pole radius
.99 => f.prad;
// set equal gain zeros
1 => f.eqzs;
// envelope rise/fall time
1::ms => e.duration;
// reverb mix
.02 => r.mix;

fun void triggerSounds()
{
	while (true)
	{
		// wait on event
		kb => now;
		
		// loop through 1 or more keys
		while( kb.more() )
		{
			// get key...
			kb.getchar() => int c;
			
			// set filtre freq
			c => Std.mtof => f.pfreq;
			// print int value
			<<< "ascii:", c >>>;
			
			// fire an impulse
			1.0 => i.next;
			// open
			e.keyOn();
			// advance time
			T-2::ms => now;
			// close
			e.keyOff();
		}
	}
}

spork ~ triggerSounds();

while( true )
{
	day => now;
}