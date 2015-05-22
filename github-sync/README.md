# Github-sync

github-sync is a sipmle script to update all branch of your forked repos (like a
mirror for fork repos).

We use this script in order to sync stackforge/puppet-* modules in our
organisation.

## Jenkins

Here, just a simple jenkins-job-build script for update-github-forks script.

```yaml
    builders:
      - shell: |
          mkdir -p vendor
          export GEM_HOME="$(pwd)/vendor"
          gem install --no-ri --no-rdoc octokit
          GITHUB_TOKEN='<your github token>' ruby update-github-forks.rb
```
