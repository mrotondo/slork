public class NoiseDrum
{
    10 => float min_frequency;
    250 => float max_frequency;
    
    200::ms => dur min_time_between_plays;
    now => time last_played;
    
    //Noise n => Gain g => ADSR e1=> dac;
    NRev r => dac;
    0.05 => r.mix;
    Noise n1 => BPF bpf1 => Gain g1 => ADSR e1=> r;
    Noise n2 => BPF bpf2 => Gain g2 => ADSR e2=> r;
    0.8 => g1.gain;
    800 => bpf1.freq;
    8 => bpf1.Q;
    1::ms => e1.attackTime;
    50::ms => e1.decayTime;
    0.01 => e1.sustainLevel;
    100::ms => e1.releaseTime;

    0.8 => g1.gain;
    800 => bpf1.freq;
    4 => bpf1.Q;
    0::ms => e1.attackTime;
    150::ms => e1.decayTime;
    0.05 => e1.sustainLevel;
    200::ms => e1.releaseTime;
    
    1 => e1.keyOff;
    1 => e2.keyOff;

    
    fun void play(float amplitude)
    {
        if (now - last_played > min_time_between_plays)
        {  
            <<<"trigger">>>;
            now => last_played;
            // amplitude => e1.target
            1 => e1.keyOn;
            1 => e2.keyOn;
            500::ms => now;
            // TODO: Check that it hasn't been less than 500 ms since the last hit
            1 => e1.keyOff;
            1 => e2.keyOff;
        }
    }
    
    fun void setFrequency(float frequency_percent) // [0, 1]
    {
        min_frequency + frequency_percent * (max_frequency - min_frequency) => float frequency;
        frequency * 8 => bpf1.freq;
        frequency * 4 => bpf2.freq;
    }
    
    // TODO: differentiate left movement from right movement
    fun void setModulation(float modulation_amount) // [-1, 1]
    {   
        //Math.fabs(modulation_amount) * 10 => b.vibratoFreq;
        //Math.fabs(modulation_amount) => b.vibratoGain;
    }    
}