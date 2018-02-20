#!/bin/bash

set -e

## PUSH TO XDB-LANDMARK-DIST

## set up environment ##
echo -e "\nSetting environment\n"
git --version
git config --global user.email "landmark@fairfaxmedia.com.au"
git config --global user.name "FFX UI Engineering Bot"
git config --global push.default simple

## clone dependent source repos
echo -e "\nClone dependent source repos\n"
cd ~/src/bitbucket.org/fairfax/xdb-landmark
git clone git@bitbucket.org:fairfax/xdb-landmark-dist.git dist

## npm install
echo -e "\nNPM install\n"
rm package.json || export NO_FILE=1
ln -s build/package.json package.json
npm install

## get commit ##
echo -e "\nGet commit\n"
export LANDMARK_COMMIT=`git show --format="%h" HEAD | head -n1 | awk '{ print $1 }'`
echo $LANDMARK_COMMIT
export LANDMARK_COMMIT_MESSAGE=`git show --format="%B" HEAD | head -n1 | awk '{ print }'`
echo $LANDMARK_COMMIT_MESSAGE

## clean dist subdirectories ##
echo -e "\nClean dist subdirectories\n"
cd dist/
ls -1 -d */ | xargs rm -r -f

## package landmark ##
echo -e "\nPackage landmark\n"
cd ../build/
ln -s ../node_modules node_modules
npm run grunt package

## get current version ##
echo -e "\nGet LMK Version\n"
export LMK_VERSION=`git describe --abbrev=0`
echo $LMK_VERSION

## commit and push changes to dist repo ##
echo -e "\ncommit and push changes to dist repo\n"
cd ../dist/
git status
git add --all

## set DIST_HAS_UPDATE=1 by default, meaning there are differences
export DIST_HAS_UPDATE=1

## if commit success DIST_HAS_UPDATE stays as 1 otherwise set DIST_HAS_UPDATE to 0
git commit -m "Update from Landmark $LANDMARK_COMMIT" -m "$LANDMARK_COMMIT_MESSAGE" || DIST_HAS_UPDATE=0
echo -e "\nDist has update: $DIST_HAS_UPDATE\n"

## If updates exist, push change ...
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git push; fi

## Set remote branch
export REMOTE_BRANCH="origin/$CI_BRANCH"
echo -e "\nRemote branch: $REMOTE_BRANCH\n"

if [[ "$DIST_HAS_UPDATE" = "1" ]]; then
    ## Checkout master on xdb-landmark
    echo -e "\nCheckout master on xdb-landmark\n"
    cd ..
    git fetch origin
    git branch -a
    git reset --hard $REMOTE_BRANCH

    ## then bump version on xdb-landmark-dist
    echo -e "\nbump version on xdb-landmark-dist\n"
    cd dist/
    npm i
    grunt bump
    export NEW_VERSION=`git describe --abbrev=0`

    ## then tag version on xdb-landmark
    echo -e "\nTagging new version: $NEW_VERSION\n"
    cd ../
    git tag $NEW_VERSION
    git push origin $NEW_VERSION
fi

## BUMP UP UCMS CSS VERSION

## if dist is updated ("$DIST_HAS_UPDATE" = "1") then do all the commands to bump up the ucms css repo
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then
    echo -e "\nBUMPING UP UCMS CSS VERSION\n"

    ## cleaning local ucms-css repo
    echo -e "\ncleaning local ucms-css repo\n"
    rm -rf ~/src/bitbucket.org/fairfax/ucms-css
    mkdir -p ~/src/bitbucket.org/fairfax/ucms-css

    ## cloning ucms-css repo
    echo -e "\ncloning ucms-css repo\n"
    cd ~/src/bitbucket.org/fairfax/ucms-css
    git clone git@bitbucket.org:fairfax/ucms-css.git .

    ## sites to be included for autobump
    declare -a arr=(
        "ucms-css-afr"
        "ucms-css-mastheads"
        "ucms-css-executive-style"
        "ucms-css-essential-baby"
        "ucms-css-essential-kids"
        "ucms-css-good-food"
        "ucms-css-traveller"
    )

    for sitename in "${arr[@]}"
    do
        ## go to site folder
        echo -e "\ngo to site $sitename\n"
        cd "./$sitename"

        ## replacing any tag in build gradle with the newest tag
        ## use this for linux
        sed -i "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle
        ## use this for mac, by default -i requires backup extension in sed BSD but not the case in sed GNU
        ## sed -i bak -e "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle

        ## removing the backup file whether the file exists or not (only necessary for mac)
        rm -f ./build.gradle.bak

        ## go back to root dir
        cd ..
    done  

    ## commit the changes
    echo -e "\ncommit the changes to ucms css\n"
    git status
    git add --all
    git commit -m "Bump version from Landmark $LANDMARK_COMMIT" -m "$LANDMARK_COMMIT_MESSAGE"
    git push
fi
