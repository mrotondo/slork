fun float SumFloats(float floats[])
{
    0 => float sum;
    for (0 => int i; i < floats.cap(); i++)
    {
        sum + floats[i] => sum;
    }
    return sum;
}

class Voice
{
    45 => int root;
    root => int pitch;
    0 => int prev_pitch;

	0 => int playNext;
	
    0::ms => dur note_duration;
    
    [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24] @=> int intervals[];
    
    // start on the root
    [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] @=> float weights[];
    
    // HACK: the subdivisions also act as probability weights for how they are selected.
    [0.5, 1.0] @=> float duration_subdivisions[];
    
    SinOsc osc => dac;
    0.0 => osc.gain;

	fun void SetKey(int major_minor)
	{
		if (major_minor == 0)
		{
			[0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24] @=> intervals;
		}
		else
		{
			[0, 2, 3, 5, 7, 9, 10, 12, 14, 15, 17, 19, 21, 22, 24] @=> intervals;
		}
	}
    
    fun void updateParams()
    {
        while (true)
        {
			day => now;
        }
    }
    
    fun void SetFrequency(float freq)
    {
        SetGain(1.0);
        freq => osc.freq;
    }
    
    fun void SetGain(float gain)
    {
        gain => osc.gain;
    }

	fun void ChooseNextNote(int manual_note_choice, float pitch_param)
	{
        if (!manual_note_choice) {
			ComputeNextPitch();
		} else {
			1.0 / (intervals.cap()) => float interval_prob;
			(pitch_param / interval_prob) $ int => int i;
			root + intervals[i] => pitch;
		}
        ComputeNextDuration();

		1 => playNext;
	}
	
    fun void PlayNextNote()
    {
		if (playNext == 1) {
			SetFrequency(Std.mtof(pitch));
			SetGain(1.0);
			0 => playNext;
		}
    }
    
    fun void ComputeNextDuration()
    {
        SumFloats(duration_subdivisions) => float weights_sum;
        Std.rand2f(0, weights_sum) => float rand_val;
        
        int duration_subdivisions_index;
        0 => float accum;
        for (0 => int i; i < duration_subdivisions.cap(); i++)
        {
            accum + duration_subdivisions[i] => accum;
            if (accum > rand_val)
            {
                i => duration_subdivisions_index;
                break;
            }
        }
        (60.0 / 145)::second => dur max_duration;
        duration_subdivisions[duration_subdivisions_index] * max_duration => note_duration;
    }
    
    fun void ComputeNextPitch()
    {
        pitch => prev_pitch;
        
        SumFloats(weights) => float weights_sum;
        Std.rand2f(0, weights_sum) => float rand_val;
        
        int next_interval_index;
        0 => float accum;
        for (0 => int i; i < weights.cap(); i++)
        {
            accum + weights[i] => accum;
            0 => weights[i]; // clear weights, will be reset afterwards
            if (accum > rand_val)
            {
                i => next_interval_index;
                break;
            }
        }
        
        root + intervals[next_interval_index] => int next_pitch;
        
        if (next_pitch - pitch > 4)
        {
            1.0 => weights[next_interval_index - 1];
        }
        else if (next_pitch - pitch < -4)
        {
            1.0 => weights[next_interval_index + 1];
        }
        else
        {
            // Assign new weights
            for (0 => int i; i < weights.cap(); i++)
            {
                
                Std.abs(i - next_interval_index) => int dist;
                Math.pow(2, -dist) => weights[i];
                
                // never choose the same pitch
                if (i == next_interval_index)
                {
                    0 => weights[i];
                }
            }
        }

        next_pitch => pitch;
    }
}

public class MelodyVoice extends Voice
{
    HPF hpf => dac;
    10 => hpf.freq;
	0 => float hpf_freq_base;
	0 => float hpf_freq_target;
    
    ModalBar ugen1 => NRev reverb1 => BPF bf => hpf;
    0.0 => reverb1.mix;
	0.0 => float reverb1_mix_target;
	0.0 => float reverb1_mix_base;
    1 => ugen1.preset;
    1200 => bf.freq;
    7 => bf.Q;
    
    Wurley ugen2 => NRev reverb2 => hpf;
    0.0 => reverb2.mix;
	0.0 => float reverb2_mix_target;
	0.0 => float reverb2_mix_base;

    Wurley ugen3 => NRev reverb3 => hpf;
    0.0 => reverb3.mix;
	0.0 => float reverb3_mix_target;
	0.0 => float reverb3_mix_base;
    
    PulseOsc ugen4 => BPF lf => ADSR env4 => NRev reverb4 => hpf;
    0.0 => reverb4.mix;
	0.0 => float reverb4_mix_target;
	0.0 => float reverb4_mix_base;
    200::ms => env4.duration;
    1 => lf.Q;
    
    SetGain(0.0);
    
    fun void SetFrequency(float freq)
    {
        freq => ugen1.freq;
        freq * 0.8 => bf.freq;
        
        freq / 2 => ugen2.freq;
        freq / 2 + 5 => ugen3.freq;
        
        freq / 4 => ugen4.freq;
        freq / 4 => lf.freq;
    }
    
    fun void SetGain(float gain)
    {
        gain => ugen1.strike;
        gain / 2 => ugen2.noteOn;
        gain / 7 => ugen3.noteOn;
        gain / 3 => env4.value;
        env4.keyOff();
    }
    
    fun void SetHPFFreq(float freq)
    {
		freq => hpf_freq_target;
    }

	fun void SetReverbMix(float mix)
	{
		mix => reverb1_mix_target;
		mix / 3 => reverb2_mix_target;
		mix / 2 => reverb3_mix_target;
		mix / 3 => reverb4_mix_target;
	}

	fun void updateParams()
	{
		while(true)
		{
			hpf.freq() + ((hpf_freq_target + Scenes.current_scene.hpf_freq_base) - hpf.freq()) * 0.01 => hpf.freq;

			reverb1.mix() + ((reverb1_mix_target + Scenes.current_scene.reverb_base) - reverb1.mix()) * 0.01 => reverb1.mix;
			reverb2.mix() + ((reverb2_mix_target + Scenes.current_scene.reverb_base) - reverb2.mix()) * 0.01 => reverb2.mix;
			reverb3.mix() + ((reverb3_mix_target + Scenes.current_scene.reverb_base) - reverb3.mix()) * 0.01 => reverb3.mix;
			reverb4.mix() + ((reverb4_mix_target + Scenes.current_scene.reverb_base) - reverb4.mix()) * 0.01 => reverb4.mix;
			
			second => now;
		}
	}
}
