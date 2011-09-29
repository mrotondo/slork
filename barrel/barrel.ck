
0 => int drumsound;
if( me.args() ) me.arg(0) => drumsound;

<<< "drum: ", drumsound >>>;

public class Barrel
{
    10 => float min_frequency;
    250 => float max_frequency;
    
    200::ms => dur min_time_between_plays;
    now => time last_played;
    
    Noise n => BPF bpf => Gain g => ADSR e1 => NRev r => dac;
    0.01 => r.mix;
    0.2 => g.gain;
    800 => bpf.freq;
    20 => bpf.Q;
    
    ModalBar b => dac;
    1 => b.preset;

    0.1 => b.stickHardness;

    1::ms => e1.attackTime;
    50::ms => e1.decayTime;
    0.01 => e1.sustainLevel;
    100::ms => e1.releaseTime;
    
    1 => e1.keyOff;
    
    fun void play(float amplitude)
    {
        if (now - last_played > min_time_between_plays)
        {  
            <<<"trigger">>>;
            now => last_played;
            //1 => e1.target;
            b.strike(1.0);
            5000::ms => now;
            //1 => e1.keyOff;
            //b.damp(1.0);
        }
    }
    
    fun void setFrequency(float frequency_percent) // [0, 1]
    {
        min_frequency + frequency_percent * (max_frequency - min_frequency) => float frequency;
        frequency => b.freq;
        frequency * 4 => bpf.freq;
    }
    
    // TODO: differentiate left movement from right movement
    fun void setModulation(float modulation_amount) // [-1, 1]
    {   
        Math.fabs(modulation_amount) * 10 => b.vibratoFreq;
        Math.fabs(modulation_amount) => b.vibratoGain;
    }    
}