gitbook build

cd _book

git init

git checkout -b gh-pages

git remote add origin git@github.com:gavinliu/A-tour-of-modern-Android-app-development.git

git add -A

git commit -m "UPDATE SITE"

git push -u origin gh-pages -f