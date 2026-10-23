# Prepara o PC com Windows para o ESP32 alcançar a API e o broker pela rede
# local (issue #7). Rode no PowerShell como administrador:
#
#   powershell -ExecutionPolicy Bypass -File scripts\preparar-rede-windows.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\preparar-rede-windows.ps1 -CorrigirPortas
#
# - Libera no firewall (só redes privadas) as portas da API e do broker.
# - Com -CorrigirPortas: devolve a faixa de portas dinâmicas ao padrão do Windows
#   (49152-65535). Quando ela começa em 1024, o Hyper-V/WSL reserva blocos como
#   1879-1978 e a 1883 do MQTT dá "access forbidden" no docker compose.
#   Precisa reiniciar o PC depois.
param(
    [switch]$CorrigirPortas
)

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Write-Error 'Abra o PowerShell como administrador.'
    exit 1
}

$portas = @(
    @{ Nome = 'Passe API'; Porta = 3000 },
    @{ Nome = 'Passe MQTT'; Porta = 1883 },
    @{ Nome = 'Passe MQTT TLS'; Porta = 8883 },
    @{ Nome = 'Passe MQTT WebSocket'; Porta = 9001 }
)
foreach ($p in $portas) {
    Get-NetFirewallRule -DisplayName $p.Nome -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    New-NetFirewallRule -DisplayName $p.Nome -Direction Inbound -Protocol TCP -LocalPort $p.Porta `
        -Action Allow -Profile Private | Out-Null
    Write-Host "Firewall: porta $($p.Porta) liberada ($($p.Nome), redes privadas)"
}

$perfil = Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -eq 'Wi-Fi' }
if ($perfil -and $perfil.NetworkCategory -ne 'Private') {
    Write-Warning "A rede Wi-Fi '$($perfil.Name)' está como $($perfil.NetworkCategory). As regras valem só para rede privada:"
    Write-Warning "  Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private"
}

$dinamica = netsh int ipv4 show dynamicport tcp | Select-String 'Porta Inicial|Start Port'
$inicio = [int](($dinamica -split ':')[-1].Trim())
if ($inicio -lt 49152) {
    if ($CorrigirPortas) {
        netsh int ipv4 set dynamic tcp start=49152 num=16384 | Out-Null
        Write-Host 'Faixa de portas dinâmicas voltou para 49152-65535. Reinicie o PC.'
    } else {
        Write-Warning "A faixa de portas dinâmicas começa em $inicio; o Windows pode reservar a 1883 ou a 3000."
        Write-Warning 'Rode de novo com -CorrigirPortas (e reinicie) ou use outra porta: MQTT_PORT=11883 no docker compose.'
    }
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue).IPAddress
Write-Host ''
Write-Host "IP deste PC no Wi-Fi: $ip"
Write-Host "No firmware (firmware/include/credenciais.h):"
Write-Host "  #define API_URL   `"http://${ip}:3000`""
Write-Host "  #define MQTT_HOST `"$ip`""
Write-Host 'Teste de outro aparelho na mesma rede: http://<IP>:3000/health'
