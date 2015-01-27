package Text::Table::Manifold;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	as_markdown    =>  0, # The default.
	as_boxed       =>  1,
];

use List::AllUtils 'max';

use Log::Any;

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Str/;

use Unicode::GCString;

has data =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has escapes =>
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

has header_widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has log =>
(
	default  => sub { return Log::Any -> get_logger },
	is       => 'ro',
	isa      => Any,
	required => 0,
);

has options =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has style =>
(
	default  => sub{return 'boxed'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

} # End of BUILD.

# ------------------------------------------------

sub gather_statistics
{
	my($self, $headers, $data) = @_;

	my($column_count);

	for my $row (0 .. $#$data)
	{
		$column_count = $#{$$data[$row]};

		die "# of data columns (@{[$column_count]}) != # of header columns (@{[$#$headers]})\n" if ($column_count != $#$headers);
	}

	my(@header_widths);
	my(@max_widths);

	for my $column (0 .. $#$headers)
	{
		my(@column);

		for my $row (0 .. $#$data)
		{
			push @column, $$data[$row][$column];
		}

		push @header_widths, Unicode::GCString -> new($$headers[$column]) -> chars;
		push @max_widths, max $header_widths[$#header_widths], map{Unicode::GCString -> new($_) -> chars} @column;
	}

	$self -> header_widths([@header_widths]);
	$self -> widths(\@max_widths);

} # End of gather_statistics.

# ------------------------------------------------

sub pad_center
{
	my($self, $s, $width) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = int( ($width - $s_width) / 2);
	my($right)   = $width - $s_width - $left;

	return (' ' x ($left + 1) ) . $s . (' ' x ($right + 1) );

} # End of pad_center;

# ------------------------------------------------

sub pad_left
{
	my($self, $s, $width) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = $width - $s_width;

	return (' ' x ($left + 1) ) . $s . ' ';

} # End of pad_left;

# ------------------------------------------------

sub pad_right
{
	my($self, $s, $width) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($right)   = $width - $s_width;

	return ' ' . $s . (' ' x ($right + 1) );

} # End of pad_right;

# ------------------------------------------------

sub render
{
	my($self) = @_;

	my($output);

	if ($self -> style == as_boxed)
	{
		$output = $self -> render_boxed;
	}
	elsif ($self -> style == as_markdown)
	{
		$output = $self -> render_markdown;
	}
	else
	{
		$self -> log -> error('Style not implemented: ' . $self -> style);
	}

	return $output;

} # End of render.

# ------------------------------------------------

sub render_boxed
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;

	$self -> gather_statistics($headers, $data);

	my($widths)    = $self -> widths;
	my($separator) = '+' . join('+', map{'-' x ($_ + 2)} @$widths) . '+';
	my(@output)    = $separator;

	my(@s);

	for my $column (0 .. $#$widths)
	{
		push @s, $self -> pad_center($$headers[$column], $$widths[$column]);
	}

	push @output, '|' . join('|', @s) . '|';
	push @output, $separator;

	for my $row (0 .. $#$data)
	{
		@s = ();

		for my $column (0 .. $#$widths)
		{
			push @s, $self -> pad_center($$data[$row][$column], $$widths[$column]);
		}

		push @output, '|' . join('|', @s) . '|';
	}

	push @output, $separator;

	return [@output];

} # End of render_boxed.

# ------------------------------------------------

sub render_markdown
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;

	$self -> gather_statistics($headers, $data);

	my(@output) = join('|', @$headers);

	push @output, join('|', map{'-' x $_} @{$self -> header_widths});

	my($width);

	for my $row (0 .. $#$data)
	{
		push @output, join('|', @{$$data[$row]});
	}

	return [@output];

} # End of render_markdown.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Text::Table::Manifold> - Render tables in manifold styles

=head1 Synopsis

This is scripts/synopsis.pl:

This is the output of synopsis.pl:

=head1 Description

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

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

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</text([$stringref])>]):

=over 4

=item o close => $arrayref

An arrayref of strings, each one a closing delimiter.

The # of elements must match the # of elements in the 'open' arrayref.

See the L</FAQ> for details and warnings.

A value for this option is mandatory.

Default: None.

=back

=head1 Methods

=head2 bnf()

Returns a string containing the grammar constructed based on user input.

=head1 FAQ

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o This

=item o That

=back

=head1 See Also

L<Any::Renderer>

L<Data::Formatter::Text>

L<Data::Tab>

L<Data::Table>

L<Data::Tabulate>

L<Gapp>

L<HTML::Table>

L<HTML::Tabulate>

L<Text::ASCIITable>

L<Text::CSV>

L<Text::Table>

L<Text::TabularDisplay>

L<Text::Tabulate>

L<Tie::Array::CSV>

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
