
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
    [string]$ComputerName = $($env:COMPUTERNAME),
    [Parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
    [string[]]$Name
  )

  begin
  {
    Set-StrictMode -Version Latest
    $returnArray = @()
  }
  process
  {
    # List all local users on the local or a remote computer


    foreach ($user in $Name)
    {
      if ($ComputerName -eq '.') { $computername = $env:COMPUTERNAME }
      #Name                        Property   System.DirectoryServices.PropertyValueCollection
      $thisComputer = [adsi]"WinNT://$computerName,computer"
      $results = ($thisComputer.psbase.Children | Where-Object { $_.psbase.schemaclassname -eq 'user' -and $_.Name -match "$user" } | Select-Object Name,Description,LastLogin)

      foreach ($returneduser in $results) {

        [hashtable]$thisUser = @{}
        $thisUser.UserName = $returneduser | Select-Object -ExpandProperty Name
        $thisUser.description = $returneduser | Select-Object  -ExpandProperty Description
        $thisUser.LastLogin = $returneduser | Select-Object  -ExpandProperty LastLogin

        $returnArray += (New-Object -Type PSObject -Property $thisUser)

      }
    }
  }
  end
  {
    return $returnArray
  }

