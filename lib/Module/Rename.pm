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
        name_old           => undef,
        name_new           => undef,
        dir_exclude        => ['blib'],
        dir_ignore         => ['CVS'],
        wipe_empty_subdirs => 0,
        %options,
    };

    $self->{dir_exclude_hash} = { map { $_ => 1 } @{$self->{dir_exclude}} };
    $self->{dir_ignore_hash}  = { map { $_ => 1 } @{$self->{dir_ignore}} };

    bless $self, $class;
}

###########################################
sub find_and_rename {
###########################################
    my($self, $start_dir) = @_;

    (my $look_for   = $self->{name_old}) =~ s#::#/#g;
    (my $replace_by = $self->{name_new}) =~ s#::#/#g;

    my @files = ();
    my %empty_subdirs = ();

    find(sub {
        if(-d and $self->dir_empty($_)) {
            WARN "$File::Find::name is an empty subdir";
            $empty_subdirs{$File::Find::name}++;
        }
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

    (my $dashed_look_for   = $self->{name_old}) =~ s#::#-#g;
    (my $dashed_replace_by = $self->{name_new}) =~ s#::#-#g;

        # Rename any top directory files like Foo-Bar-0.01
    my @rename_candidates = ();
    find(sub {
        if(/$dashed_look_for/) {
            push @rename_candidates, $File::Find::name;
        }
    }, $start_dir);
    for my $item (@rename_candidates) {
        (my $newitem = $item) =~ s/$dashed_look_for/$dashed_replace_by/;
        mv $item, $newitem;
    }
        # Update empty_subdirs with the latest name changes
    %empty_subdirs = map { s/$dashed_look_for/$dashed_replace_by/; $_; }
        %empty_subdirs;

    my @dirs = ();
        # Delete all empty dirs
    finddepth(sub { 
        if(-d and $self->dir_empty($_) and
           ! exists $empty_subdirs{$File::Find::name}) {
            INFO "$File::Find::name is empty and can go away";
            rmf $_ if $self->{wipe_empty_subdirs};
            $File::Find::prune = 1;
        }
    }, $start_dir);
}

###########################################
sub dir_empty {
###########################################
    my($self, $dir) = @_;

    opendir DIR, $dir or LOGDIE "Cannot open dir $dir";
    my @items = grep { $_ ne "." and $_ ne ".." } readdir DIR;
    closedir DIR;

    @items = grep { ! exists $self->{dir_ignore_hash}->{$_} } @items;
    
    return ! scalar @items;
}

###########################################
sub file_process {
###########################################
    my($self, $file, $path) = @_;

    my $out = "";

    open FILE, "<$file" or LOGDIE "Can't open $file ($!)";
    while(<FILE>) {
        $self->{line} = $.;
        s/($self->{name_old})\b/$self->rep($1)/ge;
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

Did you ever create a module distribution, only to realize later that
the module hierarchary needed to be changed? All of a sudden, 
C<Cool::Frobnicator> didn't sound cool anymore, but needed to be
C<Util::Frobnicator>?

        name_old           => undef,
        name_new           => undef,
        dir_exclude        => ['blib'],
        dir_ignore         => ['CVS'],
        wipe_empty_subdirs => 1,

=head1 EXAMPLES

  $ module-rename Cool::Frobnicator Util::Frobnicator Cool-Frobnicator-0.01

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
