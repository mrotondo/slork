// Shred me first, bitches!

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
		64 => scene0.duration_in_beats;
        1.6 => scene0.drumRandomness;
        
        [ 1, 0, 0, 0,  0, 0, 1, 0,  1, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 1, 1, 0 ] @=> scene0.kickPattern;
        [ 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0 ] @=> scene0.snarePattern;
        [ 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0 ] @=> scene0.snareHardPattern;
        [ 0, 0, 0, 1,  0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 0, 0,   1, 0, 1, 0,  0, 0, 0, 0,  1, 0, 1, 0,  0, 0, 0, 0 ] @=> scene0.hihatPattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 1, 0,   0, 0, 0, 0,  0, 1, 0, 0,  0, 0, 0, 0,  0, 0, 1, 0 ] @=> scene0.openhatPattern;
        [ 1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0 ] @=> scene0.kickHardPattern;
        
        
		scene1 @=> scenes[1];
		0.5 => scene1.reverb_base;
		500 => scene1.hpf_freq_base;
		20 => scene1.modulation_base;
		64 => scene1.duration_in_beats;
        4.5 => scene1.drumRandomness;
        

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
        9.0 => scene2.drumRandomness;

        [ 1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  1, 0, 1, 0 ] @=> scene2.kickPattern;
        [ 0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1 ] @=> scene2.snarePattern;
        [ 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,   0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 0 ] @=> scene2.snareHardPattern;
        [ 1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,   1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 1, 0 ] @=> scene2.hihatPattern;
        [ 0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,   0, 0, 1, 0,  0, 0, 1, 0,  0, 0, 1, 0,  0, 1, 0, 1 ] @=> scene2.openhatPattern;
        [ 1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,   1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0 ] @=> scene2.kickHardPattern;

		145 => bpm;

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
			beat_duration => now;
		}
	}
}