@{
    RootModule        = 'Mongo.psm1'
    ModuleVersion     = '1.0.0'
    PowerShellVersion = '5.1'
    Description       = 'MongoDB container and connection helpers.'
    FunctionsToExport = @('Docker-MongoUi', 'Get-MongoConnectionString', 'Get-MongoContainers', 'Select-MongoContainer', 'Start-MongoUi')
    AliasesToExport   = @('docker-mongo')
    CmdletsToExport   = @()
    VariablesToExport = @()
}
