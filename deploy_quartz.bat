@echo off
SETLOCAL

REM --- Configuration ---
SET "QUARTZ_PROJECT_DIR=C:\Users\laksh\quartz"
SET "OBSIDIAN_VAULT_PATH=C:\Users\laksh\Desktop\D&D" REM Make sure this is your correct Obsidian vault path


REM --- Navigate to Quartz project directory ---
echo.
echo Navigating to Quartz project directory...
cd /d "%QUARTZ_PROJECT_DIR%"
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Could not change to directory %QUARTZ_PROJECT_DIR%. Exiting.
    GOTO :EOF
)
echo Current directory: %cd%

REM --- Step 1: Ensure main branch is clean and build latest site ---
echo.
echo --- Step 1: Building latest Quartz site from Obsidian changes ---
git checkout main
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to checkout main branch. Aborting.
    GOTO :EOF
)

REM Check if package-lock.json has uncommitted changes and commit them
echo Checking for uncommitted package-lock.json changes...
git status --porcelain package-lock.json | findstr /i "M" >nul
IF %ERRORLEVEL% EQU 0 (
    echo package-lock.json modified. Committing to main...
    git add package-lock.json
    git commit -m "Update package-lock.json after npm install"
    IF %ERRORLEVEL% NEQ 0 (
        echo Warning: Failed to commit package-lock.json. Continuing.
    )
) ELSE (
    echo package-lock.json is clean or not modified.
)

echo Pushing main branch to origin...
git push origin main
IF %ERRORLEVEL% NEQ 0 (
    echo Warning: Failed to push main branch. Continuing.
)

echo Running npx quartz build to generate latest site...
npx quartz build
IF %ERRORLEVEL% NEQ 0 (
    echo Error: npx quartz build failed. Check output above. Aborting deployment.
    GOTO :EOF
)


REM --- Step 2: Deploy the updated site to gh-pages branch ---
echo.
echo --- Step 2: Deploying to gh-pages branch ---

REM Switch to gh-pages
echo Switching to gh-pages branch...
git checkout gh-pages
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to checkout gh-pages branch. Aborting.
    GOTO :EOF
)

REM Remove all old site files from gh-pages branch
echo Removing old site files from gh-pages...
git rm -rf .
IF %ERRORLEVEL% NEQ 0 (
    echo Warning: git rm -rf . encountered an issue. Continuing.
)

REM Copy newly built site content from public folder
echo Copying new site content from public folder...
xcopy public\* . /s /e /h /k /y
IF %ERRORLEVEL% NEQ 0 (
    echo Error: xcopy failed. Aborting deployment.
    GOTO :EOF
)

REM Add copied files to Git's staging area
echo Adding copied files to Git staging area...
git add .
IF %ERRORLEVEL% NEQ 0 (
    echo Error: git add . failed. Aborting deployment.
    GOTO :EOF
)

REM Commit changes to gh-pages branch
echo Committing changes to gh-pages...
git commit -m "Deploy latest Obsidian changes to GitHub Pages"
IF %ERRORLEVEL% NEQ 0 (
    echo Error: git commit failed on gh-pages. Aborting.
    GOTO :EOF
)

REM Push gh-pages branch to GitHub
echo Pushing gh-pages branch to GitHub...
git push origin gh-pages
IF %ERRORLEVEL% NEQ 0 (
    echo Error: git push failed on gh-pages. Aborting.
    GOTO :EOF
)

REM Switch back to main branch
echo Switching back to main branch...
git checkout main
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to checkout main branch after deployment.
)

echo.
echo --- Deployment Complete! ---
echo Check GitHub Actions for status: https://github.com/Webcreator3478/dnd-site-for-players/actions
echo Your site should be live at: https://webcreator3478.github.io/dnd-site-for-players/
echo.

ENDLOCAL