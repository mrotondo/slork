40 => float f;

Gain g1 => LPF lf => dac;

SawOsc s1 => g1;
SawOsc s2 => g1;
SawOsc s3 => g1;

f * 0.99 => s1.freq;
f => s2.freq;
f * 1.01 => s3.freq;

8 => float env_freq;
SawOsc env => blackhole;
env_freq => env.freq;
40 => float env_add;
4960 => float env_mul;

while (true)
{
	1::samp => now;
	(env.last() * 0.5 + 0.5) * env_mul + env_add => lf.freq;
}