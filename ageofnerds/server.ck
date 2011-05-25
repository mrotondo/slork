OscSend xmit;
xmit.setHost("localhost", 9999);

120.0 => float bpm;
1::minute / bpm => dur beat;


while (true)
{
	xmit.startMsg("/beat, f");
    xmit.addFloat(bpm);
	beat => now;
}