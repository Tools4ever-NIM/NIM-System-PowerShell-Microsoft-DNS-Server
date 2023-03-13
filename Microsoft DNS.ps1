#
# Microsoft DNS.ps1 - Microsoft DNS Server
#
$Log_MaskableKeys = @()

#
# System functions
#
function Idm-SystemInfo {
    param (
        # Operations
        [switch] $Connection,
        [switch] $TestConnection,
        [switch] $Configuration,
        # Parameters
        [string] $ConnectionParams
    )

    Log info "-Connection=$Connection -TestConnection=$TestConnection -Configuration=$Configuration -ConnectionParams='$ConnectionParams'"

    if ($Connection) {
        @(
            @{
                name = 'Hostname'
                type = 'textbox'
                label = 'DNS Server'
                description = 'Hostname for DNS Server'
                value = ''
            }
            @{
                name = 'nr_of_sessions'
                type = 'textbox'
                label = 'Max. number of simultaneous sessions'
                description = ''
                value = 1
            }
            @{
                name = 'sessions_idle_timeout'
                type = 'textbox'
                label = 'Session cleanup idle time (minutes)'
                description = ''
                value = 1
            }
        )
    }

    if ($TestConnection) {
        
    }

    if ($Configuration) {
        @()
    }

    Log info "Done"
}

function Idm-OnUnload {
}

#
# Object CRUD functions
#
$Properties = @{
   Zone = @(
        @{ name = 'DistinguishedName';                              options = @('default')                      }
        @{ name = 'IsAutoCreated';                              options = @('default')                      }
        @{ name = 'IsDsIntegrated';                              options = @('default')                      }
        @{ name = 'IsPaused';                              options = @('default')                      }
        @{ name = 'IsReadOnly';                              options = @('default')                      }
        @{ name = 'IsReverseLookupZone';                              options = @('default')                      }
        @{ name = 'IsShutdown';                              options = @('default')                      }
        @{ name = 'ZoneName';                              options = @('default','key')                      }
        @{ name = 'ZoneType';                              options = @('default')                      }
        @{ name = 'DirectoryPartitionName';                              options = @('default')                      }
        @{ name = 'DynamicUpdate';                              options = @('default')                      }
        @{ name = 'IgnorePolicies';                              options = @('default')                      }
        @{ name = 'IsSigned';                              options = @('default')                      }
        @{ name = 'IsWinsEnabled';                              options = @('default')                      }
        @{ name = 'Notify';                              options = @('default')                      }
        @{ name = 'ReplicationScope';                              options = @('default')                      }
        @{ name = 'SecureSecondaries';                              options = @('default')                      }
        @{ name = 'ZoneFile';                              options = @('default')                      }
   )
   Record = @(
        @{ name = 'DistinguishedName';                              options = @('default')                      }
        @{ name = 'HostName';                              options = @('default','key')                      }
        @{ name = 'RecordType';                              options = @('default')                      }
        @{ name = 'Type';                              options = @('default')                      }
        @{ name = 'RecordClass';                              options = @('default')                      }
        @{ name = 'TimeToLive';                              options = @('default')                      }
        @{ name = 'Timestamp';                              options = @('default')                      }
        @{ name = 'RecordData';                              options = @('default')                      }
   )
}



function Idm-ZonesRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "Zone"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                Get-DnsServerZone -ComputerName $system_params.hostname | Select-Object *
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Idm-ZoneRecordsRead {
    param (
        [switch] $GetMeta,
        [string] $SystemParams,
        [string] $FunctionParams
    )
    $Class = "Zone"
    Log info "-GetMeta=$GetMeta -SystemParams='$SystemParams' -FunctionParams='$FunctionParams'"

    if ($GetMeta) {

        Get-ClassMetaData -SystemParams $SystemParams -Class $Class
    }
    else {
        
        $system_params   = ConvertFrom-Json2 $SystemParams
        $function_params = ConvertFrom-Json2 $FunctionParams

        $properties = $function_params.properties

        if ($properties.length -eq 0) {
            $properties = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }

        # Assure key is the first column
        $key = ($Global:Properties.$Class | Where-Object { $_.options.Contains('key') }).name
        $properties = @($key) + @($properties | Where-Object { $_ -ne $key })

        try { 
                $zones = Get-DnsServerZone -ComputerName $system_params.hostname

                foreach($zone in $zones)
                {
                    Get-DnsServerResourceRecord -ComputerName $system_params.hostname -ZoneName $zone.ZoneName | Select-Object *
                }
            }
            catch {
                Log error "Failed: $_"
                Write-Error $_
            }
    }

    Log info "Done"
}

function Get-ClassMetaData {
    param (
        [string] $SystemParams,
        [string] $Class
    )
    
    @(
        @{
            name = 'properties'
            type = 'grid'
            label = 'Properties'
            description = 'Selected properties'
            table = @{
                rows = @( $Global:Properties.$Class | ForEach-Object {
                    @{
                        name = $_.name
                        usage_hint = @( @(
                            foreach ($opt in $_.options) {
                                if ($opt -notin @('default', 'idm', 'key')) { continue }

                                if ($opt -eq 'idm') {
                                    $opt.Toupper()
                                }
                                else {
                                    $opt.Substring(0,1).Toupper() + $opt.Substring(1)
                                }
                            }
                        ) | Sort-Object) -join ' | '
                    }
                })
                settings_grid = @{
                    selection = 'multiple'
                    key_column = 'name'
                    checkbox = $true
                    filter = $true
                    columns = @(
                        @{
                            name = 'name'
                            display_name = 'Name'
                        }
                        @{
                            name = 'usage_hint'
                            display_name = 'Usage hint'
                        }
                    )
                }
            }
            value = ($Global:Properties.$Class | Where-Object { $_.options.Contains('default') }).name
        }
    )
}
