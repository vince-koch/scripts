function Enable-DirectoryCompletion {
    param(
        [int]$MaxDepth = 5
    )

    $commands = @(
        'cd',
        'Set-Location',
        'pushd',
        'Push-Location'
    )

    Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
        param(
            $commandName,
            $parameterName,
            $wordToComplete,
            $commandAst,
            $fakeBoundParameters
        )

        if ([string]::IsNullOrWhiteSpace($wordToComplete)) {
            return
        }

        $search = $wordToComplete.ToLowerInvariant()

        $skip = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]('node_modules', '.git', 'bin', 'obj', '.vs', '.venv', '__pycache__', '.nuget', 'packages'),
            [System.StringComparer]::OrdinalIgnoreCase)
        $wordRegex = [regex]::new("(^|[-_. ])$([regex]::Escape($search))")
        $options = [System.IO.EnumerationOptions]::new()
        $options.IgnoreInaccessible = $true
        $options.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint
        $maxResults = 50
        $deadline = [DateTime]::UtcNow.AddMilliseconds(150)
        $results = [System.Collections.Generic.List[object]]::new()
        $foundDepth = -1

        # Breadth-first so shallow matches are found before the time budget runs out
        $queue = [System.Collections.Generic.Queue[object]]::new()
        $queue.Enqueue(@((Get-Location).ProviderPath, 0))

        while ($queue.Count -gt 0 -and $results.Count -lt $maxResults -and [DateTime]::UtcNow -lt $deadline) {
            $item = $queue.Dequeue()
            $dir = $item[0]
            $depth = $item[1]

            # Finish the level where matches were found, but don't go deeper
            if ($foundDepth -ge 0 -and $depth + 1 -gt $foundDepth) {
                break
            }

            try {
                foreach ($path in [System.IO.Directory]::EnumerateDirectories($dir, '*', $options)) {
                    $name = [System.IO.Path]::GetFileName($path)
                    $lowerName = $name.ToLowerInvariant()

                    if ($lowerName.Contains($search)) {
                        $score =
                            if ($lowerName -eq $search) { 1000 }
                            elseif ($lowerName.StartsWith($search)) { 900 }
                            elseif ($wordRegex.IsMatch($lowerName)) { 800 }
                            else { 500 }

                        if ($foundDepth -lt 0) { $foundDepth = $depth + 1 }

                        $results.Add([pscustomobject]@{ Score = $score; Name = $name; FullName = $path })
                    }

                    if ($depth -lt $MaxDepth -and -not $skip.Contains($name)) {
                        $queue.Enqueue(@($path, ($depth + 1)))
                    }
                }
            }
            catch { }
        }

        $results |
            Sort-Object -Property @{
                Expression = { $_.Score }
                Descending = $true
            }, @{
                Expression = { $_.Name }
            } |
            ForEach-Object {

                $text = if ($_.Name -match '\s') { "'$($_.Name)'" } else { $_.Name }

                [System.Management.Automation.CompletionResult]::new(
                    $text,
                    $_.Name,
                    [System.Management.Automation.CompletionResultType]::ProviderContainer,
                    $_.FullName
                )
            }
    }.GetNewClosure()
}