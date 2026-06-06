https://learn.microsoft.com/en-us/dotnet/core/tools/global-tools



dotnet new tool-manifest
dotnet tool install dotnetsay
dotnet tool restore
dotnet tool install dotnetsay --version 2.1.3

dotnet tool list
dotnet tool list dotnetsay


dotnet tool run dotnetsay
dotnet dotnetsay

dotnet tool update --global <packagename>
dotnet tool update --tool-path <packagename>
dotnet tool update <packagename>