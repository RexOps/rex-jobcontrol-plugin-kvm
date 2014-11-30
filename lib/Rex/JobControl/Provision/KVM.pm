#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

use strict;
use warnings;

package Rex::JobControl::Provision::KVM;

use Moo;
use YAML;
use namespace::clean;
use Rex::JobControl::Provision;
use Data::Dumper;

require Rex::Commands;
use Rex::Commands::Virtualization;

with 'Rex::JobControl::Provision::Base', 'Rex::JobControl::Plugin';

Rex::JobControl::Provision->register_type('kvm');

has image     => ( is => 'ro' );
has host      => ( is => 'ro' );
has name      => ( is => 'ro' );
has kvm_id => ( is => 'ro' );

sub create {
  my ($self) = @_;
  $self->project->app->log->debug(
    "Creating a docker container from image: " . $self->image );

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'LibVirt' );

  vm clone => $self->image, $self->name;
  if($? != 0) {
    $self->project->app->log->error("Error cloning VM. virt clone returned non zero value.");
    die "Error cloning VM.";
  }

  my $vm_info = vm info => $self->name;
  return { kvm_id => $vm_info->{uuid} };
}

sub remove {
  my ($self) = @_;

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'LibVirt' );

  eval { vm destroy => $self->kvm_id; };
  vm delete => $self->kvm_id;
}

sub get_auth_data {
  my ( $self, $node ) = @_;
  return $node->data->{data}->{kvm}->{auth};
}

sub get_data {
  my ($self) = @_;

  my $host_node = Rex::JobControl::Helper::Project::Node->new(
    node_id => $self->host,
    project => $self->project
  );

  my $auth = $self->get_auth_data($host_node);
  $self->project->app->ssh_pool->connect_to(
    ( $host_node->data->{ip} || $host_node->name ),
    %{$auth}, port => ( $host_node->data->{ssh_port} || 22 ) );

  Rex::Commands::set( virtualization => 'LibVirt' );

  return vm info => $self->kvm_id;
}

sub get_hosts {
  my ($self) = @_;
  return $self->project->get_nodes(
    sub {
      my ($file) = @_;
      $self->project->app->log->debug(
        "Reading $file to see if it is a KVM host.");
      my $ref = YAML::LoadFile($file);
      if ( exists $ref->{data}
        && exists $ref->{data}->{kvm_host}
        && $ref->{data}->{kvm_host} )
      {
        return 1;
      }
      else {
        return 0;
      }
    }
  );
}

1;
