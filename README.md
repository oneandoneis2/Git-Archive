# NAME

Git::Archive - For automated file archiving with Git

# SYNOPSIS

    use Git::Archive;
    Git::Archive->commit({ msg => "Committing files", files => [qw/foo bar/] });

# DESCRIPTION

When you want to have code maintain a file archive by committing changes to a Git repo,
you don't have the luxury of being lazy and simply telling the code to do:

    git pull
    git commit changes
    git push

Many little things can go wrong:

- What if files are already staged when your code goes to commit its changes?
- What if there are conflicts on pull?
- What if the world ends?

This is a module that helps you not have to care about such questions!
(Two out of three ain't bad)

The goal is to allow you to simply call the commit method, and know that you'll get
a useful error and safe recovery to a working state, whatever goes wrong.

## Arguments:

### msg

Commit message. This one is mandatory.

### files

List of filenames to commit. Necessary unless you specify all\_tracked or all\_dirty.
Can be a string of space-separated files, or an arrayref of files

### error

Default behaviour for errors is to just dump them to STDERR.

If you want something more exciting (like email!) supply a subref here.

#### Args:

- $args

    Hashref, mostly the arguments you passed in when calling the commit method

- $error

    String containing the actual error message

### success

If you want to execute some code upon successful commit supply the function here

#### Args:

- $args

    Hashref, mostly the arguments you passed in when calling the commit method

### all\_tracked

If you want to simply commit all tracked files, set this to be true

### all\_dirty

If you want to commit all changes in the directory, tracked or not, set this to be true

### use\_remote

If you want to push to a remote, set this to the name of the remote
(You'll typically want this to be 'origin')

### check\_all\_staged

If you want to make sure every file supplied in the 'files' arg is staged before committing,
set this to be true: It will then throw an error if the file was unchanged/doesn't exist

### git\_dir

If you want to use a directory other than the current one as your repo, specify it here

Note: If your git-controlled dir is ./foo and you want to commit the file ./foo/bar/baz
then ( git\_dir => './foo', files => 'bar/baz' )

# AUTHOR

Dominic Humphries <dominic@oneandoneis2.com>

# COPYRIGHT

Copyright 2013 Dominic Humphries

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

Git::Repository
