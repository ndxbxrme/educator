call grunt build
call npm version %1 --no-git-tag-version
git add --all
git commit -m %2
git push origin master
REM npm run pack-win