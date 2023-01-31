<#
All SKU features are documented at https://docs.microsoft.com/en-us/graph/api/subscribedsku-list?view=graph-rest-beta&tabs=cs

Note: ID is a combination of tenantId and skuId
Note: Graph doens't currently support Top as a filter so it's emulated with scoped array
#>

function Get-MSGSubscribedSKUs
{
    [CmdletBinding(DefaultParameterSetName = "noargs")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(ParameterSetName = "TopAll")]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false,
            ParameterSetName = "TopAll",
            HelpMessage = "Return all SKUs in directory")]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {

        #region processParameterSet
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "noargs"
            {
                $res = Get-MSGObject -Type "subscribedSkus"
                break
            }
            "id"
            {
                if (-not $id -match "_")
                {
                    $id = $MSGAuthInfo.TenantId + "_" + $id
                }

                $res = Get-MSGObject -Type "subscribedSkus/$id"
                break
            }
            "topall"
            {
                $res = Get-MSGObject -Type "subscribedSkus" -All:$All
                break
            }
        }

        if ($null -ne $res)
        {
            if ($All -or $id.Length)
            {
                $res
            }
            else
            {
                $res[0..($top - 1)]
            }
        }
    }
}
