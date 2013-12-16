package Git::Archive;

use strict;
use v5.10.0;
our $VERSION = '0.01';

use Git::Repository;
use Data::Dumper;

sub commit {
    my $self = shift;
    # Get passed-in arguments correctly into hash
    my %args = ref $_[0] eq 'HASH' ? %{ shift @_ } : @_;

    # Check for mandatory args
    ## First, make sure we have an error sub defined
    my $error = $args{error} // sub { my $error = shift; print STDERR $error };

    ## Now throw errors if necessary
    unless ( $args{msg} ) {
        $error->('No commit message supplied');
        return 1;
        }
    unless ( $args{files} || $args{all_tracked} || $args{all_dirty} ) {
        $error->('No files specified to commit');
        return 2;
        }

    # Seems all is well. Check if the environment is sane
    ## Is the current or passed-in directory a git repo?
    my $repo;
    eval { $repo = Git::Repository->new( git_dir => $args{git_dir} ); };
    if ($@) { $error->($@); return 3; }

    ## Are there files already staged?
    if ( $repo->run( qw/diff --cached --name-only/ ) ) {
        $error->('Repo already has staged files');
        return 4
        }

    # Looks like we're good to go. Stage the files
    my $files;
    if ( $args{files} ) {
        ## We have a list of specified files to commit
        $files = $self->filenames( \%args );
        eval { $repo->run( add => $files ); };
        ## Do we need to make sure all the files had changes to stage?
        if ( $args{check_all_staged} ) {
            my @staged = $repo->run( qw/diff --cached --name-only/ );
            my @files = split ' ', $files;
            unless ( @staged == @files ) {
                # Numerical equality is Good Enough for now
                $repo->run( reset => 'HEAD' ); # Unstage the files, it's all gone wrong!
                $error->('Some files not staged when "check_all_staged" specified');
                return 5;
                }
            }
        }
    elsif ( $args{all_tracked} ) {
        ## We want to commit any modified tracked files
        }
    elsif ( $args{all_dirty} ) {
        ## We want to commit all files in their current state
        }

    # Files staged and ready to go. Commit time
    $repo->run( commit => '-m "' . $args{msg} . '"' );

    # We've got a new commit. Do we need to worry about a remote?
    if ( my $remote = $args{use_remote} ) {
        # Yup, we do. So, get any updates
        $repo->run( fetch => $remote );

        # Find out if our committed files have been modified on the remote
        my $branch = $repo->run( 'rev-parse --abbrev-ref HEAD' );
        my @remote_files = $repo->run( qq#diff $remote/$branch HEAD^ --name-only# );
        # ^ checks the current head of our branch against the commit BEFORE
        # the one we just added - we know that the current HEAD has changed
        # the files we just committed!
        my %remotes = map { $_ => 1 } @remote_files;
        if ( grep { $remotes{$_} } @{ split ' ', $files } ) {
            $error->('Commit cannot be pushed due to possible conflicts');
            return 6;
            }

        # Looks like we should be good to go. Push time?
        # No, we want to 'pull' first, of course. Except ideally, without going back
        # to the remote, so let's fake it with the fetch we just did
        $remote->run( "merge FETCH_HEAD" );
        # Now that we're effectively 'pull'ed up to date, push
        # Hopefully nobody's had time to push anything else in the tiny window
        my $push = $remote->run( "push $remote" );

        # Should be ok, but let's make sure
        if ( $push =~ m#\[rejected\]# ) {
            $error->( 'Could not push commit, git returned: ' . $push );
            return 7;
            }
        }

    # Looks like we made it! Run the success sub if appropriate
    $args{success}->( \%args ) if $args{success};

    return 0;
    }

sub filenames {
    my ( $self, $args ) = @_;

    if ( ref $args->{files} eq 'ARRAY' ) {
        my $files = join ' ', @{ $args->{files} };
        $files =~ s/\s+/ /;
        return $files;
        }
    else {
        return $args->{files};
        }
    }

1;
__END__

=encoding utf-8

=head1 NAME

Git::Archive - For automated git commits

=head1 SYNOPSIS

  use Git::Archive;
  Git::Archive->commit({ msg => "Committing files", files => (qw/foo bar/) });

=head1 DESCRIPTION

Git::Archive is designed to simplify the automated commit of files in a git repo,
with optional pushing to a remote branch

=head2 Arguments:

=head3 msg

Commit message. This one is mandatory.

=head3 files

List of filenames to commit. Necessary unless you specify all_tracked or all_dirty

=head3 error

If you want to do more with errors than dump them to STDERR, supply a function to handle them

=head3 success

If you want to execute some code upon successful commit (send an email, etc.) supply the
function here

=head3 all_tracked

If you want to simply commit all tracked files, set this to be true

=head3 all_dirty

If you want to commit all changes in the directory, tracked or not, set this to be true

=head3 use_remote

If you want to push to a remote, set this to the name of the remote (usually 'origin')

=head3 check_all_staged

If you want to make sure every file supplied in the 'files' arg is staged before committing,
set this to be true: It will then throw an error if the file was unchanged/doesn't exist

=head3 git_dir

If you want to use a directory other than the current one as your repo, specify it here

=head1 AUTHOR

Dominic Humphries E<lt>dominic@oneandoneis2.comE<gt>

=head1 COPYRIGHT

Copyright 2013 Dominic Humphries

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Git::Repository

=cut
