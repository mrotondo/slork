SinOsc s => blackhole;

Impulse i => dac;

while (true)
{
	Math.tanh(s.last() * 10) => i.next;
	1::samp => now;
}