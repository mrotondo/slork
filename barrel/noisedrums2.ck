public class NoiseDrum
{
    80 => float min_frequency;
    250 => float max_frequency;
    
    0 => int isKick;
    
    200::ms => dur min_time_between_plays;
    now => time last_played;
    
    //Noise n => Gain g => ADSR e1=> dac;
    NRev r => dac;
    0.009 => r.mix;
    Noise n1 => BPF bpf1 => Gain g1 => ADSR e1=> r;
    Noise n2 => BPF bpf2 => Gain g2 => ADSR e2=> r;
    SinOsc bassSin => e1;
    
    400 => bassSin.freq;
    0.1 => bassSin.gain;
    
    0.4 => g1.gain;
    800 => bpf1.freq;
    8 => bpf1.Q;
    1::ms => e1.attackTime;
    50::ms => e1.decayTime;
    0.01 => e1.sustainLevel;
    100::ms => e1.releaseTime;

    0.4 => g2.gain;
    800 => bpf2.freq;
    4 => bpf2.Q;
    3::ms => e2.attackTime;
    150::ms => e2.decayTime;
    0.04 => e2.sustainLevel;
    200::ms => e2.releaseTime;
    
    1 => e1.keyOff;
    1 => e2.keyOff;
    
    SndBuf snare => Gain gsnare => r;
    SndBuf kick  => Gain gkick => r;
    
    0.5 => snare.gain => kick.gain;
    
    snare.read("snare.aiff");
    kick.read("kick.wav");
    snare.samples() - 1 => snare.pos;
    kick.samples() - 1 => kick.pos;
    
    TriOsc o => LPF lpf => Gain g3 => ADSR e3 => r;
    0.1 => g3.gain;
    200 => lpf.freq;
    100::ms => e3.attackTime;
    100::ms => e3.decayTime;
    0.05 => e3.sustainLevel;
    300::ms => e3.releaseTime;
    
    1 => e3.keyOff;
    
    fun void play(float amplitude)
    {
        if (now - last_played > min_time_between_plays)
        {  
            <<<"trigger: " + amplitude>>>;
            
            amplitude * 9.0 => float temp;
            if ( temp > 1.0 ) 1.0 => temp;
            
            0.7 * temp => snare.gain => kick.gain;
            0.5 * temp => g1.gain => g2.gain;
            0.2 * temp => bassSin.gain;
            
            now => last_played;
            0 => snare.pos;
            0 => kick.pos;
            // amplitude => e1.target
            1 => e1.keyOn;
            1 => e2.keyOn;
            1 => e3.keyOn;
            300::ms => now; // 500 before
            // TODO: Check that it hasn't been less than 500 ms since the last hit
            1 => e1.keyOff;
            1 => e2.keyOff;
            1 => e3.keyOff;
        }
    }
    
    fun void setFrequency(float frequency_percent) // [0, 1]
    {
        min_frequency + frequency_percent * (max_frequency - min_frequency) => float frequency;
        frequency * 8 => bpf1.freq;
        frequency * 4 => bpf2.freq;
        
        if ( isKick )
        {
            
            60 + (frequency_percent-0.5)*10 => bassSin.freq;
            //0.0 => bassSin.gain;
            1.0 => gkick.gain;
            0.0 => gsnare.gain;
            (frequency_percent)/1.5 + 1.0 => kick.rate => snare.rate;
        }
        else
        {
            400 + (frequency_percent-0.5)*80 => bassSin.freq;
            1.0 - frequency_percent/6.0 => gsnare.gain;
            frequency_percent/6.0 => gkick.gain;
            (frequency_percent) + 0.5 => kick.rate => snare.rate;
        }
        
        
<<<<<<< HEAD
        (frequency_percent) + 0.5 => kick.rate => snare.rate;
        
        frequency * 2 => o.freq;
=======
>>>>>>> 38d21160b6f58e4765374ad1e78f28858f9e0dae
    }
    
    // TODO: differentiate left movement from right movement
    fun void setModulation(float modulation_amount) // [-1, 1]
    {   
        //Math.fabs(modulation_amount) * 10 => b.vibratoFreq;
        //Math.fabs(modulation_amount) => b.vibratoGain;
    }    
}