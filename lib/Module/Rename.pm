###########################################
package Module::Rename;
###########################################

use strict;
use warnings;
use File::Find;
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
use File::Basename;

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        name_old    => undef,
        name_new    => undef,
        dir_exclude => ['blib'],
        %options,
    };

    $self->{dir_exclude_hash} = { map { $_ => 1 } @{$self->{dir_exclude}} };

    bless $self, $class;
}

###########################################
sub find_and_rename {
###########################################
    my($self, $start_dir) = @_;

    (my $look_for   = $self->{name_old}) =~ s#::#/#g;
    (my $replace_by = $self->{name_new}) =~ s#::#/#g;

    my @files = ();

    find(sub {
        if(-d and exists $self->{dir_exclude_hash}->{$_}) {
            $File::Find::prune = 1;
            return;
        }
        return unless -f $_;
        push @files, $File::Find::name if $File::Find::name =~ /$look_for/;
        $self->file_process($_, $File::Find::name);
    }, $start_dir);
    
    for my $file (@files) {
        (my $newfile = $file) =~ s/$look_for/$replace_by/;
        INFO "mv $file $newfile";
        my $dir = dirname($newfile);
        mkd $dir unless -d $dir;
        mv $file, $newfile;
    }
}

###########################################
sub file_process {
###########################################
    my($self, $file, $path) = @_;

    my $out = "";

    open FILE, "<$file" or LOGDIE "Can't open $file ($!)";
    while(<FILE>) {
        $self->{line} = $.;
        s/\b($self->{name_old})\b/$self->rep($1)/ge;
        $out .= $_;
    }
    close FILE;

    blurt $out, $file;
}

###########################################
sub rep {
###########################################
    my($self, $found) = @_;

    INFO "$File::Find::name ($.): $self->{name_old} => $self->{name_new}";
    return $self->{name_new};
}

1;

__END__

=head1 NAME

Module::Rename - Utility functions for renaming a module distribution

=head1 SYNOPSIS

    use Module::Rename;

=head1 DESCRIPTION

Module::Rename blah blah blah.

=head1 EXAMPLES

  $ perl -MModule::Rename -le 'print $foo'

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
