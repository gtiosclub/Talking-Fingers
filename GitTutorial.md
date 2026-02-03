# Git Tutorial for Xcode

## Video: [text](https://youtu.be/pqnPP57Hs9s)

## Workflow:
Below is a typical workflow from start to finish that you should follow when you deal with Xcode and Github:

1.  On Xcode create a new branch from **main** (via your _issue/task_ from projects). For now, let's call it `isabel`

2.  Then you start working and making changes to it, and at this point your branch is ahead of main because of your changes, **but** it could also be behind main in some files because **others** may have created a PR and their work got approved to merge into the main but in your own branch you don't have those changes.

3.  Now with that in mind, let's say you have finished your work, what you do now is:
    -   `git stash` all your work
    - `git commit` all your work with a commit message describing in essence your work
    - `git push` all your work to the GitHub -- note at this step Xcode will automatically create this branch `isabel` on GitHub and push all you work to that branch. Up to this point, you have successfully saved all your work in the GitHub repo in this branch `isabel`.

4.  Now before you create a PR for your work, you need to perform `git pull` from **main** . This ensures that the changes that **others** made that have been merged into main are now pulled into **your** branch. This step is _essential_ because it helps you spot the merge conflicts. If there's any merge conflict, Xcode will tell you. From there you need to use Xcode merge conflict resolver to decide how to resolve those conflicts. At this point if you get confused as to how to resolve those conflicts, feel free to reach out to us for clarity.

5.  Once you've made sure no merge conflicts are there, perform another `git push` to `isabel`. Now your branch is very much ready for creating a PR.

6.  Create the PR and request a review from your subteam leader.