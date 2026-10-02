$ErrorActionPreference = "Stop"
$projectPath = $PSScriptRoot
$backendPath = Join-Path $projectPath "backend"
$frontendPath = Join-Path $projectPath "frontend"
$venvPath = Join-Path $projectPath ".venv"

$postgresService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue |
    Where-Object Status -eq "Running" |
    Select-Object -First 1
if (-not $postgresService) {
    throw "A running PostgreSQL Windows service was not found. Start PostgreSQL, then run this script again."
}

$psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
if ($psqlCommand) {
    $psqlPath = $psqlCommand.Source
} else {
    $postgresRoot = Join-Path $env:ProgramFiles "PostgreSQL"
    $psqlPath = Get-ChildItem $postgresRoot -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName "bin\psql.exe" } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
}
if (-not $psqlPath) {
    throw "Could not find psql.exe. Add PostgreSQL's bin folder to PATH or repair the PostgreSQL installation."
}

$postgresBin = Split-Path $psqlPath
$createdbPath = Join-Path $postgresBin "createdb.exe"
$adminPassword = Read-Host "Enter the PostgreSQL postgres account password" -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
try {
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
}

function Invoke-PostgresQuery($Database, $Sql) {
    $result = & $psqlPath --host 127.0.0.1 --username postgres --dbname $Database --set ON_ERROR_STOP=1 --tuples-only --no-align --command $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL command failed. Check the password and local server."
    }
    return ($result -join "").Trim()
}

try {
    Invoke-PostgresQuery "postgres" "SELECT 1;" | Out-Null

    $roleExists = Invoke-PostgresQuery "postgres" "SELECT 1 FROM pg_roles WHERE rolname = 'students_user';"
    if ($roleExists) {
        Invoke-PostgresQuery "postgres" "ALTER ROLE students_user WITH LOGIN PASSWORD 'students_password';" | Out-Null
    } else {
        Invoke-PostgresQuery "postgres" "CREATE ROLE students_user WITH LOGIN PASSWORD 'students_password';" | Out-Null
    }

    $databaseExists = Invoke-PostgresQuery "postgres" "SELECT 1 FROM pg_database WHERE datname = 'students';"
    if ($databaseExists) {
        Invoke-PostgresQuery "postgres" "ALTER DATABASE students OWNER TO students_user;" | Out-Null
    } else {
        & $createdbPath --host 127.0.0.1 --username postgres --owner students_user students
        if ($LASTEXITCODE -ne 0) {
            throw "Could not create the students database."
        }
    }
} finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

$pythonLauncher = Get-Command py -ErrorAction SilentlyContinue
if (-not $pythonLauncher) {
    throw "Python launcher 'py' was not found. Install Python 3.10 or later, then retry."
}

if (-not (Test-Path (Join-Path $venvPath "Scripts\python.exe"))) {
    & $pythonLauncher.Source -3 -m venv $venvPath
    if ($LASTEXITCODE -ne 0) { throw "Could not create the Python virtual environment." }
}
$pythonPath = Join-Path $venvPath "Scripts\python.exe"
& $pythonPath -m pip install -r (Join-Path $backendPath "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "Could not install the backend packages." }

Push-Location $backendPath
try {
    & $pythonPath manage.py migrate
    if ($LASTEXITCODE -ne 0) { throw "Database migration failed." }
} finally {
    Pop-Location
}

Push-Location $frontendPath
try {
    npm install
    if ($LASTEXITCODE -ne 0) { throw "Could not install the frontend packages." }
} finally {
    Pop-Location
}

Start-Process -FilePath $pythonPath -ArgumentList @("manage.py", "runserver", "127.0.0.1:8000") -WorkingDirectory $backendPath
Start-Process -FilePath "cmd.exe" -ArgumentList @("/k", "npm run dev -- --host 127.0.0.1") -WorkingDirectory $frontendPath

Write-Host "Student Management is starting at http://127.0.0.1:5173"