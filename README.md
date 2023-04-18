# hise-builder

Docker container that builds HISE Standalone with Faust, IPP support for Linux.

Go to [packages](https://github.com/spezifisch/hise-builder/pkgs/container/hise-builder) for the Docker container.

Tags:

* main-hise-3.0.3 is based on HISE 3.0.3
* main-hise-develop is based on the most recent develop branch of HISE at build time
* main-hise-3.0.3-ci-dsp is based on HISE 3.0.3 with some experimental stuff inside

## Usage

See my [Reach fork](https://github.com/spezifisch/Reach) for an example use of this builder.

* Its Dockerfile is a good starting point. It inherits this container (hise-builder) and compiles the Linux VST3 version of that plugin.
* Build is triggered by [a GitHub Action](https://github.com/spezifisch/Reach/blob/main/.github/workflows/build.yml) on main/develop branch and tag pushes.
* Branch pushes are uploaded as artifacts which are downloadable in the GitHub's Actions tab as eg. `Reach-nightly-20230418-17b1d68-Linux-VST3.tar.gz`
* Tags matching `v*` are uploaded as releases as eg. `Reach-v1.5.0-Linux-VST3.tar.gz` for tag `v1.5.0`

You can also use it independent from GitHub and get the resulting tar ball using (inside Reach repository):

```console
$ docker build . -t reach-builder
$ docker run --rm -v .:/foo reach-builder bash -c "cp -R /output/* /foo"
$ ls Reach-v1.5.0-Linux-VST3.tar.gz 
Reach-v1.5.0-Linux-VST3.tar.gz
```

