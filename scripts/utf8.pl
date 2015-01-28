#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new;

$table -> headers(['One', 'Two', 'Three']);
$table -> data(
[
	['Reichwaldstraße', 'Böhme', 'ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ'],
	['Πηληϊάδεω Ἀχιλῆος', 'ΔΔΔΔΔΔΔΔΔΔ', 'A snowman: ☃'],
	['Two ticks: ✔✔', undef, ''],
]);

$table -> handle_empty(empty_as_minus);
$table -> handle_undef(undef_as_text);
$table -> padding(2);
$table -> style(as_boxed);

print "Style: as_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

$table -> style(as_github);

print "Style: as_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";