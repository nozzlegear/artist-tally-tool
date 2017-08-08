# Super simple build script. Should port this to Fake some day.
dotnet publish -c release -o dist -r ubuntu.16.04-x64
cd dist
zip ../dist.zip ./*
cd ../

Write-Host "Package was built and zipped for publishing."
