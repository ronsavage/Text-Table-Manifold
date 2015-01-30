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

$table -> headers(['Name', 'Type', 'Null', 'Key', 'Auto increment']);
$table -> data(
[
	['id', 'int(11)', 'not null', 'primary key', 'auto_increment'],
	['description', 'varchar(255)', 'not null', '', ''],
	['name', 'varchar(255)', 'not null', '', ''],
	['upper_name', 'varchar(255)', 'not null', '', ''],
	[undef, '', '0', 'http://savage.net.au/', '<tr><td>undef</td></tr>'],
]);

# Save the data, since render() may update it.

my(@data) = @{$table -> data};

$table -> empty(empty_as_minus);
$table -> undef(undef_as_text);
$table -> padding(1);
$table -> style(style_internal_boxed);

print "Style: style_internal_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> pass_thru({style_csv_text => {always_quote => 1} });
$table -> style(style_csv_text);

print "Style: style_csv: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> style(style_internal_github);

print "Style: style_internal_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> escape(escape_html);
$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
$table -> pass_thru({style_internal_html => {table => {align => 'center', border => 1} } });

print "Style: as_internal_html: \n";
print join("\n", @{$table -> render(style => style_internal_html)}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> escape(escape_html);
$table -> pass_thru({style_html_table => {-style => 'color: blue'} });

print "Style: style_html_table: \n";
print join("\n", @{$table -> render(style => style_html_table)}), "\n";
print "\n";
