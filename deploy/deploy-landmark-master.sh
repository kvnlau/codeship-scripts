#!/bin/bash

## PUSH TO XDB-LANDMARK-DIST

## set up environment ##
git --version
git config --global user.email "landmark@fairfaxmedia.com.au"
git config --global user.name "FFX UI Engineering Bot"
git config --global push.default simple

## clone dependent source repos
cd ~/src/bitbucket.org/fairfax/xdb-landmark
git clone git@bitbucket.org:fairfax/xdb-landmark-dist.git dist

## npm install
rm package.json || export NO_FILE=1
ln -s build/package.json package.json
npm install

## get commit ##
export LANDMARK_COMMIT=`git show --format="%h" HEAD | head -n1 | awk '{ print $1 }'`
echo $LANDMARK_COMMIT
export LANDMARK_COMMIT_MESSAGE=`git show --format="%B" HEAD | head -n1 | awk '{ print }'`
echo $LANDMARK_COMMIT_MESSAGE

## clean dist subdirectories ##
cd dist/
ls -1 -d */ | xargs rm -r -f

## package landmark ##
cd ../build/
ln -s ../node_modules node_modules
npm run grunt package

## get current version ##
export LMK_VERSION=`git describe --abbrev=0`
echo $LMK_VERSION

## commit and push changes to dist repo ##
cd ../dist/
git status
git add --all

## set DIST_HAS_UPDATE=1 by default, meaning there are differences
export DIST_HAS_UPDATE=1

## if commit success DIST_HAS_UPDATE stays as 1 otherwise set DIST_HAS_UPDATE to 0
git commit -m "Update from Landmark $LANDMARK_COMMIT" -m "$LANDMARK_COMMIT_MESSAGE" || DIST_HAS_UPDATE=0
echo $DIST_HAS_UPDATE

## If updates exist, push change ...
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git push; fi

## Set remote branch
export REMOTE_BRANCH="origin/$CI_BRANCH"
echo $REMOTE_BRANCH

if [[ "$DIST_HAS_UPDATE" = "1" ]]; then
    ## Checkout master on xdb-landmark
    cd ..
    git fetch origin
    git branch -a
    git reset --hard $REMOTE_BRANCH

    ## then bump version on xdb-landmark-dist
    cd dist/
    npm i
    grunt bump
    export NEW_VERSION=`git describe --abbrev=0`

    ## then tag version on xdb-landmark
    echo $NEW_VERSION
    cd ../
    git tag $NEW_VERSION
    git push origin $NEW_VERSION
fi

## BUMP UP UCMS CSS VERSION

## if dist is updated ("$DIST_HAS_UPDATE" = "1") then do all the commands to bump up the ucms css repo
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then
    ## cleaning local ucms-css repo
    rm -rf ~/src/bitbucket.org/fairfax/ucms-css
    mkdir -p ~/src/bitbucket.org/fairfax/ucms-css

    ## cloning ucms-css repo
    cd ~/src/bitbucket.org/fairfax/ucms-css
    git clone git@bitbucket.org:fairfax/ucms-css.git .

    ## sites to be included for autobump
    declare -a arr=(
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
    git status
    git add --all
    git commit -m "Bump version from Landmark $LANDMARK_COMMIT" -m "$LANDMARK_COMMIT_MESSAGE"
    git push
fi
