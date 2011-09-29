Blit b => LPF lf => dac;
SinOsc s => dac;
BlitSquare bs => LPF lf2 => dac;

40 => float freq;

freq => b.freq;
freq * 8 => lf.freq;
4 => lf.Q;

freq => s.freq;

freq / 2 => bs.freq;
freq * 8 => lf2.freq;
2 => lf2.Q;

while (true)
{
	day => now;
}