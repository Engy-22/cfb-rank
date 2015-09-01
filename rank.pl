#!/usr/bin/env perl

use strict;
use warnings;
use feature ":5.10";

use Text::CSV;

use constant e => 2.718281828459;

sub trim;
sub add_game;

my $input = "input.csv";

my $columns = {
	date => 0,
	visitor => 1,
	visitor_rushing_yards => 2,
	visitor_rushing_attempts => 3,
	visitor_passing_yards => 4,
	visitor_passing_attempts => 5,
	visitor_passing_completions => 6,
	visitor_penalties => 7,
	visitor_penalty_yards => 8,
	visitor_fumbles_lost => 9,
	visitor_picks_thrown => 10,
	visitor_first_down => 11,
	visitor_third_down_attempts => 12,
	visitor_third_down_conversions => 13,
	visitor_fourth_down_attempts => 14,
	visitor_fourth_down_conversions => 15,
	visitor_time_of_possesion => 16,
	visitor_score => 17,
	home => 18,
	home_rushing_yards => 19,
	home_rushing_attempts => 20,
	home_passing_yards => 21,
	home_passing_attempts => 22,
	home_passing_completions => 23,
	home_penalties => 24,
	home_penalty_yards => 25,
	home_fumbles_lost => 26,
	home_picks_thrown => 27,
	home_first_down => 28,
	home_third_down_attempts => 29,
	home_third_down_conversions => 30,
	home_fourth_down_attempts => 31,
	home_fourth_down_conversions => 32,
	home_time_of_possesion => 33,
	home_score => 34,
};

my $teams = {
#	"teamname" => [
#		{
#			opponent => "Bowling Green",
#			win => 1,
#			score => 1032,
#			x_factor => .610923
#		},
#	],
};

#my $game = {
#	team => "teamname",
#	opponent => "oppname",
#	win => 1,
#	score => 1238,
#	x_factor => .54092323904,
#};

open my $fh, "<", $input or die "$input: $!";
my $csv = Text::CSV->new({
	binary    => 1,
	auto_diag => 1,
});

#column names
$csv->getline($fh);

while (my $row = $csv->getline($fh)) {
	say trim $row->[$columns->{visitor}] . " at " . trim $row->[$columns->{home}];

        my $v_rushing_ypc = $row->[$columns->{visitor_rushing_yards}] / $row->[$columns->{visitor_rushing_attempts}];
        my $v_passing_ypa = $row->[$columns->{visitor_passing_yards}] / $row->[$columns->{visitor_passing_attempts}];
        #To avoid division by zero
        $v_rushing_ypc += .0000001;
        $v_passing_ypa += .0000001;
        my $v_total_yards = $row->[$columns->{visitor_rushing_yards}] + $row->[$columns->{visitor_passing_yards}] - $row->[$columns->{visitor_penalty_yards}];
        my $v_o_factor = (($v_rushing_ypc * e**e) + ($v_passing_ypa * e**2)) * atan2($v_total_yards, 1);
        say "\tO-Factor for visitor: " . $v_o_factor;

        my $h_rushing_ypc = $row->[$columns->{home_rushing_yards}] / $row->[$columns->{home_rushing_attempts}];
        my $h_passing_ypa = $row->[$columns->{home_passing_yards}] / $row->[$columns->{home_passing_attempts}];
        #To avoid division by zero
        $h_rushing_ypc += .0000001;
        $h_passing_ypa += .0000001;
        my $h_total_yards = $row->[$columns->{home_rushing_yards}] + $row->[$columns->{home_passing_yards}] - $row->[$columns->{home_penalty_yards}];
        my $h_o_factor = (($h_rushing_ypc * e**e) + ($h_passing_ypa * e**2)) * atan2($h_total_yards, 1);
        say "\tO-Factor for home: " . $h_o_factor;

        my $v_third_down_rate = $row->[$columns->{visitor_third_down_conversions}] / $row->[$columns->{visitor_third_down_attempts}];
        my $h_third_down_rate = $row->[$columns->{home_third_down_conversions}] / $row->[$columns->{home_third_down_attempts}];

        my $v_3_factor = (e**atan2(1 - $h_third_down_rate, 1)) - (1/e);
        my $h_3_factor = (e**atan2(1 - $v_third_down_rate, 1)) - (1/e);

        my $v_d_factor = ((e + 1) * ((1 / $h_rushing_ypc) + 1) + (e ** 2) * ((1 / $h_passing_ypa) + (e / 3))) * $v_3_factor * e**e;
        my $h_d_factor = ((e + 1) * ((1 / $v_rushing_ypc) + 1) + (e ** 2) * ((1 / $v_passing_ypa) + (e / 3))) * $h_3_factor * e**e;

        say "\tD-Factor for visitor: " . $v_d_factor;
        say "\tD-Factor for home: " . $h_d_factor;

        #Calculate the x factor (reward teams for being balanced between o and d)

        my $h_x_factor = ((1 / e) * e**(-((1 / 100) * (abs($h_o_factor - $h_d_factor)))**2) + 1) / 2;
        my $v_x_factor = ((1 / e) * e**(-((1 / 100) * (abs($v_o_factor - $v_d_factor)))**2) + 1) / 2;

        say "\tX-Factor for visitor: " . $v_x_factor;
        say "\tX-Factor for home: " . $h_x_factor;

        #Calculate the win factor

        my $h_margin = $row->[$columns->{home_score}] - $row->[$columns->{visitor_score}];
        my $v_margin = -1 * $h_margin;

        my $h_win_factor = (e ** atan2($h_margin / e**e, 1) + 1);
        my $v_win_factor = (e ** atan2($v_margin / e**e, 1) + 1);

        say "\tWin Factor for visitor: " . $v_win_factor;
        say "\tWin Factor for home: " . $h_win_factor;

        my $h_game_score = ($h_o_factor + $h_d_factor) * $h_x_factor * $h_win_factor;
        my $v_game_score = ($v_o_factor + $v_d_factor) * $v_x_factor * $v_win_factor;

        say "\tGame Score for visitor: " . $v_game_score;
        say "\tGame Score for home: " . $h_game_score;

	my $v_game = {
		team => trim $row->[$columns->{visitor}],
		opponent => trim $row->[$columns->{home}],
		win => $v_margin > 0,
		score => $v_game_score,
		x_factor => $v_x_factor,
	};

	my $h_game = {
		team => trim $row->[$columns->{home}],
		opponent => trim $row->[$columns->{visitor}],
		win => $v_margin < 0,
		score => $h_game_score,
		x_factor => $h_x_factor,
	};

	$teams = add_game $teams, $v_game;
	#TODO
}

close $fh;

#say $teams->{"teamname"}->[0]->{score};

sub trim {
	my $string = $_[0];
	$string =~ s/^\s+|\s+$//g;
	return $string;
}

#$teams is the data structure for all of the games
#$game is the structure for an individual team's game

sub add_game {
	my ($teams, $game) = @_;
	$teams->{$game->{team}} = [] unless ($teams->{$game->{team}});
	push $teams->{$game->{team}}, {
		opponent => $game->{opponent},
		win => $game->{win},
		score => $game->{score},
		x_factor => $game->{x_factor},
	};

	return $teams;

}
