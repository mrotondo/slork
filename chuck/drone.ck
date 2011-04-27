TriOsc t1 => JCRev revL => Gain gL => dac.chan(0);
Blit t2 => JCRev revR => Gain gR => dac.chan(1);

0.03 => gR.gain => gL.gain;

TriOsc t3 => revL;
Blit t4 => revR;

TriOsc t5 => revL;
Blit t6 => revR;

4 => t2.harmonics;
5 => t4.harmonics;
5 => t6.harmonics;

SinOsc m1 => blackhole;
0.005 => m1.freq;
SinOsc m2 => blackhole;
0.0045 => m2.freq;
SinOsc m3 => blackhole;
0.0065 => m3.freq;
SinOsc m4 => blackhole;
0.006 => m2.freq;
SinOsc m5 => blackhole;
0.0075 => m5.freq;
SinOsc m6 => blackhole;
0.007 => m6.freq;
43 => int base;
Std.mtof(base) => float cf1 => t1.freq;
Std.mtof(base) + .3 => float cf2 => t2.freq;

Std.mtof(base+7) => float cf3 => t3.freq;
Std.mtof(base+7) + .3 => float cf4 => t4.freq;

Std.mtof(base+12) => float cf5 => t5.freq;
Std.mtof(base+12) + .3 => float cf6 => t6.freq;

1.0 => float index;

0.5 => float g1;

while (true)
{
   cf1 + index*(m1.last()) => t1.freq;
   cf2 + index*(m2.last()) => t2.freq;
   cf3 + index*(m3.last()) => t3.freq;
   cf4 + index*(m4.last()) => t4.freq;
   cf5 + index*(m3.last()) => t5.freq;
   cf6 + index*(m4.last()) => t6.freq;
 
   //g1 + 0.3*(m4.last()) => t1.gain;
   //g1 + 0.3*(m3.last()) => t2.gain;
   //g1 + 0.3*(m2.last()) => t3.gain;
   //g1 + 0.3*(m1.last()) => t4.gain;
   g1 + 0.3*(m6.last()) => t5.gain;
   g1 + 0.3*(m5.last()) => t6.gain;
 
   1::samp => now; 
}