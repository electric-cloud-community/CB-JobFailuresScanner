package FlowPlugin::CBJobFailuresScanner;
use strict;
use warnings;
use base qw/FlowPDF/;
use FlowPDF::Log;

# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName          => '@PLUGIN_KEY@',
        pluginVersion       => '@PLUGIN_VERSION@',
        configFields        => ['config'],
        configLocations     => ['ec_plugin_cfgs'],
        defaultConfigValues => {}
    };
}

# Auto-generated method for the procedure Scan Failed Pipelines/Scan Failed Pipelines
# Add your code into this method and it will be called when step runs
sub scanFailedPipelines {
    my ($pluginObject, $r, $stepResult) = @_;

    my $projectName = $r->{projectName};
    my $ec = ElectricCommander->new;
    my $filters = [
        {
            propertyName => 'projectName',
            operator => 'equals',
            operand1 => $projectName,
        },
        {
            propertyName => 'outcome',
            operator => 'notEqual',
            operand1 => 'success',
        },
    ];
    my $stateProperty = $r->{statePropertySheet} ? $r->{statePropertySheet} : "/mySchedule/ec_scanFailedPipelines";

    my $lastRun = eval { $ec->getPropertyValue("$stateProperty/lastRun") };
    if ($lastRun) {
        $lastRun = DateTime->from_epoch(epoch => $lastRun);
    }
    # TODO timezone
    if ($lastRun) {
        push @$filters, {
            propertyName => 'finish',
            operator => 'greaterThan',
            operand1 => $lastRun->ymd . 'T' . $lastRun->hms . '.000Z',
        };
    }
    logInfo "Filters: ", $filters;
    my $runtimes = $ec->findObjects('flowRuntime', {filter => $filters});
    logInfo $runtimes->{_xml};
    my $data = {};

    my $text = [];
    my $found = 0;
    for my $runtime ($runtimes->findnodes('//flowRuntime')) {
        my $id = $runtime->findvalue('flowRuntimeId') . '';
        my $pipelineName = $ec->getPropertyValue('/myPipeline/name', {flowRuntimeId => $id});
        my $pipelineId = $ec->getPropertyValue('/myPipeline/id', {flowRuntimeId => $id});
        my $finish = $runtime->findvalue('finish') . '';
        my $host = '$[/server/webServerHost]';
        my $outcome = $runtime->findvalue('outcome') . '';
        my $launchedBy = $runtime->findvalue('launchedByUser') . '';
        my $link = "http://$host/flow/#pipeline-run/$pipelineId/$id";
        push @$text, qq{Pipeline "$pipelineName" from project "$projectName" has not succeeded ($finish): $outcome, launched by $launchedBy};
        push @{$data->{links}}, $link;
        $found = 1;
    }

    if ($found) {
        if ($r->{sendTo}) {
            $ec->sendEmail({
                text => join("\n" => @$text),
                subject => "Failed pipeline runs for project $projectName",
                to => split(/\n/ => $r->{sendTo})
            });
            logInfo "Sent email to $r->{sendTo}";
        }
        my $json = encode_json($data);
        $ec->setProperty($r->{resultProperty} . '/json', $json);
        $ec->setProperty($r->{resultProperty} . '/links', join("\n" => @{$data->{links}}));
        logInfo "Saved data into $r->{resultProperty}";
    }
    my $now = DateTime->now;
    $ec->setProperty("$stateProperty/lastRun", $now->epoch);
    logInfo "Saved current time into $stateProperty/lastRun";
}
## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.


1;
