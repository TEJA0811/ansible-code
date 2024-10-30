#/*
# * 
# *
# */
package Container::Volume::Meta;

#
use strict;
use warnings;
use Parse::CPAN::Meta;
use File::Spec::Functions;
use File::Spec::Functions 'rel2abs';

use feature 'say';
use Data::Dumper;

our $VERSION = "version";
our $DEFAULT_HOME = "default_home";
our $CONFIG_HOME = "config_home";
our $CHECK_VOLUME = "checkvolume";
our $VOLUMES = "volumes";

our $DIRS = "dirs";
our $FILES = "files";

our $SRC = "source";
our $DEST = "dest";

our $YAML_FILE = "yaml_file";

# this is the entry method for parsing volume information in yaml file and obtain
# a reference out of it.
sub get_volume_meta {
	print_self(@_);
	my ($class, $file) = @_; # first argument is class name
	#my $file = shift || 'volumes.yml'; # second argument is file name

	print_self($file);

	my $input = Parse::CPAN::Meta->load_file($file);

	# add if condition
	# if not true raise exception

	# else parse input and move forward.
	my $self = parse_input($input);
	$self->{$YAML_FILE} = rel2abs($file);
	print_self($self);
	
	bless ($self, $class);
	return $self; # return reference
}

#parse the input and resolve information
sub parse_input {
	my $input = shift;

	my $self = {}; # create a hash
	$self->{$VERSION} = $input->{$VERSION};
	$self->{$CONFIG_HOME} = $input->{$CONFIG_HOME};
	$self->{$DEFAULT_HOME} = $input->{$DEFAULT_HOME};

	#get backup check
	my $backup = $input->{$CHECK_VOLUME};
	resolve_checks($self, $backup);

	#get reference to node
	my $volumes = $input->{$VOLUMES};

	# check if it is an array type, else raise error
	#say "ref type is " . Scalar::Util::reftype($vol);

	# for each volume data in array
	foreach my $vol (@{$volumes}) {
		resolve($self,$input->{$vol});
	}

	return $self;
}

sub print_self {
	say Dumper(shift)
}

# subroutine to check for files need to be checked if backup is correct
sub resolve_checks {
	my ($self, $checkvol) = @_;
	
	my $default_home = $checkvol->{$DEFAULT_HOME};
	my $files = $checkvol->{$FILES}; #get files
	#direcotries are ignored by default.

	my $config_home = resolve_path_dir($self->{$CONFIG_HOME}, $default_home);

	# resolve files
	resolve_checks_files($self, $config_home, $files);
}

# subroutine to resolve file checks for volumized location
sub resolve_checks_files {
	my ($self, $config, $files) = @_;

	#check if files of array type, else raise error
	foreach my $file (@{$files}) {
		my $dest = resolve_path_file($config, $file);
		#print_self($vol_pair);
		push(@{$self->{$CHECK_VOLUME}}, $dest);
	}
}

# resolve the files and directories to be volumized
sub resolve {
	my ($self, $volume) = @_;

	#check if $volume of hash type, else raise error

	my $default_home = $volume->{$DEFAULT_HOME}; # get default_home
	my $dirs = $volume->{$DIRS}; # get dirs;
	my $files = $volume->{$FILES}; # get files;

	# order in which below commands are important
	my $config_home = resolve_path_dir($self->{$CONFIG_HOME}, $default_home);
	$default_home = resolve_path_dir($self->{$DEFAULT_HOME}, $default_home);

	# resolve directories
	resolve_dirs($self, $config_home, $default_home, $dirs);

	# resolve files
	resolve_files($self, $config_home, $default_home, $files);
	
	#print_self($volume);
}

# resolve dir path
sub resolve_path_dir {
	return catdir(@_);
}

sub resolve_path_file {
	return catfile(@_);
}

# resolve directories
sub resolve_dirs {
	my ($self,$config,$default,$dirs) = @_;

	#check if dirs of array type, else raise error
	foreach my $dir (@{$dirs}) {
		my $src = resolve_path_dir($default,$dir);
		my $dest = resolve_path_dir($config, $dir);
		my $vol_pair = {};
		$vol_pair->{$SRC} = $src;
		$vol_pair->{$DEST} = $dest;
		#print_self($vol_pair);
		push(@{$self->{$DIRS}}, $vol_pair);
	}
}

# resolve files
sub resolve_files {
	my ($self,$config,$default,$files) = @_;

	#check if files of array type, else raise error
	foreach my $file (@{$files}) {
		my $src = resolve_path_file($default,$file);
		my $dest = resolve_path_file($config, $file);
		my $vol_pair = {};
		$vol_pair->{$SRC} = $src;
		$vol_pair->{$DEST} = $dest;
		#print_self($vol_pair);
		push(@{$self->{$FILES}}, $vol_pair);
	}
}

# This subroutine returns version of the yaml file by extracting "version"
sub getVersion {
	my $self = shift;
	return $self->{$VERSION};
}

# This subroutine returns default home location from which relative paths 
# calculated
sub getDefaultHome {
	my $self = shift;
	return $self->{$DEFAULT_HOME};
}

# This subroutine returns config location from which relative paths calculated
sub getConfigHome {
	my $self = shift;
	return $self->{$CONFIG_HOME};
}

# This subroutine retuns a list of volumizing directories
sub get_volumized_dirs {
	my $self = shift;
	return @{$self->{$DIRS}};
}

# This subroutine returns a list of volumizing files
sub get_volumized_files {
	my $self = shift;
	return @{$self->{$FILES}};
}

# This subroutinge returns a list of check files
sub get_check_files {
	my $self = shift;
	return @{$self->{$CHECK_VOLUME}};
}

1;
