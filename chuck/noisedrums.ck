// TODO: Sometimes the random parameters OR something being changed too fast/mid-playback cause this to blow up. Figure out how to avoid that (Maybe talk to chris about detecting blown filters)
// TODO: Figure out why the drum seems balanced towards the right

public class NoiseDrum
{
	Mix2 mix => Gain masta_g => Gain master_gain => dac.chan(0) => dac.chan(1);
	0.0 => mix.pan;
    0.5 => master_gain.gain;

	Noise n => BPF bf => mix.left;
	5 => bf.Q;
	Impulse impulse => LPF lf => mix.right;
	10 => lf.Q;
	
	// DRUM SPEC
	60 => float freq_start;
	40 => float freq_end;
	1::second => dur play_time;
	0.99 => float exponent;
	0.15::second => dur pitch_decay;
	1.0 => float volume;
    1.0 => masta_g.gain;

	fun void randomize()
	{
		Std.rand2f(20, 1000) => freq_start;
		Std.rand2f(20, 1000) => freq_end;
		1::second => play_time;
		Std.rand2f(0.97, 0.99) => exponent;
		Std.rand2f(0.1, 1.0)::second => pitch_decay;
		Std.rand2f(0.5, 1) => volume;

		Std.rand2f(2, 4) => bf.Q;
		Std.rand2f(2, 4) => lf.Q;
	}

	fun void print()
	{
		<<< "Freq start: " + freq_start >>>;
		<<< "Freq end: " + freq_end >>>;
		<<< "Exponent: " + exponent >>>;
		<<< "Pitch decay: " >>>;
		<<< pitch_decay >>>;
		<<< "Volume: " + volume >>>;

		<<< "Bandpass Q: " + bf.Q() >>>;
		<<< "Lowpass Q: " + lf.Q() >>>;
		<<< "---------" >>>;
	}
	
	fun void setFrequency(float freq)
	{
		freq => bf.freq;
		freq => lf.freq;
	}

	fun void setGain(float gain)
	{
		gain => mix.gain;
	}


	0.0 => float current_gain;
	now => time pitch_end;
	now => time start;
	0.0 => float freq_diff;
	
	fun void go()
	{
		while (true)
		{
			while (now < pitch_end)
			{
				ms => now;
				(now - start) / pitch_decay => float percent; // Might need to replace this with some linear increase instead of a linear percent, because there will be no absolute play length
				Math.min(percent, 1) => percent;
				setFrequency(freq_start + percent * freq_diff);
				exponent *=> current_gain;
				setGain(volume * current_gain);
			}
			
			ms => now;
			exponent *=> current_gain;
			setGain(volume * current_gain);
		}
	}
	
	fun void play()
	{
		1.0 => current_gain;
		setGain(volume * current_gain);
		setFrequency(freq_start);
		
		now => start;
		now + pitch_decay => pitch_end;
		freq_end - freq_start => freq_diff;
	}
}