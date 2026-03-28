# file-writer.ps1
# Listens on localhost:9998 for POST { filename, content } and writes the file to disk.
# Used by n8n workflows that can't write files directly (Code node sandbox blocks fs).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File file-writer.ps1
#
# To enable secret validation, set $Secret below to match fileWriterSecret in your Config node.

$Port   = 9998
$Secret = ""   # Leave empty to skip validation. Set to match fileWriterSecret in Config node.

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "file-writer listening on http://localhost:$Port/  (press Ctrl+C to stop)"

try {
    while ($listener.IsListening) {
        $context  = $listener.GetContext()
        $request  = $context.Request
        $response = $context.Response

        try {
            # Validate secret if configured
            if ($Secret -ne "") {
                $incoming = $request.Headers["X-Writer-Secret"]
                if ($incoming -ne $Secret) {
                    $response.StatusCode = 401
                    $response.Close()
                    Write-Host "$(Get-Date -f 'HH:mm:ss')  401 Unauthorized (bad secret)"
                    continue
                }
            }

            # Read body
            $reader = [System.IO.StreamReader]::new($request.InputStream)
            $body   = $reader.ReadToEnd()
            $reader.Close()

            $payload  = $body | ConvertFrom-Json
            $filename = $payload.filename
            $content  = $payload.content

            if (-not $filename -or -not $content) {
                throw "Missing filename or content in request body"
            }

            # Create directory if needed and write file
            $dir = Split-Path -Parent $filename
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            [System.IO.File]::WriteAllText($filename, $content, [System.Text.Encoding]::UTF8)

            $response.StatusCode = 200
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
            $response.ContentType   = "application/json"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            Write-Host "$(Get-Date -f 'HH:mm:ss')  200 Written: $filename"

        } catch {
            $response.StatusCode = 500
            $bytes = [System.Text.Encoding]::UTF8.GetBytes("{`"error`":`"$($_.Exception.Message)`"}")
            $response.ContentType   = "application/json"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.Close()
            Write-Host "$(Get-Date -f 'HH:mm:ss')  500 Error: $($_.Exception.Message)"
        }
    }
} finally {
    $listener.Stop()
    Write-Host "file-writer stopped."
}