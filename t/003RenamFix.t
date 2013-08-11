######################################################################
# Test suite for Module::Rename
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Sysadm::Install qw(:all);
use Log::Log4perl qw(:easy);
use File::Basename;
use File::Find;
use FindBin qw( $Bin );


Log::Log4perl->easy_init({level => $ERROR, file => 'STDOUT'});

BEGIN { 
    plan tests => 4;
    use_ok('Module::Rename') 
};

my $sbx = "$Bin/sandbox";
require "$sbx/utils/Utils.pm";

cd $sbx;
rmf "tmp" if -d "tmp";
cp_r("NowOrLater", "tmp");

my $ren = Module::Rename->new(
    name_old           => "NowOrLater::Core::TaskState",
    name_new           => "NowOrLater::Core::Tasks::TaskState",
);

$ren->find_and_rename("tmp");

my $ren2 = Module::Rename->new(
    name_old           => "NowOrLater::Core::Task",
    name_new           => "NowOrLater::Core::Tasks::Task",
);

$ren2->find_and_rename("tmp");

ok -f "tmp/NowOrLater/Core/Tasks/Task.pm", "Task.pm ok";
ok -f "tmp/NowOrLater/Core/Tasks/TaskState.pm", "TaskState.pm ok";
ok !-f "tmp/NowOrLater/Core/Tasks/Tasks/TaskState.pm", "no bogus Tasks.pm";
