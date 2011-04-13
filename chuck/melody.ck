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
    72 => int root;
    root => int pitch;
    0 => int prev_pitch;
    
    0::ms => dur note_duration;
    
    [0, 2, 4, 5, 7, 10, 12] @=> int intervals[];
    
    // start on the root
    [1.0, 0.0, 0.0, 0.0, 0.0, 0.0] @=> float weights[];
    
    // HACK: the subdivisions also act as probability weights for how they are selected.
    [0.5, 1.0] @=> float duration_subdivisions[];
    
    SinOsc osc => dac;
    0.0 => osc.gain;
    
    fun void Play()
    {
        while (true)
        {
            PlayNextNote();
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

    fun void PlayNextNote()
    {
        ComputeNextPitch();
        ComputeNextDuration();

        SetFrequency(Std.mtof(pitch));
        note_duration => now;
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
        
        <<< "Voice pitch", pitch >>>;
    }
}

public class MelodyVoice extends Voice
{
    
    NRev reverb;
    
    ModalBar ugen1 => reverb => BPF bf => dac;
    1 => ugen1.preset;
    1200 => bf.freq;
    7 => bf.Q;
    
    NRev reverb2;    
    Wurley ugen2 => reverb2 => dac;
    0.1 => reverb2.mix;

    NRev reverb3;    
    Wurley ugen3 => reverb3 => dac;
    0.2 => reverb3.mix;
    
    PulseOsc ugen4 => BPF lf => ADSR env4 => NRev reverb4 => dac;
    0.1 => reverb4.mix;
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
        
        SetGain(1.0);
    }
    
    fun void SetGain(float gain)
    {
        gain => ugen1.strike;
        gain / 2 => ugen2.noteOn;
        gain / 7 => ugen3.noteOn;
        gain / 3 => env4.value;
        env4.keyOff();
    }
}

while (true)
{
    1::second => now;
}