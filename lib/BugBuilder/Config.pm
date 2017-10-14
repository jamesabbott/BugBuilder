package BugBuilder::Config;

=pod

=head1 NAME

    BugBuilder::Config - provides centralised config data

=head1 SYNOPSIS

    my $bb_config = BugBuilder::Config->new();
    my $config = $bb_config->get_config(); 

=head1 DESCRIPTION

=cut

use Carp qw(croak);
use YAML::XS qw(LoadFile);

sub new {

    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(%args);

    return $self;

}

sub _init {
	my $self = shift;
	my $config = LoadFile("$FindBin::Bin/../etc/BugBuilder.yaml");
	if ($config->{'picard_dir'}=~/\$ENV\{'PICARD_HOME'\}/) {
                  my $dir = eval $config->{'picard_dir'};
                  $config->{'picard_dir'} = $dir;
          }
          if ($config->{'mauve_dir'}=~/\$ENV\{'MAUVE_HOME'\}/) {
                  my $dir = eval $config->{'mauve_dir'};
                  $config->{'mauve_dir'} = $dir;
          }
          if ($config->{'cgview_dir'}=~/\$ENV\{'CGVIEW_HOME'\}/) {
                  my $dir = eval $config->{'cgview_dir'};
                  $config->{'cgview_dir'} = $dir;
          }
          if ($config->{'pilon_dir'}=~/\$ENV\{'PILON_HOME'\}/) {
                  my $dir = eval $config->{'pilon_dir'};
                  $config->{'pilon_dir'} = $dir;
          }
          if ($config->{'gfinisher_dir'}=~/\$ENV\{'GENOMEFINISHER_HOME'\}/) {
                  my $dir = eval $config->{'gfinisher_dir'};
                  $config->{'gfinisher_dir'} = $dir;
          }


      if ( $config->{'python_lib_path'} ) {
          if ( defined( $ENV{'PYTHONPATH'} ) ) {
              $ENV{'PYTHONPATH'} = "$ENV{'PYTHONPATH'}:" . $config->{'python_lib_path'};
          }
          else {
              $ENV{'PYTHONPATH'} = $config->{'python_lib_path'};
          }
      }
  
      if ( $config->{'perl_lib_path'} ) {
          if ( $ENV{'PERL5LIB'} ) {
              $ENV{'PERL5LIB'} = "$ENV{'PERL5LIB'}:" . $config->{'perl_lib_path'};
          }
          else {
              $ENV{'PERL5LIB'} = $config->{'perl_lib_path'};
          }
      }

	$self->{'config'}=$config;
}

sub get_config {
	my $self = shift;
	return($self->{'config'})
}

1;
