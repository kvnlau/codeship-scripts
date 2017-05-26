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
## ... checkout master on xdb-landmark ... ##
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ..; git fetch origin; git branch -a; git reset --hard $REMOTE_BRANCH; fi
## ... then bump version on xdb-landmark-dist ##
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd dist/; npm i; grunt bump; export NEW_VERSION=`git describe --abbrev=0`; fi
## ...then tag version on xdb-landmark
echo $NEW_VERSION
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ../; git tag $NEW_VERSION; git push origin $NEW_VERSION; fi
## BUMP UP UCMS CSS VERSION
## if dist is updated ("$DIST_HAS_UPDATE" = "1") then do all the commands to bump up the ucms css repo
## cleaning local ucms-css repo
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then rm -rf ~/src/bitbucket.org/fairfax/ucms-css; fi
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then mkdir -p ~/src/bitbucket.org/fairfax/ucms-css; fi
## cloning ucms-css repo
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ~/src/bitbucket.org/fairfax/ucms-css; fi
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git clone git@bitbucket.org:fairfax/ucms-css.git .; fi
## go to gradle file
## do for masthead
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ./ucms-css-mastheads; fi
## ----
## replacing any tag in build gradle with the newest tag
## use this for linux
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then sed -i "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle; fi
## use this for mac, by default -i requires backup extension in BSD but not the case in GNU
## if [[ "$DIST_HAS_UPDATE" = "1" ]]; then sed -i bak -e "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle; fi
## ----
## removing the backup file whether the file exists or not (only necessary for mac)
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then rm -f ./build.gradle.bak; fi
## go to gradle file
## do for execstyle
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ../ucms-css-executive-style; fi
## ----
## replacing any tag in build gradle with the newest tag
## use this for linux
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then sed -i "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle; fi
## use this for mac, by default -i requires backup extension in BSD but not the case in GNU
## if [[ "$DIST_HAS_UPDATE" = "1" ]]; then sed -i bak -e "s|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/.*|downloadCssResourcesZipFile.src 'https://bitbucket.org/fairfax/xdb-landmark-dist/get/$NEW_VERSION.zip'|" ./build.gradle; fi
## ----
## removing the backup file whether the file exists or not (only necessary for mac)
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then rm -f ./build.gradle.bak; fi
## move back to root of repo
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then cd ..; fi
## commit the changes
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git status; fi
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git add --all; fi
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git commit -m "Bump version from Landmark $LANDMARK_COMMIT" -m "$LANDMARK_COMMIT_MESSAGE"; fi
if [[ "$DIST_HAS_UPDATE" = "1" ]]; then git push; fi