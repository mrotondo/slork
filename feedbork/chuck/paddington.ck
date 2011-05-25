BeeThree osc1 => ADSR env1 => NRev rev1 => dac;
TriOsc osc2 => ADSR env2 => NRev rev2 => dac;
0.6 => osc2.gain;
0.7 => rev2.mix;
PulseOsc osc3 => ADSR env3 => NRev rev3 => dac;
0.5 => osc3.gain;
0.8 => rev3.mix;

fun void setFreq(float freq)
{
    freq => osc1.freq;
    freq * 1.02 => osc2.freq;
    freq * 0.5 => osc3.freq;
}

fun void changeFreqs()
{
    while (true)
    {
        setFreq(Std.rand2f(400, 600));
        4::second => now;
    }
}
spork ~ changeFreqs();

while (true)
{
    Std.rand2f(0.9999, 1.0001) => float mult;
    4::second + now => time future;
    while (now < future)
    {
        1::ms => now;
        osc1.freq() * mult => osc1.freq;
        
    }
}