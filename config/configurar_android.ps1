$ErrorActionPreference = 'Stop'
$archivo = 'android/app/build.gradle.kts'
if (-not (Test-Path $archivo)) {
    Write-Host 'No se encontro android/app/build.gradle.kts. Ejecuta flutter create primero.' -ForegroundColor Yellow
    exit 1
}
$contenido = Get-Content $archivo -Raw
if ($contenido -notmatch 'isCoreLibraryDesugaringEnabled\s*=\s*true') {
    if ($contenido -match 'compileOptions\s*\{') {
        $contenido = [regex]::Replace($contenido, '(compileOptions\s*\{)', ('$1' + "`r`n        isCoreLibraryDesugaringEnabled = true"), 1)
    } else {
        throw 'No se encontro compileOptions en build.gradle.kts.'
    }
}
if ($contenido -notmatch 'coreLibraryDesugaring\(') {
    $linea = '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if ($contenido -match 'dependencies\s*\{') {
        $contenido = [regex]::Replace($contenido, '(dependencies\s*\{)', ('$1' + "`r`n" + $linea), 1)
    } else {
        $contenido += "`r`n`r`ndependencies {`r`n$linea`r`n}`r`n"
    }
}
Set-Content -Path $archivo -Value $contenido -Encoding UTF8
Write-Host 'Desugaring configurado correctamente.' -ForegroundColor Green
