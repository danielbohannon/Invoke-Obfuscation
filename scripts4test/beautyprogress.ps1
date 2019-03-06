If ($host.Runspace.ApartmentState -ne 'STA') { 
	write-host 'Script is not running in STA mode. Switching '
	$Script = $MyInvocation.MyCommand.Definition
	Start-Process powershell.exe -ArgumentList '-sta $Script'
	Exit
}
Function ShowProgressForm {
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
	[Void][Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms.VisualStyles')

$ProgressForm = New-Object System.Windows.Forms.Form
$ProgressForm.Text = 'Ждём 10 секунд'
$ProgressForm.Width = 350
$ProgressForm.Height = 144
$ProgressForm.MaximizeBox = $False
$ProgressForm.MinimizeBox = $False
$ProgressForm.ControlBox = $False
$ProgressForm.ShowIcon = $False
$ProgressForm.StartPosition = 1
$ProgressForm.Visible = $False
$ProgressForm.FormBorderStyle = 'FixedDialog'
$InText = New-Object System.Windows.Forms.Label
$InText.Text = 'Прогрессбарчик покрутим'
$InText.Location = '18,26'
$InText.Size = New-Object System.Drawing.Size(330,18)
$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$ProgressBar1.Name = 'LoadingBar'
$ProgressBar1.Style = 'Marquee'
$ProgressBar1.Location = '17,61'
$ProgressBar1.Size = '300,18'
$ProgressBar1.MarqueeAnimationSpeed = 40
$ProgressForm.Controls.Add($InText)
$ProgressForm.Controls.Add($ProgressBar1)
$sharedData.Form = $ProgressForm 
	[System.Windows.Forms.Application]::EnableVisualStyles()
	[System.Windows.Forms.Application]::Run($ProgressForm)
}
$sharedData = [HashTable]::Synchronized(@{})
$sharedData.Form = $Null
$newRunspace = [RunSpaceFactory]::CreateRunspace()
$newRunspace.ApartmentState = 'STA'
$newRunspace.ThreadOptions = 'ReuseThread'
$newRunspace.Open()
$newRunspace.SessionStateProxy.setVariable('sharedData', $sharedData)
$PS = [PowerShell]::Create()
$PS.Runspace = $newRunspace
$PS.AddScript($Function:ShowProgressForm)
$AsyncResult = $PS.BeginInvoke()
For ($i = 0 ; $i -lt 5; $I++) {
'Двухсекундная интерация: ' + $I
Start-Sleep 2
} 
If($sharedData.Form) {
$sharedData.Form.close()
}
$PS.Endinvoke($AsyncResult)
$PS.dispose()