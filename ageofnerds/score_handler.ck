1 => int port;
class RemoteVoice
{
	MidiOut midiport;
	midiport.open(port++);
	
	0 => int playing;
	0 => int midi_note;

	fun void startPlaying(MidiMsg m)
	{
		midiport.send(m);
		m.data2 => midi_note;
		1 => playing;
	}

	fun void stopPlaying(MidiMsg m)
	{
		midiport.send(m);
		0 => playing;
	}
}


MidiIn min;
MidiMsg msg;

// open midi receiver, exit on fail
if ( !min.open(0) ) me.exit(); 

RemoteVoice voices[Luncher.numVoices];

while( true )
{
    min => now;

    while( min.recv( msg ) )
    {
		0 => int voiceFound;
		0 => int voiceIndex;
		if (msg.data1 == 144) // note on!
		{
			while (!voiceFound && voiceIndex < Luncher.numVoices)
			{
				voices[voiceIndex] @=> RemoteVoice @ voice;
				if (!voice.playing)
				{
					voice.startPlaying(msg);
					1 => voiceFound;
				}				
				voiceIndex++;
			}
		}
		else if (msg.data1 == 128) // note off
		{
			while (!voiceFound && voiceIndex < Luncher.numVoices)
			{
				voices[voiceIndex] @=> RemoteVoice @ voice;
				if (voice.playing && voice.midi_note == msg.data2)
				{
					voice.stopPlaying(msg);
					1 => voiceFound;
				}
				voiceIndex++;
			}			
		}
    }
}
