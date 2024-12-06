apt-get update
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install gitlab-runner
apt-cache madison gitlab-runner
gitlab-runner -version