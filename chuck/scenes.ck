// Shred me first, bitches!
144.0 => float tempo;
(44100*60.0/tempo)::samp => dur TimeUnit;
TimeUnit * 0.5 => dur Half;
Half * 0.5 => dur Quarter;
Quarter * 0.5 => dur Eighth;
Eighth * 0.5 => dur Sixteenth;
16.0 => float quantizationSize;

HevyMetl s => JCRev rev => Gain gain => dac;

Noise n => BPF bpf => Gain noiseGain => rev;

8.0 => bpf.Q;
0.8 => noiseGain.gain;


//0.4 => s.lfoDepth;


//0.0 => s.noiseGain;
1.0 => s.noteOff;
0.0 => gain.gain;

s => Delay dly => rev;
dly => Gain fb => dly;
rev.mix(0.1);
rev.gain(0.35);
dly.gain(0.9);
TimeUnit => dly.max;
Half => dly.delay;
0.9999 => fb.gain;

0 => int thenote;
0.0 => float vel;
440.0 => float fTarget;

fun void slewFreq()
{
    now + 20::second => time later;
    while (now < later)
    {
        0.000002*(fTarget-s.freq()) + s.freq() => s.freq;
        s.freq() => bpf.freq;
        //fTarget => s.freq;
        1::samp => now;
    }
    <<< "unspork" >>>;
}

fun void makecoolsound()
{
    spork ~ slewFreq();
    
    // infinite event loop
    
    10 => fTarget;
    0.25 => s.noteOn;
    4000 => fTarget;
    0.0 => gain.gain;
    while ( gain.gain() < 0.1 )
    {
        gain.gain() + 0.0002 => gain.gain;
        4::samp => now;
    }
    4::second => now;
    while ( gain.gain() > 0 )
    {
        gain.gain() - 0.000002 => gain.gain;
        noiseGain.gain() - 0.000007 => noiseGain.gain;
        4::samp => now;
    }
}
public class Scenes
{
	class Scene
	{
		// Drum params
		// Nick fill in here
		
		// Melody params
		float reverb_base;
		float hpf_freq_base;
		float modulation_base;
        
        int kickPattern[];
        int snarePattern[];
        int snareHardPattern[];
        int hihatPattern[];
        int openhatPattern[];
        int kickHardPattern[];
        0.0 => float drumRandomness;
        2.0 => float drumDensity;
		
		// chord params
		0.0 => float chordFBgain;
		0.0 => float chordFB;
        
        // strings params
        0.0 => float stringsFBgain;
		0.0 => float stringsFB;
        
        int duration_in_beats;
	}

	static float bpm;

	static int current_scene_index;
	static Scene @ current_scene;
		
	fun static void startPiece()
	{   
		// CHANGE NUM SCENES HERE
		3 => int num_scenes;
		
		Scene @ scenes[num_scenes];

		Scene scene0;
		Scene scene1;
		Scene scene2;

		<<< "OMG INITING" >>>;

		scene0 @=> scenes[0];
		0 => scene0.reverb_base;
		10 => scene0.hpf_freq_base;
		0 => scene0.modulation_base;
		16 => scene0.duration_in_beats;
        5.6 => scene0.drumRandomness;
        2.6 => scene0.drumDensity;
		0.0 => scene0.chordFBgain;
        0.0 => scene0.chordFB;
        0.4 => scene0.stringsFBgain;
        0.3 => scene0.stringsFB;

        
        //[ 1, 0, 1, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 1 ] @=> scene0.kickPattern;
        //[ 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0 ] @=> scene0.snarePattern;
        //[ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.snareHardPattern;
        //[ 1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 1, 0,  1, 0, 0, 0,   1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 1, 0,  1, 0, 0, 0 ] @=> scene0.hihatPattern;
        //[ 0, 0, 1, 0,  0, 0, 1, 0,  0, 1, 0, 0,  0, 0, 1, 0,   0, 0, 0, 1,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 1, 0 ] @=> scene0.openhatPattern;
        //[ 1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.kickHardPattern;
        
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.kickPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.snarePattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.snareHardPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.hihatPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.openhatPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.kickHardPattern;
        
		scene1 @=> scenes[1];
		0.5 => scene1.reverb_base;
		500 => scene1.hpf_freq_base;
		20 => scene1.modulation_base;
		64 => scene1.duration_in_beats;
        50.5 => scene1.drumRandomness;
        5.6 => scene1.drumDensity;
		0.99 => scene1.chordFBgain;
        0.6 => scene1.chordFB;
        0.999 => scene1.stringsFBgain;
        0.7 => scene1.stringsFB;

        

        [ 1, 0, 0, 0,  0, 0, 0, 1,  0, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 1,  0, 0, 1, 0,  1, 0, 0, 0,  1, 0, 1, 0 ] @=> scene1.kickPattern;
        [ 0, 0, 0, 0,  1, 0, 0, 0,  0, 1, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0 ] @=> scene1.snarePattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0 ] @=> scene1.snareHardPattern;
        [ 0, 0, 1, 0,  1, 0, 0, 0,  1, 0, 1, 0,  1, 0, 0, 0,   1, 1, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0,  1, 0, 0, 0 ] @=> scene1.hihatPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 1, 0 ] @=> scene1.openhatPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 1,  0, 0, 0, 0,  0, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 1,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene1.kickHardPattern;


		scene2 @=> scenes[2];
		1 => scene2.reverb_base;
		1000 => scene2.hpf_freq_base;
		50 => scene2.modulation_base;
		64 => scene2.duration_in_beats;
        90.0 => scene2.drumRandomness;
		10.6 => scene2.drumDensity;
		0.9999 => scene2.chordFBgain;
        0.9 => scene2.chordFB;
        0.999 => scene2.stringsFBgain;
        0.94 => scene2.stringsFB;


        [ 1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  1, 0, 1, 0 ] @=> scene2.kickPattern;
        [ 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1 ] @=> scene2.snarePattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 0 ] @=> scene2.snareHardPattern;
        [ 1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,   1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 1, 0 ] @=> scene2.hihatPattern;
        [ 0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,   0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 1, 0, 1 ] @=> scene2.openhatPattern;
        [ 1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0 ] @=> scene2.kickHardPattern;

		144 => bpm;

		0 => current_scene_index;
		scenes[current_scene_index] @=> current_scene;

		1::minute / bpm => dur beat_duration;

		0 => int beat_count;
		current_scene.duration_in_beats => int next_scene_count;
        while (true)
		{
        	while (beat_count > next_scene_count && current_scene_index < num_scenes - 1)
			{
				current_scene_index++;
				scenes[current_scene_index] @=> current_scene;
				next_scene_count + current_scene.duration_in_beats => next_scene_count;

				<<< "Reverb base is now " + current_scene.reverb_base >>>;
			}
			beat_count++;
            
            if (current_scene_index == 0 && 
            beat_count == current_scene.duration_in_beats - 4) {
                <<< "GO!" >>>;
                spork ~ makecoolsound();
            }
            
			beat_duration => now;
		}
	}
}

spork ~ Scenes.startPiece();
me.yield();
while(true)
{
    second => now;
}
