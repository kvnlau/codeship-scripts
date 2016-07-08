#!/bin/bash
# Deploy to staging environment via cherry picking from CI branch.
#
# Add the following environment variables to your project configuration and make
# sure the public SSH key from your projects General settings page is allowed to
# pull from the remote repository as well.
# * REMOTE_REPOSITORY, e.g. "git@github.com:codeship/documentation.git"
# * STAGING_BRANCH, e.g. "preview"
#
# Include in your builds via
# \curl -sSL https://raw.githubusercontent.com/consolelog/deploy-preview/master/deployments/deploy-preview.sh | bash -s
REMOTE_REPOSITORY=${REMOTE_REPOSITORY:?'You need to configure the REMOTE_REPOSITORY environment variable!'}
STAGING_BRANCH=${STAGING_BRANCH:?'You need to configure the STAGING_BRANCH environment variable!'}

set -e

cd ~/src/bitbucket.org/fairfax/deploy-preview
git clone {REMOTE_REPOSITORY}
git checkout ${STAGING_BRANCH}
git checkout "${CI_BRANCH}"
# a list of commits that are not yet cherry picked onto staging branch
preview_diff=$(git rev-list --reverse --right-only --cherry-pick ${STAGING_BRANCH}...HEAD --author="${CI_COMMITTER_EMAIL}")
# a list of commits that are not yet merged into master
master_diff=$(git rev-list --reverse --right-only --no-merges master...HEAD --author="${CI_COMMITTER_EMAIL}")
for item1 in $preview_diff; do
    for item2 in $master_diff; do
        if [[ $item1 = $item2 ]]; then
            result=$result" "$item1
        fi
    done
done
echo $result

git config --global user.email "landmark@fairfaxmedia.com.au"
git config --global user.name "FFX UI Engineering Bot"
git config --global push.default simple
git checkout ${STAGING_BRANCH}
git pull --rebase
git cherry-pick -x $result
git push