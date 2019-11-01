// This procedure.dsl was generated automatically
// DO NOT EDIT THIS BLOCK === procedure_autogen starts ===
procedure 'Scan Failed Pipelines', description: '''This procedure scans for the failed pipelines in the specified projects. The procedure should run from a schedule (it is using schedule context for state saving).''', {

    step 'Scan Failed Pipelines', {
        description = ''
        command = new File(pluginDir, "dsl/procedures/ScanFailedPipelines/steps/ScanFailedPipelines.pl").text
        shell = 'ec-perl'
        shell = 'ec-perl'

        postProcessor = '''$[/myProject/perl/postpLoader]'''
    }
// DO NOT EDIT THIS BLOCK === procedure_autogen ends, checksum: 44ce3ffab61d2365d0ff96128c3bdaf5 ===
// Do not update the code above the line
// procedure properties declaration can be placed in here, like
// property 'property name', value: "value"
}