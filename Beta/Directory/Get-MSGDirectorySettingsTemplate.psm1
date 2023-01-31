function Get-MSGDirectorySettingsTemplate
{
    <#
    .SYNOPSIS
    Gets current templates from tenant

    .DESCRIPTION
    The Get-MSGDirectorySettingsTemplate cmdlet retrieves templates from tenant

    .PARAMETER Id
    Specifieds the id (ObjectId) of a directory role

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
    https://docs.microsoft.com/en-us/graph/api/resources/directorysettingtemplate?view=graph-rest-beta
    #>
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the extension")]

        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                Get-MSGObject -Type "directorySettingTemplates/$Id" -Filter $queryFilter
                break
            }
            "search"
            {
                Get-MSGObject -Type "directorySettingTemplates" -SearchString "startswith(displayName,'$SearchString')" -Filter $queryFilter -All:$All
                break
            }
            "topall"
            {
                Get-MSGObject -Type "directorySettingTemplates" -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
