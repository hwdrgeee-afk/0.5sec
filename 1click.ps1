# ===== ADMIN =====
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework

$KEY = "Fade"

# ===== LOGIN =====
[xml]$loginXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
WindowStyle="None" AllowsTransparency="True" Background="Transparent"
Height="180" Width="300" WindowStartupLocation="CenterScreen">

<Border CornerRadius="12" Background="#CC0b0b0b" Padding="20">
<Grid>

<TextBox Name="k" Height="30" Margin="0,30,0,0"
Background="#151515" Foreground="White" BorderThickness="0"
HorizontalContentAlignment="Center"/>

<Button Name="go" Content="ENTER"
Height="30" Margin="0,80,0,0"
Background="#1f1f1f" Foreground="White" BorderThickness="0"/>

<TextBlock Name="s" Foreground="#ff5555"
Margin="0,120,0,0" HorizontalAlignment="Center"/>

</Grid>
</Border>
</Window>
"@

$login = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $loginXaml))
$login.Add_MouseDown({ $login.DragMove() })

$k = $login.FindName("k")
$go = $login.FindName("go")
$s = $login.FindName("s")

# ===== PANEL =====
function Show-Panel {

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
WindowStyle="None" AllowsTransparency="True" Background="Transparent"
Height="380" Width="320" WindowStartupLocation="CenterScreen">

<Window.Resources>
<Style x:Key="FadeBtn" TargetType="Button">
    <Setter Property="Foreground" Value="White"/>
    <Setter Property="Background" Value="#1a1a1a"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="Button">
                <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="12" Padding="10">
                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="bd" Property="Background" Value="#2a2a2a"/>
                    </Trigger>
                    <Trigger Property="IsPressed" Value="True">
                        <Setter TargetName="bd" Property="Background" Value="#3a3a3a"/>
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
</Window.Resources>

<Border CornerRadius="14" Background="#CC0b0b0b" Padding="20">
<Grid>

<StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="220">

<Button Name="fadeplan" Content="FADE PLAN" Style="{StaticResource FadeBtn}" Height="38" Margin="0,6"/>
<Button Name="lowlatency" Content="LOW LATENCY" Style="{StaticResource FadeBtn}" Height="38" Margin="0,6"/>
<Button Name="timer" Content="TIMER" Style="{StaticResource FadeBtn}" Height="38" Margin="0,6"/>
<Button Name="ram" Content="CLEAN RAM" Style="{StaticResource FadeBtn}" Height="38" Margin="0,6"/>

</StackPanel>

<Button Name="close" Content="X"
Width="28" Height="24"
HorizontalAlignment="Right" VerticalAlignment="Top"
Background="Transparent" Foreground="White"/>

</Grid>
</Border>
</Window>
"@

try {
    $w = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
} catch {
    [System.Windows.MessageBox]::Show("UI Error: " + $_.Exception.Message)
    return
}

$w.Add_MouseDown({ $w.DragMove() })

$fadeplan = $w.FindName("fadeplan")
$lowlatency = $w.FindName("lowlatency")
$timer = $w.FindName("timer")
$ram = $w.FindName("ram")
$close = $w.FindName("close")

$close.Add_Click({ $w.Close() })

# ===== FADE PLAN =====
$fadeplan.Add_Click({
    try {
        $raw = powercfg -duplicatescheme SCHEME_MIN
        $guid = ($raw | Select-String "([a-f0-9-]{36})").Matches.Value
        powercfg -changename $guid "Fade"
        powercfg -setactive $guid
        [System.Windows.MessageBox]::Show("Fade Plan OK")
    } catch {
        [System.Windows.MessageBox]::Show("Error: " + $_.Exception.Message)
    }
})

# ===== LOW LATENCY =====
$lowlatency.Add_Click({
    try {
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f | Out-Null

        Set-ItemProperty "HKCU:\Control Panel\Keyboard" "KeyboardDelay" 0 -ErrorAction SilentlyContinue
        Set-ItemProperty "HKCU:\Control Panel\Keyboard" "KeyboardSpeed" 31 -ErrorAction SilentlyContinue

        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinMM {
[DllImport("winmm.dll")] public static extern uint timeBeginPeriod(uint u);
}
"@
        [WinMM]::timeBeginPeriod(1)

        [System.Windows.MessageBox]::Show("LOW LATENCY ON")
    } catch {
        [System.Windows.MessageBox]::Show("Error: " + $_.Exception.Message)
    }
})

# ===== TIMER =====
$timer.Add_Click({
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinMM {
[DllImport("winmm.dll")] public static extern uint timeBeginPeriod(uint u);
}
"@
        [WinMM]::timeBeginPeriod(1)
        [System.Windows.MessageBox]::Show("Timer ON")
    } catch {
        [System.Windows.MessageBox]::Show("Timer Error")
    }
})

# ===== RAM =====
$ram.Add_Click({
    [System.GC]::Collect()
    [System.Windows.MessageBox]::Show("RAM Cleaned")
})

$w.ShowDialog() | Out-Null
}

# ===== LOGIN =====
$go.Add_Click({
    if ($k.Text -eq $KEY) {
        $login.Hide()
        Show-Panel
        $login.Close()
    } else {
        $s.Text = "invalid key"
    }
})

$login.ShowDialog() | Out-Null