python setup.py sdist
git status --porcelain
git diff > all_diff
cat all_diff
