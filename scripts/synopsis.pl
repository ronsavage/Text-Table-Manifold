#!/usr/bin/env perl

use strict;
use warnings;

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new
(
	alignment =>
	[
		align_left,
		align_center,
		align_right,
		align_center,
		align_left,
	]
);

$table -> headers(['Homepage', 'Country', 'Name', 'Phone']);
$table -> data(
[
	['http://savage.net.au/', 'Australia', 'Ron Savage', undef],
	['https://jeffreykegler.github.io/Ocean-of-Awareness-blog/', 'America', 'Jeffrey kegler', ''],
]);

# Save the data, since render() may update it.

my(@data) = @{$table -> data};

$table -> empty(empty_as_minus);
$table -> format(format_internal_boxed);
$table -> undef(undef_as_text);
$table -> padding(1);

print "Format: format_internal_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> format(format_text_csv);
$table -> pass_thru({format_text_csv => {always_quote => 1} });

print "Format: format_text_csv: \n";
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
$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
$table -> escape(escape_html);
$table -> include(include_headers | include_data | include_footers);
$table -> pass_thru({format_internal_html => {table => {align => 'center', border => 1} } });

print "Format: as_internal_html: \n";
print join("\n", @{$table -> render(format => format_internal_html)}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> escape(escape_html);
$table -> pass_thru({format_html_table => {-style => 'color: blue'} });

print "Style: format_html_table: \n";
print join("\n", @{$table -> render(format => format_html_table)}), "\n";
print "\n";
