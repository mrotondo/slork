if ( !me.args() ) 
{
    <<< "Usage: luncher.ck:0 for bass, luncher.ck:1 for chords" +"">>>;
    me.exit();
}

<<<"argument is " + me.arg(0)>>>;

Std.atoi(me.arg(0)) => int which;

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