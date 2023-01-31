function Get-MSPIMResourceRoleDefinition
{
    <#
    .SYNOPSIS
    Get current list of role definitions for the specified resources

    .DESCRIPTION
    The Get-MSPIMResourceRoleDefinitions cmdlet returns the current list of role definitionse for the specified resources.  If no resource is specified
    then it will return all resources that the current user has access to.

    .PARAMETER ResourceId
    Specifies the resource to query for role definitons

    .EXAMPLE
    Get-MSPIMResourceRoleDefinition  -ResourceId 453fa744-8104-40e9-8756-4a1c4292cd21

    Id                                   ResourceId                           DisplayName                                         Type
    --                                   ----------                           -----------                                         ----
    0d72b023-beec-40c4-a9b0-8fb970da543a 453fa744-8104-40e9-8756-4a1c4292cd21 Reader                                              BuiltInRole
    19f560ac-dbd8-4bac-8491-69f342113031 453fa744-8104-40e9-8756-4a1c4292cd21 Log Analytics Contributor                           BuiltInRole
    32956bf5-7a63-419d-90e7-a3700c943f28 453fa744-8104-40e9-8756-4a1c4292cd21 Contributor                                         BuiltInRole
    21e891fc-cc85-4358-b711-a696f2811512 453fa744-8104-40e9-8756-4a1c4292cd21 Log Analytics Reader                                BuiltInRole
    41c2a09c-299c-4c29-a7fe-2ca0fc2b7e87 453fa744-8104-40e9-8756-4a1c4292cd21 Managed Application Operator Role                   BuiltInRole
    2117b766-db11-4837-bc09-addbb9d2cb2c 453fa744-8104-40e9-8756-4a1c4292cd21 Resource Policy Contributor (Preview)               BuiltInRole
    73b48a29-ca8c-49ed-82ac-963f754e109a 453fa744-8104-40e9-8756-4a1c4292cd21 ExpressRoute Administrator                          CustomRole
    c73fd896-5290-47a6-8cdd-84f7e1fb7bb5 453fa744-8104-40e9-8756-4a1c4292cd21 masterreader                                        CustomRole
    5f503457-71b8-4969-98e5-1472ef6fea3b 453fa744-8104-40e9-8756-4a1c4292cd21 Managed Applications Reader                         BuiltInRole
    c0551f98-b6b7-4968-a63b-c576d671b8bb 453fa744-8104-40e9-8756-4a1c4292cd21 Monitoring Metrics Publisher                        BuiltInRole
    acc94a68-3efd-4a36-a4fc-0fed8e09db0d 453fa744-8104-40e9-8756-4a1c4292cd21 Monitoring Reader                                   BuiltInRole
    d9df2654-d527-4b71-a73c-fa83374f422d 453fa744-8104-40e9-8756-4a1c4292cd21 Monitoring Contributor                              BuiltInRole
    84b337d4-e42d-42d0-aa1b-3c468af35202 453fa744-8104-40e9-8756-4a1c4292cd21 User Access Administrator                           BuiltInRole
    523c3efb-8396-43e9-a147-c8e39733cee7 453fa744-8104-40e9-8756-4a1c4292cd21 Security Reader
    dfa468ec-1b2d-4796-a8c0-350f23f9f99a 453fa744-8104-40e9-8756-4a1c4292cd21 Azure Service Deploy Release Management Contributor CustomRole
    e45413a0-5594-4793-bbb9-65276c97666f 453fa744-8104-40e9-8756-4a1c4292cd21 Owner

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceresource-list?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the specific resource")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$ResourceId
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
        Get-MSGObject -Type "privilegedAccess/azureResources/resources/$ResourceId/roleDefinitions" -ObjectName "MSPIM"
    }
}
