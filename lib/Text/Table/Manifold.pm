package Text::Table::Manifold;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	# Values of alignment().

	justify_left   => 0,
	justify_center => 1, # The default.
	justify_right  => 2,

	# Values for empty(), i.e. empty string handling.

	empty_as_empty => 0, # Do nothing. The default.
	empty_as_minus => 1,
	empty_as_text  => 2, # 'empty'.
	empty_as_undef => 3,

	# Values for escape().

	escape_nothing => 0, # The default.
	escape_html    => 1,
	escape_uri     => 2,

	# Values for extend().

	extend_with_empty => 0, # The default.
	extend_with_undef => 1,

	# Values for style().

	as_internal_boxed  => 0, # The default.
	as_csv_text        => 1,
	as_internal_github => 2,
	as_internal_html   => 3,
	as_html_table      => 4,

	# Values for undef(), i.e. undef handling.

	undef_as_empty => 0,
	undef_as_minus => 1,
	undef_as_text  => 2, # 'undef'.
	undef_as_undef => 3, # Do nothing. The default.
];

use HTML::Entities::Interpolate; # This module can't be loaded at runtime.

use List::AllUtils 'max';

use Module::Runtime 'use_module';

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Unicode::GCString;

has alignment =>
(
	default  => sub{return justify_center},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has data =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has empty =>
(
	default  => sub{return empty_as_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has escape =>
(
	default  => sub{return escape_nothing},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has extend =>
(
	default  => sub{return extend_with_empty},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has footers =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has headers =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has padding =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has pass_thru =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has style =>
(
	default  => sub{return as_internal_boxed},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has undef =>
(
	default  => sub{return undef_as_undef},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

our $VERSION = '0.90';

# ------------------------------------------------

sub align_center
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = int( ($width - $s_width) / 2);
	my($right)   = $width - $s_width - $left;

	return (' ' x ($left + $padding) ) . $s . (' ' x ($right + $padding) );

} # End of align_center;

# ------------------------------------------------

sub align_left
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($left)    = $width - $s_width;

	return (' ' x ($left + $padding) ) . $s . ' ';

} # End of align_left;

# ------------------------------------------------

sub align_right
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($right)   = $width - $s_width;

	return ' ' . $s . (' ' x ($right + $padding) );

} # End of align_right;

# ------------------------------------------------

sub _clean_data
{
	my($self, $headers, $data, $footers) = @_;

	for my $column (0 .. $#$headers)
	{
		$$headers[$column] = defined($$headers[$column]) ? $$headers[$column] : '-';
	}

	for my $column (0 .. $#$footers)
	{
		$$footers[$column] = defined($$footers[$column]) ? $$footers[$column] : '-';
	}

	my($empty)  = $self -> empty;
	my($escape) = $self -> escape;
	my($undef)  = $self -> undef;

	use_module('URI::Escape') if ($escape & escape_uri);

	my($s);

	for my $row (0 .. $#$data)
	{
		for my $column (0 .. $#{$$data[$row]})
		{
			$s = $$data[$row][$column];
			$s = defined($s)
					? (length($s) == 0) # Unicode::GCString should not be necessary here.
						? ($empty & empty_as_minus)
							? '-'
							: ($empty & empty_as_text)
								? 'empty'
								: ($empty & empty_as_undef)
									? undef
									: $s # No need to check to empty_as_empty here!
						: $s
					: ($undef & undef_as_empty)
							? ''
							: ($undef & undef_as_minus)
								? '-'
								: ($undef & undef_as_text)
									? 'undef'
									: $s; # No need to check for undef_as_undef here!

			$s                    = $Entitize{$s}  if ($escape & escape_html);
			$s                    = URI::Escape::uri_escape($s) if ($escape & escape_uri);
			$$data[$row][$column] = $s;
		}
	}

} # End of _clean_data.

# ------------------------------------------------

sub gather_statistics
{
	my($self, $headers, $data, $footers) = @_;

	$self -> _rectify_data($headers, $data, $footers);
	$self -> _clean_data($headers, $data, $footers);

	my(@column);
	my($header_width);
	my(@max_widths);

	for my $column (0 .. $#$headers)
	{
		@column = ($$headers[$column], $$footers[$column]);

		for my $row (0 .. $#$data)
		{
			push @column, $$data[$row][$column];
		}

		push @max_widths, max map{Unicode::GCString -> new($_ || '') -> chars} @column;
	}

	$self -> widths(\@max_widths);

} # End of gather_statistics.

# ------------------------------------------------

sub _rectify_data
{
	my($self, $headers, $data, $footers) = @_;
	my($max_length) = 0;

	for my $row (0 .. $#$data)
	{
		$max_length = $#{$$data[$row]} if ($#{$$data[$row]} > $max_length);
	}

	$max_length = max $#$headers, $#$footers, $max_length;

} # End of _rectify_data.

# ------------------------------------------------

sub render
{
	my($self, %hash) = @_;

	for my $key (keys %hash)
	{
		$self -> $key($hash{$key});
	}

	my($output);

	if ($self -> style == as_internal_boxed)
	{
		$output = $self -> render_as_internal_boxed;
	}
	elsif ($self -> style == as_csv_text)
	{
		$output = $self -> render_as_csv_text;
	}
	elsif ($self -> style == as_internal_github)
	{
		$output = $self -> render_as_internal_github;
	}
	elsif ($self -> style == as_internal_html)
	{
		$output = $self -> render_as_internal_html;
	}
	elsif ($self -> style == as_html_table)
	{
		$output = $self -> render_as_html_table;
	}
	else
	{
		die 'Error: Style not implemented: ' . $self -> style . "\n";
	}

	return $output;

} # End of render.

# ------------------------------------------------

sub render_as_internal_boxed
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;
	my($footers) = $self -> footers;

	$self -> gather_statistics($headers, $data, $footers);

	my($padding)   = $self -> padding;
	my($widths)    = $self -> widths;
	my($separator) = '+' . join('+', map{'-' x ($_ + 2 * $padding)} @$widths) . '+';
	my(@output)    = $separator;

	my(@s);

	for my $column (0 .. $#$widths)
	{
		push @s, $self -> align_center($$headers[$column], $$widths[$column], $padding);
	}

	push @output, '|' . join('|', @s) . '|';
	push @output, $separator;

	for my $row (0 .. $#$data)
	{
		@s = ();

		for my $column (0 .. $#$widths)
		{
			push @s, $self -> align_center($$data[$row][$column], $$widths[$column], $padding);
		}

		push @output, '|' . join('|', @s) . '|';
	}

	push @output, $separator;

	return [@output];

} # End of render_as_internal_boxed.

# ------------------------------------------------

sub render_as_csv_text
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;
	my($footers) = $self -> footers;

	$self -> gather_statistics($headers, $data, $footers);

	my($csv)    = use_module('Text::CSV') -> new(${$self -> pass_thru}{as_csv} || {});
	my($status) = $csv -> combine(@$headers);

	my(@output);

	if ($status)
	{
		push @output, $csv -> string;

		for my $row (0 .. $#$data)
		{
			$status = $csv -> combine(@{$$data[$row]});

			if ($status)
			{
				push @output, $csv -> string
			}
			else
			{
				die "Can't combine data:\nLine: " . $csv -> error_input . "\nMessage: " . $csv -> error_diag . "\n";
			}
		}
	}
	else
	{
		die "Can't combine headers:\nHeader: " . $csv -> error_input . "\nMessage: " . $csv -> error_diag . "\n";
	}

	return [@output];

} # End of render_as_csv_text.

# ------------------------------------------------

sub render_as_internal_github
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;
	my($footers) = $self -> footers;

	$self -> gather_statistics($headers, $data, $footers);

	my(@output) = (join('|', @$headers), join('|', map{'-' x $_} @{$self -> widths}) );

	for my $row (0 .. $#$data)
	{
		push @output, join('|', map{defined($_) ? $_ : ''} @{$$data[$row]});
	}

	return [@output];

} # End of render_as_internal_github.

# ------------------------------------------------

sub render_as_internal_html
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;
	my($footers) = $self -> footers;

	$self -> gather_statistics($headers, $data, $footers);

	# What if there are no headers!

	my($table)         = '';
	my($table_options) = ${$self -> pass_thru}{as_internal_html}{table} || {};
	my(@table_keys)    = sort keys %$table_options;

	if (scalar @table_keys)
	{
		$table .= ' ' . join(' ', map{qq|$_ = "$$table_options{$_}"|} keys %$table_options);
	}

	my(@output) = "<table$table>";

	if ($#$headers >= 0)
	{
		push @output, '<thead>';
		push @output, '<th>' . join('</th><th>', @$headers) . '</th>' if ($#$headers >= 0);
		push @output, '</thead>';
	}

	for my $row (0 .. $#$data)
	{
		push @output, '<tr><td>' . join('</td><td>', map{defined($_) ? $_ : ''} @{$$data[$row]}) . '</td></tr>';
	}

	if ($#$footers >= 0)
	{
		push @output, '<tfoot>';
		push @output, '<th>' . join('</th><th>', @$footers) . '</th>' if ($#$footers >= 0);
		push @output, '<tfoot>';
	}

	push @output, '</table>';

	return [@output];

} # End of render_as_internal_html.

# ------------------------------------------------

sub render_as_html_table
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;
	my($footers) = $self -> footers;

	$self -> gather_statistics($headers, $data, $footers);

	my($html) = use_module('HTML::Table') -> new(%{${$self -> pass_thru}{as_html_table} }, -data => $data);

	return [$html -> getTable];

} # End of render_as_html_table.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Text::Table::Manifold> - Render tables in manifold styles

=head1 Synopsis

This is scripts/synopsis.pl:

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
	$table -> style(as_internal_boxed);

	print "Style: as_internal_boxed: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

	# Restore the saved data.

	$table -> data([@data]);
	$table -> pass_thru({as_csv_text => {always_quote => 1} });
	$table -> style(as_csv_text);

	print "Style: as_csv: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

	# Restore the saved data.

	$table -> data([@data]);
	$table -> style(as_internal_github);

	print "Style: as_internal_github: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

	# Restore the saved data.

	$table -> data([@data]);
	$table -> escape(escape_html);
	$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
	$table -> pass_thru({as_internal_html => {table => {align => 'center', border => 1} } });

	print "Style: as_internal_html: \n";
	print join("\n", @{$table -> render(style => as_internal_html)}), "\n";
	print "\n";

	# Restore the saved data.

	$table -> data([@data]);
	$table -> escape(escape_html);
	$table -> pass_thru({as_html_table => {-style => 'color: blue'} });

	print "Style: as_html_table: \n";
	print join("\n", @{$table -> render(style => as_html_table)}), "\n";
	print "\n";

This is the output of synopsis.pl:

	Style: as_internal_boxed:
	+-------------+--------------+----------+-----------------------+-------------------------+
	|    Name     |     Type     |   Null   |          Key          |     Auto increment      |
	+-------------+--------------+----------+-----------------------+-------------------------+
	|     id      |   int(11)    | not null |      primary key      |     auto_increment      |
	| description | varchar(255) | not null |           -           |            -            |
	|    name     | varchar(255) | not null |           -           |            -            |
	| upper_name  | varchar(255) | not null |           -           |            -            |
	|    undef    |      -       |          | http://savage.net.au/ | <tr><td>undef</td></tr> |
	+-------------+--------------+----------+-----------------------+-------------------------+

	Style: as_csv:
	Name,Type,Null,Key,"Auto increment"
	id,int(11),"not null","primary key",auto_increment
	description,varchar(255),"not null",-,-
	name,varchar(255),"not null",-,-
	upper_name,varchar(255),"not null",-,-
	undef,-,0,http://savage.net.au/,<tr><td>undef</td></tr>

	Style: as_internal_github:
	Name|Type|Null|Key|Auto increment
	-----------|------------|--------|---------------------|-----------------------
	id|int(11)|not null|primary key|auto_increment
	description|varchar(255)|not null|-|-
	name|varchar(255)|not null|-|-
	upper_name|varchar(255)|not null|-|-
	undef|-|0|http://savage.net.au/|<tr><td>undef</td></tr>

	Style: as_internal_html:
	<table align = "center" border = "1">
	<thead>
	<th>Name</th><th>Type</th><th>Null</th><th>Key</th><th>Auto increment</th>
	</thead>
	<tr><td>id</td><td>int(11)</td><td>not null</td><td>primary key</td><td>auto_increment</td></tr>
	<tr><td>description</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>name</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>upper_name</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>undef</td><td>-</td><td>0</td><td>http://savage.net.au/</td><td>&lt;tr&gt;&lt;td&gt;undef&lt;/td&gt;&lt;/tr&gt;</td></tr>
	<tfoot>
	<th>One</th><th>Two</th><th>Three</th><th>Four</th><th>Five</th>
	<tfoot>
	</table>

	Style: as_html_table:

	<table style="color: blue">
	<tbody>
	<tr><td>id</td><td>int(11)</td><td>not null</td><td>primary key</td><td>auto_increment</td></tr>
	<tr><td>description</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>name</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>upper_name</td><td>varchar(255)</td><td>not null</td><td>-</td><td>-</td></tr>
	<tr><td>undef</td><td>-</td><td>0</td><td>http://savage.net.au/</td><td>&amp;lt;tr&amp;gt;&amp;lt;td&amp;gt;undef&amp;lt;/td&amp;gt;&amp;lt;/tr&amp;gt;</td></tr>
	</tbody>
	</table>

=head1 Description

Renders your data as tables of various types, using options to the L</style([$style]) method:

=over 4

=item o as_internal_boxed

All headers and table data are surrounded by ASCII characters.

The rendering is done internally.

=item o as_csv_text

Passes the data to L<Text::CSV>. You can use the L</pass_thru([$hashref])> method to set options for
the C<Text::CSV> object.

=item o as_internal_github

As github-flavoured markdown.

The rendering is done internally.

=item o as_internal_html

As a HTML table. You can use the L</pass_thru([$hashref])> method to set options for the HTML table.

The rendering is done internally.

=item o as_html_table

Passes the data to L<HTML::Table>. You can use the L</pass_thru([$hashref])> method to set options
for the C<HTML::Table> object.

Warning: You must use C<Text::Table::Manifold>'s data() method, or the same-named parameter to new(),
and not the C<-data> option to C<HTML::Table>. This is because my module processes the data before
calling the C<HTML::Table>'s new() method.

=back

See data/*.log for output corresponding to scripts/*.pl.

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

See scripts/utf8.pl and data/utf8.log.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Text::Table::Manifold> as you would any C<Perl> module:

Run:

	cpanm Text::Table::Manifold

or run:

	sudo cpan Text::Table::Manifold

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Text::Table::Manifold -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Text::Table::Manifold>.

Details of all parameters are explained in the L</FAQ>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</data([$arrayref])>]):

=over 4

=item o alignment => An imported constant

A value for this parameter is optional.

Alignment applies equally to every cell in the table.

Default: justify_center.

=item o data => $arrayref of arrayrefs

An arrayref of arrayrefs, each one a line of data.

The # of elements in each header/data/footer row does not have to be the same. See the C<extend>
parameter for more.

A value for this parameter is optional.

Default: [].

=item o empty => An imported constant

A value for this parameter is optional.

This specifies how to transform cell values which are the empty string. See also the C<undef>
parameter.

The C<empty> parameter is activated after the C<extend> parameter has been applied.

Default: empty_as_empty. I.e. do not transform.

=item o escape => An imported constant

A value for this parameter is optional.

Default: escape_nothing. I.e. do not transform.

=item o extend => An imported constant

A value for this parameter is optional.

The 2 constants available allow you to specify how short rows are extended. Then, after extension,
the parameters C<empty> or C<undef> are applied.

Default: extend_with_empty. I.e. extend short rows with the empty string.

=item o footers => $arrayref

A value for this parameter is optional.

These are the column footers. See also the C<headers> option.

The # of elements in each header/data/footer row does not have to be the same. See the C<extend>
parameter for more.

Default: [].

=item o headers => $arrayref

A value for this parameter is optional.

These are the column headers. See also the C<footers> option.

The # of elements in each header/data/footer row does not have to be the same. See the C<extend>
parameter for more.

Default: [].

=item o padding => $integer

A value for this parameter is optional.

This integer is the # of spaces added to each side of the cell value, after the C<alignment>
parameter has been applied.

Default: 0.

=item o pass_thru => $hashref

A hashref of values to pass thru to another object.

The keys in this $hashref control what parameters are passed to rendering routines.

Default: {}.

=item o style => An imported constant

A value for this parameter is optional.

This specifies which type of rendering to perform.

Default: as_internal_boxed.

=item o undef => An imported constant

A value for this parameter is optional.

This specifies how to transform cell values which are undef. See also the C<empty> parameter.

The C<undef> parameter is activated after the C<extend> parameter has been applied.

Default: undef_as_undef. I.e. do not transform.

=back

=head1 Methods

=head2 alignment([$alignment])

Here, the [] indicate an optional parameter.

Returns the alignment as a constant (actually an integer).

$alignment might force spaces to be added to one or both sides of a cell value.

Alignment applies equally to every cell in the table.

This happens before any spaces specified by L</padding([$integer])> are added.

See the L</FAQ#What are the constants for alignment?> for legal values for $alignment.

=head2 data([$arrayref])

Here, the [] indicate an optional parameter.

Returns the data as an arrayref. Each element in this arrayref is an arrayref of one row of data.

The structure of C<$arrayref>, if provided, must match the description in the previous line.

Rows do not need to have the same number of elements.

Use Perl's C<undef> or '' (the empty string) for missing values.

See L</empty([$empty])> and L</undef([$undef])> for how '' and C<undef> are handled.

See L</extend([$extend])> for how to extend a short data row.

=head2 empty([$empty])

Here, the [] indicate an optional parameter.

Returns the option specifying how empty cell values ('') are being dealt with.

$empty controls how empty strings in cells are rendered.

See the L</FAQ#What are the constants for handling cell values which are empty strings?>
for legal values for $empty.

See also L</undef([$undef])>.

=head2 escape([$escape])

Here, the [] indicate an optional parameter.

Returns the option specifying how HTML and URIs are being dealt with.

$escape controls how either HTML or URIs are rendered.

See the L</FAQ#What are the constants for escaping HTML and URIs?>
for legal values for $escape.

=head2 extend([$extend])

Here, the [] indicate an optional parameter.

Returns the option specifying how short rows are extended.

If the # of elements in any header/data/footer row is shorter than the longest row, $extend
specifies how to extend those short rows.

See the L</FAQ#What are the constants for extending short rows?> for legal values for $extend.

=head2 footers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the footers as an arrayref of strings.

$arrayref, if provided, must be an arrayref of strings.

See L</extend([$extend])> for how to extend a short footer row.

=head2 headers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the headers as an arrayref of strings.

$arrayref, if provided, must be an arrayref of strings.

See L</extend([$extend])> for how to extend a short header row.

=head2 new([%hash])

The constructor. See L</Constructor and Initialization> for details of the parameter list.

Note: L</render([%hash])> supports the same options as C<new()>.

=head2 padding([$integer])

Here, the [] indicate an optional parameter.

Returns the padding as an integer.

Padding is the # of spaces to add to both sides of the cell value after it has been aligned.

=head2 pass_thru([$hashref])

Here, the [] indicate an optional parameter.

Returns the hashref previously provided.

The structure of this hashref is detailed in the L</FAQ>.

See scripts/synopsis.pl for sample code where it is used to add attributes to the C<table> tag in
HTML output.

=head2 render([%hash])

Here, the [] indicate an optional parameter.

Returns an arrayref, where each element is 1 line of the output table. These lines do not have "\n"
or any other line terminator (e.g. <br/>) added by this module.

It's up to you how to handle the output. The simplest thing is to just do:

	print join("\n", @{$table -> render}), "\n";

Note: C<render()> supports the same options as L</new([%hash])>.

=head2 style([$style])

Here, the [] indicate an optional parameter.

Returns the style as a constant (actually an integer).

See the L</FAQ#What are the constants for styling?> for legal values for $style.

=head2 undef([$undef])

Here, the [] indicate an optional parameter.

Returns the option specifying how undef cell values are being dealt with.

$undef controls how undefs in cells are rendered.

See the L</FAQ#What are the constants for handling cell values which are undef?>
for legal values for $undef.

See also L</empty([$empty])>.

=head1 FAQ

Note: See L</TODO> for what has not been implemented yet.

=head2 How are imported constants used?

Firstly, you must import them with:

	use Text::Table::Manifold ':constants';

Then you can use them in the constructor:

	my($table) = Text::Table::Manifold -> new(alignment => justify_center);

And/or you can use them in method calls:

	$table -> style(as_internal_boxed);

See scripts/synopsis.pl for various use cases.

Note how the code uses the names of the constants. The integer values listed below are just FYI.

=head2 What are the constants for alignment?

The parameter to L</alignment([$alignment])> must be one of the following:

=over 4

=item o justify_left  => 0

=item o justify_left  => 1

=item o justify_right => 2

=back

Alignment applies equally to every cell in the table.

=head2 What are the constants for handling cell values which are empty strings?

The parameter to L</empty([$empty])> must be one of the following:

=over 4

=item o empty_as_empty => 0

Do nothing.

This is the default.

=item o empty_as_minus => 1

Convert empty cell values to '-'.

=item o empty_as_text  => 2

Convert empty cell values to the text string 'empty'.

=item o empty_as_undef => 3

Convert empty cell values to undef.

=back

Warning: This updates the original data!

=head2 What are the constants for handling cell values which are undef?

The parameter to L</undef([$undef])> must be one of the following:

=over 4

=item o undef_as_empty => 0

Convert undef cell values to the empty string ('').

=item o undef_as_minus => 1

Convert undef cell values to '-'.

=item o undef_as_text  => 2

Convert undef cell values to the text string 'undef'.

=item o undef_as_undef => 3

Do nothing.

This is the default.

=back

Warning: This updates the original data!

=head2 What are the constants for escaping HTML and URIs?

The parameter to L</escape([$escape])> must be one of the following:

=over 4

=item o escape_nothing => 0

This is the default.

=item o escape_html    => 1

Use L<HTML::Entities::Interpolate> to escape HTML. C<HTML::Entities::Interpolate> cannot be loaded
as runtime, and so is always needed.

=item o escape_uri     => 2

Use L<URI::Escape>'s uri_escape() method to escape URIs. C<URI::Escape> is loaded at runtime
if needed.

=back

Warning: Do not use C<escape_html> and C<escape_uri> simultaneously, since e.g. the '<' which
has been escaped first by <HTML::Entities::Interpolate> into '&lt;' will then have its '&' escaped
by C<URI::Escape> into '%26'. You probably don't want that, but if you do, that's what will happen.

Warning: This updates the original data!

=head2 What are the constants for extending short rows

The C<extend> option must be one of the following:

=over 4

=item o extend_with_empty

=item o extend_with_undef

=back

Keep in mind that after short headers/data/footers are extended, the logic activated by
L</empty([$empty])> and L</undef([$undef])> is applied.

=head2 What are the constants for styling?

The C<style> option must be one of the following:

=over 4

=item o as_internal_boxed  => 0

Render internally.

=item o as_csv_text        => 1

L<Text::CSV> is loaded at runtime if this option is used.

=item o as_internal_github => 2

Render internally.

=item o as_internal_html   => 3

Render internally.

=item o as_html_table      => 4

L<HTML::Table> is loaded at runtime if this option is used.

=back

=head2 What is the format of the $hashref used in the call to pass_thru()?

It takes these (key => value) pairs:

=over 4

=item o as_csv_text => {...}

Pass these parameters to L<Text::CSV>'s new() method.

=item o as_internal_html => {table => {...} }

Pass these parameters to the C<table> tag.

=back

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o Fancy alignment of real numbers

It makes sense to right-justify integers, but in the rest of the table you probably want to
left-justify strings.

Then, vertically aligning decimal points (whatever they are in your locale) is another complexity.

See L<Text::ASCIITable> and L<Text::Table>.

=item o Embedded newlines

Cell values which are HTML could be split at each "<br/>" and "<br />" for the same reason.

Cell values which are text could be split at each "\n" character, to find the widest line within the
cell. That is then used as the cell's width.

For Unicode, this is complex. See L<http://www.unicode.org/versions/Unicode7.0.0/ch04.pdf>, and
especially p 192, for 'Line break' controls. Also, the Unicode line breaking algorithm is documented
in L<http://www.unicode.org/reports/tr14/tr14-33.html>.

Perl modules relevant to this are listed under L</See also#Line Breaking>.

=item o Nested tables

This really requires the implementation of embedded newline analysis, as per the previous point.

=item o Pass-thru class support

The problem is the mixture of options required to drive classes.

=item o Sorting the rows, or individual columns

See L<Data::Table> and L<HTML::Table>.

=item o Color support

See L<Text::ANSITable>.

=item o Subtotal support

Maybe one day.

=back

=head1 See Also

=head2 Table Rendering

L<Any::Renderer>

L<Data::Formatter::Text>

L<Data::Tab>

L<Data::Table>

L<Data::Tabulate>

L<Gapp::TableMap>

L<HTML::Table>

L<HTML::Tabulate>

L<LaTeX::Table>

L<PDF::Table>

L<PDF::TableX>

L<PDF::Report::Table>

L<Table::Simple>

L<Term::TablePrint>

L<Text::ANSITable>

L<Text::ASCIITable>

L<Text::CSV>

L<Text::FormatTable>

L<Text::MarkdownTable>

L<Text::SimpleTable>

L<Text::Table>

L<Text::Table::Tiny>

L<Text::TabularDisplay>

L<Text::Tabulate>

L<Text::UnicodeBox>

L<Text::UnicodeBox::Table>

L<Text::UnicodeTable::Simple>

L<Tie::Array::CSV>

=head2 Line Breaking

L<Text::Format>

L<Text::LineFold>

L<Text::NWrap>

L<Text::Wrap>

L<Text::WrapI18N>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Text-Table-Manifold>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text::Table::Manifold>.

=head1 Author

L<Text::Table::Manifold> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
