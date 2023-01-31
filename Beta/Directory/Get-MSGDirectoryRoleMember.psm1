function Get-MSGDirectoryRoleMember
{
    <#
    .PARAMETER Id
    Specifieds the id (ObjectId) of a directory role


    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
    https://docs.microsoft.com/en-us/graph/api/directoryrole-list-members?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the role")]
        [Parameter(ParameterSetName = "Count")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(
            ParameterSetName = "Id",
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(ParameterSetName = "Count")]
        [switch]$CountOnly
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
        Get-MSGObject -Type "directoryRoles/$Id/members" -Filter $queryFilter -CountOnly:$CountOnly
    }
}
