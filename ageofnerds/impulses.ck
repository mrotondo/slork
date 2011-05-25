Impulse i => LPF lf => Gain g => dac;
Std.rand2f(1000, 2000) => lf.freq;
Std.rand2f(10, 20) => lf.Q;

2 => g.gain;

while (true)
{
	1 => i.next;
	(1/3.0)::second => now;
}