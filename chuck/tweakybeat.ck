// TODO: For some reason when this gets plugged into drumzorz, there is a droning note that sounds forever.

public class TweakyDrum
{
	Mix2 mix => dac.chan(0) => dac.chan(1);
	-1 => mix.pan;

	SinOsc sin => mix.left;
	
	Blit impulse => LPF f => mix.right;
	1 => impulse.gain;
	10 => impulse.harmonics;


	// DRUM SPEC
	160 => float freq_start;
	140 => float freq_end;
	1::second => dur play_time;
	0.99 => float exponent;
	0.15::second => dur pitch_decay;
	0.8 => float volume;
	0.0 => float waveform;

	fun void randomize()
	{
		Std.rand2f(20, 1000) => freq_start;
		Std.rand2f(20, 1000) => freq_end;
		1::second => play_time;
		Std.rand2f(0.95, 1.0) => exponent;
		Std.rand2f(0.1, 1.0)::second => pitch_decay;
		Std.rand2f(0.5, 1) => volume;
		Std.randf() => waveform;
	}
	
	fun void setFrequency(float freq)
	{
		freq => sin.freq;
		freq => impulse.freq;
		freq * 20 => f.freq;
	}

	fun void setGain(float gain)
	{
		gain => mix.gain;
	}
	
	fun void play()
	{
		waveform => mix.pan;
		1.0 => float current_gain;
		setGain(volume * current_gain);
		setFrequency(freq_start);
		
		now => time start;
		now + play_time => time play_end;

		now + pitch_decay => time pitch_end;
		freq_end - freq_start => float freq_diff;
		
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

// TweakyDrum drum;
// while (true)
// {
// 	drum.randomize();
// 	spork ~ drum.play();
// 	drum.play_time => now;
// }