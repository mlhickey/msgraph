function Get-MSGSchemaExtension
{
    <#
    .SYNOPSIS
    Get list of schema extensions

    .DESCRIPTION
    The Get-MSGSchemaExtension returns a list of schema extensions in Azure Active Directory (AD)

    .PARAMETER Id
    Specifies the id of a schema extension

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

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
            ParameterSetName = "Search",
            HelpMessage = "Search criteria.")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

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
                Get-MSGObject -Type "schemaExtensions/$id" -Filter $queryFilter
                break
            }

            { $PSItem -match "topall|search" }
            {
                Get-MSGObject -Type "schemaExtensions" -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
