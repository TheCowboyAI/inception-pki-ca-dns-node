ssh://git@github.com:TheCowboyAI/inception-pki-realm-node.git

My origin was pointing to the wrong upstream because of the colon in the URL
Replace
@github.com: with
@github-cowboy/

git remote -v
git remote add origin ssh://git@github-cowboy/TheCowboyAI/inception-pki-realm-node.git
git remote set-url origin ssh://git@github-cowboy/TheCowboyAI/inception-pki-realm-node.git

git checkout <branch>
git stash list
git stash show
