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
$table -> undef(undef_as_text);
$table -> padding(1);
$table -> style(render_internal_boxed);

print "Style: render_internal_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> pass_thru({render_text_csv => {always_quote => 1} });
$table -> style(render_text_csv);

print "Style: render_text_csv: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> style(render_internal_github);

print "Style: render_internal_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
$table -> escape(escape_html);
$table -> include(include_headers | include_data | include_footers);
$table -> pass_thru({render_internal_html => {table => {align => 'center', border => 1} } });

print "Style: as_internal_html: \n";
print join("\n", @{$table -> render(style => render_internal_html)}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> escape(escape_html);
$table -> pass_thru({render_html_table => {-style => 'color: blue'} });

print "Style: render_html_table: \n";
print join("\n", @{$table -> render(style => render_html_table)}), "\n";
print "\n";
