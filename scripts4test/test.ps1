$source = @"
using System;
using System.Runtime.InteropServices;
public class ShowMess
{
        [DllImport(`"user32.dll`", EntryPoint=`"FindWindow`", SetLastError = true)]
        static extern IntPtr FindWindowByCaption(IntPtr ZeroOnly, string lpWindowName);
        [DllImport(`"user32.Dll`")]
        static extern int PostMessage(IntPtr hWnd, UInt32 msg, int wParam, int lParam);
        [DllImport(`"user32.dll`", CharSet = CharSet.Unicode)]
        public static extern int MessageBox(IntPtr hWnd, String text, String caption, uint type);
        private const UInt32 WM_CLOSE = 0x0010;
        public static void ShowAutoClosingMessageBox(string message, string caption)
        {
                var timer = new System.Timers.Timer(5000) { AutoReset = false };
                timer.Elapsed += delegate
                {
                        IntPtr hWnd = FindWindowByCaption(IntPtr.Zero, caption);
                        if (hWnd.ToInt32() != 0) PostMessage(hWnd, WM_CLOSE, 0, 0);
                };
                timer.Enabled = true;
                MessageBox(new IntPtr(0), message, caption, 0);
        }
}
"@
Add-Type -TypeDefinition $source
[ShowMess]::ShowAutoClosingMessageBox("TestMessageBox","This autoclose in 3 sec")
[string] $cmd = 'calc'; Write-Verbose -Message $cmd; Invoke-Command -ScriptBlock ([ScriptBlock]::Create($cmd))