######################################################################
# Makefile.PL for Module::Rename
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Module::Rename',
    'VERSION_FROM' => 'lib/Module/Rename.pm', # finds $VERSION
    'EXE_FILES'    => [qw(eg/module-rename)],
    'PREREQ_PM'    => {
        Log::Log4perl   => 0.47,
        Sysadm::Install => 0.14,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Module/Rename.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
