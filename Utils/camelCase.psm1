function camelCase ()
{
    [OutputType([string])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$arg
    )

    return ($arg.Substring(0, 1).ToLower() + $arg.Substring(1))
}


