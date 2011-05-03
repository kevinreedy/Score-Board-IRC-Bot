#!/usr/bin/perl

use warnings;
use strict;

use JSON;

package ScoreBoardBot;
use base qw( Bot::BasicBot );

# Hash to keep the current score board in
our %points;

# Load points from JSON file
sub load_points {
    # open json file and store contents in $content
    open(FILE, "points.json") or die $!;
    my $content = <FILE>;
    close(FILE);

    my $json = new JSON;
    # TODO if content is not a valid json, we should skip loading it
    my $points_ref = $json->decode($content);
    # JSON->decode returns a hash ref, so we need to deref
    %points = %$points_ref;

}

# Save points to JSON file
sub save_points {
    # JSONify
    my $json = new JSON;
    # JSON->encode takes a hash ref
    my $json_out = $json->encode(\%points);

    # Write JSON to disk
    open(FILE, ">", "points.json") or die $!;
    print FILE $json_out;
    close(FILE);
}

# Add/subtract points from a nick
sub add_points {
    my ($self, $nick, $new_points) = @_;

    $points{$nick} += $new_points;

    # Save to disk incase of crash or exit
    $self->save_points();

    # Return the user's new total points
    return $points{$nick};    
}

# Extend Bot::BasicBot->send
# This gets called every time someone said something in chat
sub said {
    my ($self, $message) = @_;

    # Look for "!score" in chat
    if ($message->{body} =~ /^\!score/) {
        # TODO return the current scoreboard
    }
    
    # $1 = nick; $2 = ++,--,+=,-=; $3 = points
    elsif ($message->{body} =~ /(\w+)\s*([\+-][\+-=])\s*((\d+)|())/) {
        # Set points to 0 if it doesn't exist
        $points{1} = 0 if(!$points{$1});

        # http://www.youtube.com/watch?v=SiMHTK15Pik
        if($3 && ($3 > 9000 || $3 < -9000)) {
            return "OVER 9000?!?!?!?";
        } 

        # Find out who has lost or gained points
        return "$1 has lost a point for a total of " . $self->add_points($1, -1) if ($2 eq "--");
        return "$1 gets a point for a total of " . $self->add_points($1, 1) if ($2 eq "++");
        return "$1 has lost $3 points for a total of " . $self->add_points($1, ($3 * -1)) if ($2 eq "-=");
        return "$1 gets $3 points for a total of " . $self->add_points($1, $3) if ($2 eq "+=");
    }
}

# TODO have these parameters taken from the command line
my $bot = ScoreBoardBot->new(
    server   => "irc.dsf.cc",
    port     => "6667",
    channels => ["#coolbros"],
    nick     => "ScoreBoard",
    username => "ScoreBoard",
    name     => "I keep track of your points",
    charset  => "utf-8", # charset the bot assumes the channel is using
);

# Load points from file
$bot->load_points();

# Enter main loop
$bot->run();
