function Get-MSGFeatureRolloutPolicy
{
    <#
    .SYNOPSIS
    Gets directory FeatureRolloutPolicies available in Azure AD

    .DESCRIPTION
    The Get-MSGFeatureRolloutPolicy cmdlet returns a list of directory FeatureRolloutPolicies available in Azure AD

    .PARAMETER Id
    Specifieds the id (ObjectId) of a feature object

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .LINK
    https://docs.microsoft.com/en-us/graph/api/featurerolloutpolicy-get?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the feature.")]

        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

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
        $uri = "policies/featureRolloutPolicies"
        if (-not [string]::IsNullOrEmpty($Id))
        {
            $uri += "/{$Id}"
        }
        Get-MSGObject -Type $uri -Filter $queryFilter -All:$All
    }
}
