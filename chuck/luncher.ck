if ( !me.args() ) 
{
    <<< "Usage: luncher.ck:0 for bass, luncher.ck:1 for chords" +"">>>;
    me.exit();
}

Std.atoi(me.arg(0)) => int which;

if ( which == 0 ) <<<"-------YOU ARE BASS, BRAH!-------">>>;
if ( which == 1 ) <<<"-------YOU ARE CHORDS, BRO!-------">>>;

Machine.add("scenes.ck");
me.yield();
if ( which == 0 )
{
    Machine.add("melody.ck");
    me.yield();
    Machine.add("Feedbork.ck");
    me.yield();
}

Machine.add("tweakybeat.ck");
me.yield();
Machine.add("noisedrums.ck");
me.yield();
Machine.add("drumzorz.ck");
me.yield();
Machine.add("drone.ck");
me.yield();
if ( which == 1 )
{
    Machine.add("e-spirit.ck");
    me.yield();
    Machine.add("strings.ck");
    me.yield();
}