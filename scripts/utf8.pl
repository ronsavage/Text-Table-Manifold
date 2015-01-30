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
	['Two ticks: ✔✔', undef, '<table><tr><td>TBA</td></tr></table>'],
]);

# Save the data, since render() may update it.

my(@data) = @{$table -> data};

$table -> empty(empty_as_minus);
$table -> format(format_internal_boxed);
$table -> undef(undef_as_text);
$table -> padding(2);

print "Format: format_internal_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> format(format_internal_github);

print "Format: format_internal_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> footers(['One', 'Two', 'Three', 'Four']);
$table -> include(include_headers | include_data | include_footers);
$table -> pass_thru({format_internal_html => {table => {align => 'center', border => 1} } });

print "Format: format_internal_html: \n";
print join("\n", @{$table -> render(format => format_internal_html)}), "\n";
print "\n";

