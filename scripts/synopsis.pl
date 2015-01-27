#!/usr/bin/env perl

use strict;
use warnings;

use Log::Any::Adapter ('Stdout');

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new;

$table -> headers(['Name', 'Type', 'Null', 'Key', 'Auto increment']);
$table -> data(
[
	['id', 'int(11)', 'not null', 'primary key', 'auto_increment'],
	['description', 'varchar(255)', 'not null', '', ''],
	['name', 'varchar(255)', 'not null', '', ''],
	['upper_name', 'varchar(255)', 'not null', '', ''],
]);

$table -> style(as_boxed);

print "As boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

$table -> style(as_markdown);

print "As markdown: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";
