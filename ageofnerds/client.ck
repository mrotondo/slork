OscRecv orec;
9999 => orec.port;
orec.listen();
orec.event("/beat,f") @=> OscEvent beat_event;

39 => float subdivision;
[1, 0, 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0,
 1, 0, 1, 0, 1, 1, 1, 1, 0] @=> int play[];

SinOsc s => Envelope e => dac;

10::ms => e.duration;

fun void playNote()
{
	1 => e.keyOn;
	e.duration() => now;
	1 => e.keyOff;
	e.duration() => now;
}

fun void playBeatSubdivisions( dur beat )
{
	0 => int currentSubdivision;
	while ( currentSubdivision < subdivision )
	{
		if ( play[currentSubdivision] )
		{
			spork ~ playNote();
		}
		1 +=> currentSubdivision;
		beat / subdivision => now; 
	}
}

while (true)
{
	beat_event => now;
	1 => float bpm;
	while( beat_event.nextMsg() != 0 )
    {   
        beat_event.getFloat() => bpm;
    }
	1::minute / bpm => dur beat;
	spork ~ playBeatSubdivisions( beat );
}