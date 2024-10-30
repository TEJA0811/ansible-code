package Container::Volume::Actions;

use strict;
use warnings;
use Container::Volume::Meta;

our $SOURCE = $Container::Volume::Meta::SRC;
our $DEST = $Container::Volume::Meta::DEST;

# sub routine to backup files and folder as per yml file.
sub do_backup {
    my ($class, $ymlfile) = @_;
    my $meta = get_metadata($ymlfile);

    foreach my $dir ($meta->get_volumized_dirs()) {
        move_dir_contents($dir); # copy the contents
        delete_dir($dir);
        make_link($dir);
    }

    foreach my $file ($meta->get_volumized_files()) {
        move_file($file);
        delete_file($file);
        make_link($file);
    }
}

# sub routine to get metadata from given yaml file. This should not be called 
# from outside of this script.
sub get_metadata {
    my $ymlfile = shift;
    return Container::Volume::Meta->get_volume_meta($ymlfile);
}

# This should not be called outside of this script.
sub move_dir_contents {
    my $dir = shift;

    my $src = $dir->{$SOURCE};
    my $dest = $dir->{$DEST};

    $dest = substr($dest,0,rindex($dest,"/"));
    # warn if source dir does not exist
    # call shell command to move files
    if (! -d $dest) {
        system("mkdir","-p","$dest");
    }
    system("mv", "$src", "$dest");
    say "moved contents from $src to $dest";
}

# This should not be called outside of this script.
sub delete_dir {
    my $dir = shift;

    my $src = $dir->{$SOURCE};
    #call shell command to delete_dir
    if (-d $src) {
        system("rm", "-r", "$src");
    }
    say "deleted directory $src";
}

# This should not be called outside of this script.
sub make_link {
    my $vol_pair = shift;

    my $src = $vol_pair->{$SOURCE};
    my $dest = $vol_pair->{$DEST};

    # if destination exists
    if (-e $dest) {
        symlink $dest, $src;
    }

    say "making link for dir/file $dest at $src";
}

# This should not be called outside of this script.
sub move_file {
    my $file = shift;

    my $src = $file->{$SOURCE};
    my $dest = $file->{$DEST};
    $dest = substr($dest,0,rindex($dest,"/"));
    if (! -d $dest) {
        system("mkdir","-p","$dest");
    }
    system("mv", "$src", "$dest");
    say "moving file from $src to $dest";
}

# This should not be called outside of this script.
sub delete_file {
    my $file = shift;

    my $src = $file->{$SOURCE};

    if (-f $src) {
        system("rm","$src");
    }
    say "deleting file $src";
}

# creates the backlinks for all files and directories as per yaml file.
sub do_backlink {
    my ($class, $ymlfile) = @_;
    my $meta = get_metadata($ymlfile);

    foreach my $dir ($meta->get_volumized_dirs()) {
        delete_dir($dir);
        make_link($dir);
    }

    foreach my $file ($meta->get_volumized_files()) {
        delete_file($file);
        make_link($file);
    }
}

#  attempts to return backup location for given original location as per yaml file.
sub get_backup_location_dir {
    my ($class, $ymlfile, $defloc) = @_;

    my $meta = get_metadata($ymlfile);
    my $confloc;

    foreach my $dir ($meta->get_volumized_dirs()) {
        if ( $dir->{$SOURCE} eq $defloc) {
            $confloc = $dir->{$DEST};
            last;
        }
    }

    return $confloc;
}

#  attempts to return backup location for given original location as per yaml file.
sub get_backup_location_file {
    my ($class, $ymlfile, $defloc) = @_;

    my $meta = get_metadata($ymlfile);
    my $confloc;

    foreach my $file ($meta->get_volumized_files()) {
        if ( $file->{$SOURCE} eq $defloc) {
            $confloc = $file->{$DEST};
            last;
        }
    }
    return $confloc;  
}

# attempt to verify integrity of files and directory structure. Not implemented.
sub verify_backup {
    # not implemented
    #my ($class, $ymlfile) = @_;
}

# check if backup is already taken by examining special files as per yaml file.
sub check_backup {
    my ($class, $ymlfile) =  @_;
    #say "backup checked";
    my $meta = get_metadata($ymlfile);
    my $error = 0;
    foreach my $file ($meta->get_check_files()) {
        if (! -f $file) {
            say "$file is not present or is a directory.";
            $error = 1;
        }
    }
    exit $error;
}

1;