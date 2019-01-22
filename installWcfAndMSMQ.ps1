$runInstalls = {
    param(
        [parameter(Mandatory = $true)]
        [string]$dotnetUrl,
        [parameter(Mandatory = $true)]
        [string]$dotnetSetupFile)
   
    Import-Module WebAdministration
        
    Function InstallRole {
        param([string]$role)
     
        $isRoleInstalled = WindowsFeature | Where-Object Name -eq $role | Select-Object -Property Installed -First 1

        if (-Not $isRoleInstalled.Installed) {
            Write-Host "$role not installed"
            Write-Host "Installing $role"
            Install-WindowsFeature -Name $role
        }
        Write-Host "$role Installed"
    }

    Function InstallMSMQ() {
        @(
            "MSMQ","AS-WAS-Support","AS-MSMQ-Activation","AS-TCP-Activation"
        ) | ForEach-Object { InstallRole $_ }
    }
    Function InstallIIS() {
        @(
            "web-server", "Web-Mgmt-Console","Web-Mgmt-Service","Web-Scripting-Tools","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-AppInit"
            ) | ForEach-Object { InstallRole $_ }
       
        $iisWebsitePath = "IIS:\Sites"

        New-WebManagedModule -Name "ServiceModel-4.0" -Type "System.ServiceModel.Activation.ServiceHttpModule, System.ServiceModel.Activation, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"

        New-WebHandler -Name "svc-Integrated-4.0" -Path "*.svc" -Verb 'GET,POST' -Modules "System.ServiceModel.Activation.ServiceHttpHandlerFactory, System.ServiceModel.Activation, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" -PSPath $iisWebsitePath
      
        New-WebHandler -Name "svc-ISAPI-4.0_32bit" -Path "*.svc" -Verb 'GET,POST' -Modules IsapiModule -PSPath $iisWebsitePath
        New-WebHandler -Name "svc-ISAPI-4.0_64bit" -Path "*.svc" -Verb 'GET,POST' -Modules IsapiModule -PSPath $iisWebsitePath
    }
    Function InstallASPNET() {
        @(
            "Web-Asp-Net45","Web-Net-Ext45"
        ) | ForEach-Object { InstallRole $_ }
    }
  
    Function InstallDotNet {
        param([string]$dotnetUrl,[string]$dotnetSetupFile)
        
        $start_time = Get-Date
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetSetupFile
        Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
        
        Write-Host "Installing Tentacle"
        Start-Process $dotnetSetupFile  -ArgumentList "/q /norestart"
        Write-Host "Tentacle Installed"
    }
    Function Main {
        param(
            [parameter(Mandatory = $true)]
            [string]$dotnetUrl,
            [parameter(Mandatory = $true)]
            [string]$dotnetSetupFile)

        Write-Host "MSMQ"
        InstallMSMQ
        Write-Host "IIS"
        InstallIIS
        InstallASPNET
       
        InstallDotNet $dotnetUrl $dotnetSetupFile
    }
  
    Main $dotnetUrl $dotnetSetupFile
}

$machineName = ""
$dotnetUrl = "https://download.microsoft.com/download/0/5/C/05C1EC0E-D5EE-463B-BFE3-9311376A6809/NDP472-KB4054531-Web.exe"
$dotnetSetupFile = "D:\NDP472-KB4054530-x86-x64-AllOS-ENU.exe"

$Session = New-PSSession -ComputerName $machineName

Invoke-Command -Session $Session -ScriptBlock $runInstalls -ArgumentList $dotnetUrl, $dotnetSetupFile