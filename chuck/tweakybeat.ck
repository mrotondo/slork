// TODO: For some reason when this gets plugged into drumzorz, there is a droning note that sounds forever.

public class TweakyDrum
{
	Mix2 mix => Gain g => dac.chan(0) => dac.chan(1);
	-1 => mix.pan;
    0.25 => g.gain;

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
    0.0 => mix.gain;

	fun void randomize()
	{
		Std.rand2f(20, 1000) => freq_start;
		Std.rand2f(20, 1000) => freq_end;
		1::second => play_time;
		Std.rand2f(0.95, 0.99) => exponent;
		Std.rand2f(0.1, 1.0)::second => pitch_decay;
		Std.rand2f(0.5, 1) => volume;
		Std.randf() => waveform;
	}

	fun void print()
	{
		<<< "Freq start: " + freq_start >>>;
		<<< "Freq end: " + freq_end >>>;
		<<< "Exponent: " + exponent >>>;
		<<< "Pitch decay:" >>>;
		<<< pitch_decay >>>;
		<<< "Volume: " + volume >>>;
		<<< "Waveform: " + waveform >>>;
		<<< "---------" >>>;
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

	0.0 => float current_gain;
	now => time pitch_end;
	now => time start;
	0.0 => float freq_diff;
	setFrequency(0.0);
	setGain(0.0);
	
	fun void go()
	{
		waveform => mix.pan;
		
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

// TweakyDrum drum;
// drum.randomize();
// spork ~ drum.go();
// while (true)
// {
// 	drum.play();
// 	50::ms => now;
// }
