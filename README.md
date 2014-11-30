# KVM Plugin for Rex JobControl


This is a KVM plugin for Rex JobControl to provision KVM vms.


## INSTALLATION

Currently this plugin is in early development status. So you have to clone the git repository.

```
git clone https://github.com/RexOps/rex-jobcontrol-plugin-kvm.git
```

Then you can load the plugin from the jobcontrol configuration file.

```
{
  plugins => [
    'Rex::JobControl::Provision::KVM',
  ],
}
```

Before the restart of Rex JobControl you have to update the PERL5LIB env variable to point to the plugin repository:

```
export PERL5LIB=/path/to/rex-jobcontrol-plugin-kvm/lib:$PERL5LIB
```
