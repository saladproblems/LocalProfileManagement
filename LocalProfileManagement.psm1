class ValidateCimClass : System.Management.Automation.ValidateEnumeratedArgumentsAttribute {

    [string]$PropertyName

    ValidateCimClass([string[]]$PropertyName) {
        $this.PropertyName = $PropertyName
    }

    [void]ValidateElement($Element) {
        if ($this.PropertyName -notmatch $Element.CimClass.CimClassName) {
            throw ('Unexpected CIM class type: {0}' -f $Element.CimClass.CimClassName)
        }
    }
}

Function Get-LPProfile {
 
    [CmdletBinding()]
    Param(
        [Parameter()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(position=0)]
        [string[]]$Name,

        [Parameter()]
        [string[]]$ExcludeName
    )

    $nameFilter = ($Name -replace '(.+)', 'LocalPath like "$1"') -join ' OR ' -replace '(.+)', '($1)'
    $excludeFilter = ($excludeName -replace '(.+)', 'LocalPath like "$1"') -join ' AND ' -replace '(.+)', 'NOT ($1)'

    $getParam = @{
        ComputerName = $ComputerName
        ClassName    = 'Win32_UserProfile'
        Filter       = @('special = false', $nameFilter, $excludeFilter) -match '\w' -join ' AND ' -replace '\*', '%'
    }
    
    Get-CimInstance @getParam

}

function Remove-LPUserProfile {
    [CmdletBinding(SupportsShouldProcess, confirmimpact = 'high')]
    param(
        [parameter(ValueFromPipeline)]
        [alias('profile', 'ciminstance')]
        [ValidateCimClass('Win32_UserProfile')]
        [ciminstance[]]$InputObject
    )

    process {
        $_ | foreach-object {
            if ($PSCmdlet.ShouldProcess( ('{0}: profile "{1}"' -f $_.pscomputername, $_.LocalPath))) {
                Remove-CimInstance $_
            }
        }
    }

}