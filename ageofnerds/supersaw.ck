
// =======================================================================================
//
// Supersaw Abstraction
//
// Jason Riggs
// jnriggs@stanford.edu
// http://slork.stanford.edu
//
// =======================================================================================

public class SuperSaw
{
    
    // private constants
	0.03 => float kMasterGain;
	6 => int kMaxPolyphony;
	5 => int kNumOscillators;
	2 => int kSpeakerGroups;
	4.0 => float kMaxDetuneSpread;
	20.0 => float kMinLpfFreq;
	20000.0 => float kMaxLpfFreq;
	4 => int kMaxTimbres;
	0 => int kDefaultTimbre;
    0.008 => float detuneSensitivity;
    
    2.0 => float kMaxxPos;
    4 => float kCurvePow;
	0.64 => float kLpfSensitivity; // set from 0 to 1

	// this value will be used in the function detuneSpreader to fix an amplitude
	// problem inherent in the way the oscillators are being detuned. see comment
	// inside detuneSpreader for more info. it is being placed here because we need
	// to calculate it only once.
	(kMasterGain/(2*kMaxDetuneSpread)) => float kDetuneSlope;
	
    // lpf sensitivity power
    kMaxxPos => float xPos;
    
	// private global variables
    kMaxDetuneSpread / 2 => float detuneSpread;
    kDefaultTimbre => int timbre;
    0 => int currentNotesPlaying;

    // OSC stuff
    OscRecv recv;
    7007 => recv.port;
    recv.listen();
    recv.event( "/inst/filter, i" ) @=> OscEvent filter_event;
    recv.event( "/inst/detune, i" ) @=> OscEvent detune_event;
    recv.event( "/inst/play, f f i f f f f" ) @=> OscEvent play_event;
    // freq, velocity, timbre, envelope (adrr);
    
    private void oscModifyLPF(OscEvent osc_event)
    {
        while (true)
        {
            osc_event => now;
            while( osc_event.nextMsg() != 0 )
            {
                osc_event.getInt() / 4.0 => modifyLPF;
            }
        }
    }
    
    private void oscModifyDetune(OscEvent osc_event)
    {
        while (true)
        {
            osc_event => now;
            while( osc_event.nextMsg() != 0 )
            {
                osc_event.getInt() => modifyDetune;
            }
        }
    }

	private void oscPlayNote(OscEvent osc_event)
    {
        while (true)
        {
            osc_event => now;
            while( osc_event.nextMsg() != 0 )
            {
                spork ~ playNote(osc_event.getFloat(), osc_event.getFloat(), osc_event.getInt(), osc_event.getFloat(), osc_event.getFloat(), osc_event.getFloat(), osc_event.getFloat());
            }
        }
    }
    
    spork ~ oscModifyLPF(filter_event);
    spork ~ oscModifyDetune(detune_event);
	spork ~ oscPlayNote(play_event);

	// -----------------------master sound gen patch---------------------------|

	// LPF
	LPF l[kSpeakerGroups];
	for (0 => int i; i < l.cap(); i++)
	{
		kMaxLpfFreq => l[i].freq;
		3.2 => l[i].Q;
	}

	// reverb
	JCRev r[l.cap()];
	for (0 => int i; i < r.cap(); i++)
	{
		0.01 => r[i].mix;
		l[i] => r[i];
	}

	// gain
	Gain g[l.cap()];
	for (0 => int i; i < g.cap(); i++)
	{
		(kDetuneSlope)*detuneSpread + (kMasterGain / 2) => g[i].gain;
		r[i] => g[i];
	}

	// ---------------------end master sound gen patch-------------------------|

    // ----parameter modification hooks (private; called by osc* functions)----|
    
    public void connect( UGen ugen )
    {
		<<< "connecting", kSpeakerGroups, "speaker groups to", ugen.channels(), "output channels" >>>;
		for (0 => int i; i < ugen.channels(); i++)
		{
        	g[i % kSpeakerGroups] => ugen.chan(i % ugen.channels());
			//g[1] => ugen.chan(i % ugen.channels());//TODO
		}
    }
    
    private void modifyLPF(float change)
    {
        
        // function makes the LPF smooth across the trackpad
        1.0/(800.0 - 400.0*kLpfSensitivity) * change +=> xPos;
        if(xPos < 0) 0 => xPos;
        if(xPos > kMaxxPos) kMaxxPos => xPos;
        ((kMaxLpfFreq - kMinLpfFreq)/(Math.pow(kMaxxPos, kCurvePow)))*Math.pow(xPos, kCurvePow) + kMinLpfFreq => float newFreq;
        for (0 => int i; i < l.cap(); i++)
        {
            newFreq => l[i].freq;
        }
        //<<<newFreq>>>;
    }

    // y-axis detune change
    private void modifyDetune(int change)
    {
        if(detuneSpread >= 0 && detuneSpread <= kMaxDetuneSpread)
        {
            // subtraction reverses y-axis direction
            detuneSpread - detuneSensitivity*change => float newDetuneSpread;
            if(newDetuneSpread < 0) {
                0 => detuneSpread;
            } else if(newDetuneSpread > kMaxDetuneSpread) { 
                kMaxDetuneSpread => detuneSpread;
            } else {
                newDetuneSpread => detuneSpread;
            }
        }

        // detune spread is now where we want it, so alter master gain accordingly
        // this fixes the problem inherent in detuning the oscillators whereby
        // more-detuned oscillators have lower average amplitude than less-detuned ones
        // BUGGED. TODO: only modify this for next note
		for (0 => int i; i < g.cap(); i++)
		{
			(kDetuneSlope)*detuneSpread + (kMasterGain / 3.0) => g[i].gain;
		}
    }

    // play a single note
    public void playNote(float freq, float velocity, int timbre, float att, float dec, float sus, float rel)
    {
        if(currentNotesPlaying + 1 > kMaxPolyphony) {
            //<<< "Polyphony limit reached. Current # Notes Playing: ", currentNotesPlaying >>>;
            return;
        }
        
        currentNotesPlaying++;
        Event e;
        
        // Some notes are played in mono,
        // while others are played in up
        // to kSpeakerGroups. This still
        // spatializes the sound while
        // adding noticable efficiency.
        Std.rand2(1, kSpeakerGroups) => int speakerGroups;
        
        // envelopes
        ADSR env[l.cap()];
        att*1::second => dur curNoteAtt;
        dec*1::second => dur curNoteDec;
        sus => float curNoteSus;
        rel*1::second => dur curNoteRel;
		for (0 => int i; i < env.cap(); i++)
		{
			env[i].set(curNoteAtt, curNoteDec, curNoteSus, curNoteRel);
		}

		int oscillator_channels[kNumOscillators];
		Std.rand2(0, speakerGroups - 1) => int speaker_offset;
        for (0 => int i; i < oscillator_channels.cap(); i++)
		{
			(Std.rand2(0, speakerGroups - 1) + speaker_offset) % speakerGroups => oscillator_channels[i];
		}

		//UGen @ oscs[kNumOscillators];
        //if(timbre == 0)      { for (0 => int i; i < oscs.cap(); i++) { new SinOsc @=> oscs[i]; } }
        //else if(timbre == 1) { for (0 => int i; i < oscs.cap(); i++) { new TriOsc @=> oscs[i]; } }
        //else if(timbre == 2) { for (0 => int i; i < oscs.cap(); i++) { new SqrOsc @=> oscs[i]; } }
        //else if(timbre == 3) { for (0 => int i; i < oscs.cap(); i++) { new SawOsc @=> oscs[i]; } }
		if(timbre == 0) 
        {
            SinOsc oscs[kNumOscillators];
            for(int i; i < kNumOscillators; i++)
            {
                freq + Std.rand2f(-detuneSpread, detuneSpread) => oscs[i].freq;
                oscs[i] => env[oscillator_channels[i]];
            }
        }
        else if(timbre == 1)
        {
            TriOsc oscs[kNumOscillators];
            for(int i; i < kNumOscillators; i++)
            {
                freq + Std.rand2f(-detuneSpread, detuneSpread) => oscs[i].freq;
                oscs[i] => env[oscillator_channels[i]];
            }
        }
        else if(timbre == 2)
        {
            PulseOsc oscs[kNumOscillators];
            for(int i; i < kNumOscillators; i++)
            {
                freq + Std.rand2f(-detuneSpread, detuneSpread) => oscs[i].freq;
                oscs[i] => env[oscillator_channels[i]];
            }
        }
        else if(timbre == 3)
        {
            SawOsc oscs[kNumOscillators];
            for(int i; i < kNumOscillators; i++)
            {
                freq + Std.rand2f(-detuneSpread, detuneSpread) => oscs[i].freq;
                oscs[i] => env[oscillator_channels[i]];
            }
        }
        else
        {
            <<< "Error: Invalid Timbre Selection." >>>;
        }

        // mmm... beeeeefy
        SinOsc sin;
        (freq / 2) => sin.freq;
        .13 => sin.gain;
		for (0 => int i; i < l.cap(); i++)
		{
        	sin => env[i];
		}

        // mmm... crispy (sinosc, no crisp for you.)
        if(timbre != 0) 
        {
            Noise n;
            .02 => n.gain;
            for (0 => int i; i < l.cap(); i++)
			{
        		n => env[i];
			}
        }

        // connect envs to master patchbay
		for (0 => int i; i < l.cap(); i++)
		{
        	env[i] => l[i];
			env[i].keyOn();
		}
		
		spork ~ killSound(e, curNoteAtt+curNoteDec+curNoteRel);
        // wait for note to be released
        e => now;

        // end note
        for (0 => int i; i < l.cap(); i++)
		{
        	env[i].keyOff();
		}
        curNoteRel => now;
        for (0 => int i; i < l.cap(); i++)
		{
        	env[i] =< l[i];
		}

        currentNotesPlaying--;
    }
    
    private void killSound(Event e, dur note_time)
    {
        note_time => now;
        e.signal();
    }
}

