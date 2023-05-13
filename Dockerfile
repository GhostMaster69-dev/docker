FROM scratch
ADD ubuntu-lunar-oci-amd64-root.tar.gz /
CMD ["bash"]
RUN apt update && \
    yes | unminimize && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y alien apt-utils at autoconf automake autopoint bash-completion bc binutils-dev bison build-essential bzip2 bzr ca-certificates ccache cmake cpio curl default-jdk dialog dirmngr dpkg-dev emacs-nox file fish flex gawk g++ gcc gdb gh git git-lfs gnupg gperf help2man htop imagemagick iputils-ping jq less libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libdebuginfod-dev libedit-dev libelf-dev libevent-dev libffi-dev libfl-dev libgdbm-dev libglib2.0-dev libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev libmaxminddb-dev libmysqlclient-dev libncurses5-dev libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsdl1.2-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxmlsec1-dev libxslt-dev libyaml-dev liblzma-dev locales lsb-release lsof lz4 lzma lzop make man-db maven mercurial multitail nano ncftp neovim ninja-build netbase openssh-client openssh-server parallel patch patchelf pngcrush procps rclone ripgrep rlwrap rsync schedtool screen screenfetch software-properties-common squashfs-tools sshpass ssl-cert stow subversion sudo tar texinfo time tk-dev tmate tmux tzdata u-boot-tools vim w3m wget whiptail xsltproc xvfb xz-utils zip zlib1g-dev zsh zstd && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    locale-gen C.UTF-8
ENV TZ=Asia/Kolkata
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=C.UTF-8
ENV PATH=/usr/games:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN useradd -l -u 55555 -G sudo -md /codespace -s /bin/bash -p codespace codespace && \
    sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers && \
    chown -hR codespace:codespace /codespace && \
    chown -hR 55555:55555 /codespace
ENV HOME=/codespace
ENV PATH=/codespace/.local/bin:$PATH
WORKDIR /codespace
RUN { echo && echo "PS1='\[\033[01;32m\]\u\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\]\$(__git_ps1 \" (%s)\") $ '" ; } >> .bashrc
COPY default.gitconfig /etc/gitconfig
COPY default.gitconfig /codespace/.gitconfig
RUN git lfs install --system --skip-repo
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg     && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/$(lsb_release -cs)     llvm-toolchain-$(lsb_release -cs)-16 main" | sudo tee /etc/apt/sources.list.d/llvm.list > /dev/null && \
    apt update && \
    apt install -y clang-16 clangd-16 clang-format-16 clang-tidy-16 clang-tools-16 lld-16 lldb-16 && \
    ln -sf /usr/lib/llvm-16/bin/* /usr/bin
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt update && \
    apt install -y docker-ce docker-ce-cli containerd.io && \
    curl -o /usr/bin/slirp4netns -fsSL https://github.com/rootless-containers/slirp4netns/releases/download/v1.1.12/slirp4netns-$(uname -m) && \
    chmod +x /usr/bin/slirp4netns && \
    curl -o /usr/local/bin/docker-compose -fsSL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-$(uname -m) && \
    chmod +x /usr/local/bin/docker-compose && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    ln -s /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose && \
    curl -o /tmp/dive.deb -fsSL https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_linux_amd64.deb && \
    apt install /tmp/dive.deb && \
    rm -rf /tmp/dive.deb /var/lib/apt/lists/*
ENV NODE_VERSION=20.1.0
ENV PNPM_HOME=/codespace/.pnpm
ENV PATH=/codespace/.nvm/versions/node/${NODE_VERSION}/bin:/codespace/.yarn/bin:/codespace/.pnpm:$PATH
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash \
    && . .nvm/nvm.sh  \
    && nvm install v${NODE_VERSION} \
    && nvm alias default v${NODE_VERSION} \
    && chown -R 55555:55555 "/codespace/.npm" \
    && chown -R 55555:55555 "/codespace/.nvm" \
    && npm install typescript yarn pnpm node-gyp glob
USER codespace
RUN sudo echo "Running 'sudo' for Codespace shell: success" && \
    mkdir -p /codespace/.bashrc.d && \
    (echo; echo "for i in \$(ls -A \$HOME/.bashrc.d/); do source \$HOME/.bashrc.d/\$i; done"; echo) >> /codespace/.bashrc && \
    mkdir -p /codespace/.local/share/bash-completion/completions
ENV PATH=/codespace/.pyenv/bin:/codespace/.pyenv/shims:$PATH
ENV PIPENV_VENV_IN_PROJECT=true
ENV PYENV_ROOT=/codespace/.pyenv
ENV PYTHON_VERSION=3.11.3
RUN curl -fsSL https://pyenv.run | bash && \
    pyenv update && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    python3 -m pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --upgrade setuptools wheel virtualenv pipenv pylint rope flake8 mypy autopep8 pep8 pylama mccabe pyaf pypf pydocstyle bandit notebook twine && \
    curl -sSL https://install.python-poetry.org | python
RUN sudo rm -rf /tmp/*
RUN curl http://commondatastorage.googleapis.com/git-repo-downloads/repo -o /codespace/.local/bin/repo && \
    chmod a+x /codespace/.local/bin/repo
RUN git clone https://github.com/newren/git-filter-repo ~/git-filter-repo && \
    cd git-filter-repo && \
    python git-filter-repo --analyze && \
    pip install git-filter-repo && \
    rm -rf ~/git-filter-repo
RUN echo '. .nvm/nvm.sh' >> .bashrc
RUN echo 'sudo chown -R 55555:55555 "/codespace/.npm"' >> .bashrc
RUN echo 'sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y' >> .bashrc
