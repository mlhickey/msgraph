
function Get-MSGOrganization
{
    <#

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
    https://docs.microsoft.com/en-us/graph/api/organization-get?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties
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
        Get-MSGObject -Type "organization" -Filter $queryFilter
    }
}
