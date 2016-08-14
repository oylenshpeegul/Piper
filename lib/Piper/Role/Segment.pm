#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment;

use v5.22;
use warnings;

use Types::Standard qw(Bool CodeRef HashRef);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

=head1 DESCRIPTION

This role contains attributes and methods that apply
to each pipeline segment, both individual handlers
and sub-pipes.

=head1 REQUIRES

The following methods are required for objects that
compose this role.

=head2 _build_id

Must return a globally uniq ID for the constructed
object.

=cut

#TODO remove this need

requires '_build_id';

=head1 ATTRIBUTES

=head2 batch_size

The number of items to process at a time for
the segment.  Will inherit from a parent if
not provided.

=cut

has batch_size => (
    is => 'ro',
    isa => PositiveInt,
    predicate => 1,
);

=head2 filter

A coderef used to filter items sent to this
segment.

It will be run on each item attempting to queue
to this segment.  If the filter returns true, the
item will be queued.  Otherwise, the item will
skip this segment and continue to the next adjacent
segment.

=cut

has filter => (
    is => 'ro',
    isa => CodeRef,
    predicate => 1,
);

=head2 enabled

Set this to false to disable the segment for all
items.  Defaults to true.

=cut

has enabled => (
    is => 'rw',
    isa => Bool,
    default => 1,
);

=head2 id

A globally uniq ID for the segment.  This is primarily
useful for debugging only.

It is automatically generated by the _build_id method.

=cut

has id => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    builder => 1,
);

=head2 label

A label for this segment.  If no label is provided, the
segment's id will be used.

Labels are particularly needed if handlers wish to use
the injectAt method.  Otherwise, labels are still very
useful for debugging.

=cut

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    lazy => 1,
    builder => 1,
);

sub _build_label {
    my $self = shift;
    return $self->id;
}

#TODO explain

has extra => (
    is => 'rwp',
    isa => HashRef,
    predicate => 1,
);

1;
