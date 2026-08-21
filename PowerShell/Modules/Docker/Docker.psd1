@{
    RootModule        = 'Docker.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Docker-DotNet'
        'Docker-Node'
        'Docker-Python'
        'Docker-StartInteractive'
        'Start-Mongo'
        'Start-Redis'
        'Start-Postgres'
        'Start-LocalStack'
        'Start-SqlServer'
        'Start-RabbitMQ'
        'Start-Nginx'
        'Start-MySQL'
        'Start-Elasticsearch'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
