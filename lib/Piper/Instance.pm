#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Instance;

use List::AllUtils qw(last_value max sum);
use List::UtilsBy qw(max_by);
use Piper::Queue;
use Types::Standard qw(ArrayRef ConsumerOf HashRef InstanceOf Str);

use Moo;

with qw(Piper::Role::Instance);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

has pipe => (
    is => 'ro',
    isa => InstanceOf['Piper'],
    handles => 'Piper::Role::Segment',
);

has children => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Piper::Role::Instance']],
    required => 1,
);

sub pressure {
    my ($self) = @_;
    # Return the max among the children
    my $max = max(map { $_->pressure } @{$self->children});
}

#has freezer => (
    #is => 'rwp',
    #isa => HashRef[Bool],
    #default => sub { return {} },
#);
#
#sub freeze {
    #my ($self, $type) = @_;
    #$self->freezer->{$type} = 1;
#}
#
#sub unfreeze {
    #my ($self, $type) = @_;
    #if ($type eq 'all') {
        #$self->set_freezer({});
    #}
    #else {
        #$self->freezer->{$type} = 0;
    #}
#}

BEGIN {
    has drain => (
        is => 'ro',
        isa => InstanceOf['Piper::Queue'],
        builder => sub { Piper::Queue->new() },
        handles => [qw(dequeue ready)],
    );
}

sub enqueue {
    my $self = shift;
    $self->INFO("Queueing items", @_);
    $self->children->[0]->enqueue(@_);
}

sub pending {
    my $self = shift;
    return sum(map { $_->pending } @{$self->children});
}

sub process_batch {
    my ($self) = @_;

    my $best;
    # Overflowing process closest to drain
    if ($best = last_value { $_->pressure > 0 } @{$self->children}) {
        $self->DEBUG("Chose batch $best: overflowing process closest to drain");
    }
    # If no overflowing processes, choose the one closest to overflow
    else {
        $best = max_by { $_->pressure } @{$self->children};
        $self->DEBUG("Chose batch $best: closest to overflow");
    }
    
    $best->process_batch;
    
    # Emit results to next segment
    if (my $ready = $best->ready) {
        $self->follower->{$best}->enqueue(
            $best->dequeue($ready)
        );
    }
}

has directory => (
    is => 'lazy',
    isa => HashRef,
);

sub _build_directory {
    my ($self) = @_;
    my %dir;
    for my $child (@{$self->children}) {
        $dir{$child->path->name} = $child;
    }
    return \%dir;
}

sub find {
    my ($self, $path) = @_;

}

has follower => (
    is => 'lazy',
    isa => HashRef,
);

sub _build_follower {
    my ($self) = @_;
    my %follow;
    for my $index (keys @{$self->children}) {
        if (defined $self->children->[$index + 1]) {
            $follow{$self->children->[$index]} =
                $self->children->[$index + 1];
        }
        else {
            $follow{$self->children->[$index]} = $self->drain;
        }
    }
    return \%follow;
}

sub emit {
    
}

1;
