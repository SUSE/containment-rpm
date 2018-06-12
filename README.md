This repository hosts the containment-rpm resources used to wrap the Docker
images built by KIWI on IBS into RPMs.

The work is based on the original containment-rpm tool created by SUSE Studio
and later made available inside of [this public repository](https://github.com/openSUSE/containment-rpm).

The original repository on GitHub provides already some documentation.
However this document is going to clarify some aspects of the whole process.

# Explaining the magic

Everything starts with the user creating a package (in the build service
terminology, we are not talking about `.rpm` files) that contains all the KIWI
sources required to build the appliance.

The build service will look at these files, figure out the operating system
of the target and provision a build VM of the same type. To make it clear, if
the user uploaded the sources of a SLE11 SP3 appliance then the build service
is going to provision a SLE11 SP3 virtual machine to run the build inside of
it.

The build service will install all the packages required to run KIWI. It will
also download all the packages required by the appliance inside of the build
system. Then it will start the KIWI process like a normal KIWI user would do.
However once KIWI successfully completes the creation of the appliance the build
service is going to trigger a post build hook.

The post build hook will look for a file named `kiwi_post_run` located inside
of the `/usr/lib/build` directory. If the file exists and is executable then
the build service will invoke it. The `kiwi_post_run` script is where we
trigger the build of a new rpm containing the output of the kiwi process.

Obviously we must make the `kiwi_post_run` file available on the build host. The
solution is simple: create a package containing our script plus other resources
and ask the build service to install this package inside of the build environment.
The package containing the post build hook is usually called `containment-rpm`.

The package contains basically two files:

  * The post build script (`kiwi_post_run`): it can be written in any language
    you want. If you use an interpreted language make sure to add it as a
    runtime dependency inside of the `containment-rpm` spec file.
  * The `.spec` file used to build the package containing the output of the kiwi
    build. This file is usually a template which is later customized by the
    `kiwi_post_run` script to hold the right values (e.g.: the build version).

This is basically all you need to know.

# How to prepare a project on the build service

It is recommended to have a build service project dedicated to building
the Docker images.

The project must have at least two repositories:

  * A KIWI repository, this is called 'images' by default by the build service.
  * A repository to build the containment-rpm-docker binary.

If you plan to build docker images for different versions of SLE then you have
to make sure you build the containment rpm also for these targets. You have to
do that because the build host will have the same OS of the target (see previous
section).

You need to edit the project config: `osc meta -e prjconf` and make sure you
have something like that:

```
%if "%_repository" == "images"
Type: kiwi
Repotype: rpm-md
Patterntype: none
Required: containment-rpm-docker
%endif
```

We changed `Repotype` because the repository is going to have also the rpm
containing the output produced by KIWI.

We added the `Required` statement to have the `containment-rpm-docker` and all
its dependencies installed inside of the build environment used by the build
service.

Next we need to edit the project metadata: `osc meta -e prj`. We have to add
the repository containing the `containment-rpm` to the list of repositories
available by the `images` target at build time.

```xml
  <repository name="images">
    <path project="Devel:Docker:Images" repository="SLE_12"/>
    <arch>x86_64</arch>
  </repository>
```

So in the end the project will have just two packages (again, build service
terminology not `.rpm` files):

  * `my-appliance`: this is where the KIWI sources are placed.
  * `containment-rpm`: this is the package containing the script called by the
    post build hook.

As you can notice there is no definition of the package containing the output
of the KIWI process. Whenever the `my-appliance` package is built the rpm
containing its output is going to be created. Note well: this rpm is going
to be published by the build service inside of the `images` repository.


## Using a special kiwi version

If you want to use a special version of KIWI to build your images you can either
have a `kiwi` package inside of your project or you can reference the `kiwi`
package from another repository.

### Custom kiwi package inside of the project

This requires you to copy/link the `kiwi` package from somewhere to your project.

Then you have to add your repository to the list of repositories available for the
`images` one. This is what we have already done previously to make it possible to
install the `containment-rpm` inside of the build environment:

```xml
  <repository name="images">
    <path project="Devel:Docker:Images" repository="SLE_12"/>
    <arch>x86_64</arch>
  </repository>
```

### kiwi package from an external project

This is the only sane way to have a recent version of KIWI on an old system like
SLE11 SP3.

First of all we have to make edit the project metadata: `osc meta -e prj`.

Add the path to the project containing the `kiwi` package to the `images` repository:

```xml
  <repository name="images">
    <path project="openSUSE.org:Virtualization:Appliances" repository="SLE_12"/>
    <path project="Devel:Docker:Images" repository="SLE_12"/>
    <arch>x86_64</arch>
  </repository>
```

Then add the same repository to your KIWI source file (the `.kiwi` file).

