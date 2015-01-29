#!/usr/bin/env perl

use strict;
use warnings;

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new(alignment => justify_center);

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
$table -> style(as_boxed);

print "Style: as_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> pass_thru({as_csv => {always_quote => 1} });
$table -> style(as_csv);

print "Style: as_csv: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> style(as_github);

print "Style: as_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

# Restore the saved data.

$table -> data([@data]);
$table -> escape(escape_html);
$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
$table -> pass_thru({as_html => {table => {align => 'center', border => 1} } });

print "Style: as_html: \n";
print join("\n", @{$table -> render(style => as_html)}), "\n";
print "\n";
