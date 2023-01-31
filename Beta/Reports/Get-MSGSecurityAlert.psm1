<# https://docs.microsoft.com/en-us/graph/api/resources/security-api-overview?view=graph-rest-beta #>
function Get-MSGSecurityAlert
{
    [CmdletBinding(DefaultParameterSetName = "TopAll")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of alert to retrieve")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll")]
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
                Get-MSGObject -Type "security/alerts/$id" -Filter $queryFilter
                break
            }

            "topall"
            {
                Get-MSGObject -Type "security/alerts" -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
