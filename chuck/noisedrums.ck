// TODO: Sometimes the random parameters OR something being changed too fast/mid-playback cause this to blow up. Figure out how to avoid that (Maybe talk to chris about detecting blown filters)

public class NoiseDrum
{
	Mix2 mix => dac.chan(0) => dac.chan(1);
	0.0 => mix.pan;

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

	fun void randomize()
	{
		Std.rand2f(20, 1000) => freq_start;
		Std.rand2f(20, 1000) => freq_end;
		1::second => play_time;
		Std.rand2f(0.97, 1.0) => exponent;
		Std.rand2f(0.1, 1.0)::second => pitch_decay;
		Std.rand2f(0.5, 1) => volume;

		Std.rand2f(2, 10) => bf.Q;
		Std.rand2f(2, 10) => lf.Q;
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
	
	fun void play()
	{
		1.0 => float current_gain;
		setGain(volume * current_gain);
		setFrequency(freq_start);
		
		now => time start;
		now + play_time => time play_end;

		now + pitch_decay => time pitch_end;
		freq_end - freq_start => float freq_diff;

		1 => impulse.next;
		while (now < play_end)
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
}

// NoiseDrum drum;
// while (true)
// {
// 	drum.randomize();
// 	spork ~ drum.play();
// 	drum.play_time => now;
// }